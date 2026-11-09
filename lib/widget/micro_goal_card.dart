import 'package:flutter/material.dart';

import '../utils/reference_ui/micro_goal_session.dart';
import '../widget/theme.dart';

/// Kartu ajakan "Cek pemahamanmu dulu?" di bagian Tingkat Kesulitan pada form tugas baru.
/// Tiga keadaan: belum mulai, belum selesai (bisa dilanjutkan), dan selesai (ringkasan + Ulangi).
class MicroGoalCard extends StatelessWidget {
  final MicroGoalSession? session;
  final VoidCallback onStart;
  final VoidCallback onResume;
  final VoidCallback onRedo;

  const MicroGoalCard({
    super.key,
    required this.session,
    required this.onStart,
    required this.onResume,
    required this.onRedo,
  });

  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _ind500 = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final s = session;
    if (s != null && s.isCompleted && s.insight != null) return _done(s);
    if (s != null) {
      return _banner(
        title: 'Cek Pemahaman belum selesai',
        body: 'Kamu sudah sampai langkah ${s.resumeStep} dari 4. Lanjutkan dari tempat terakhir.',
        button: 'Lanjutkan Cek Pemahaman',
        onTap: onResume,
      );
    }
    return _banner(
      title: 'Cek pemahamanmu dulu?',
      body: 'Untuk membantu menentukan tingkat kesulitan dalam mengerjakan tugas ini, coba cek pemahaman singkat dulu.',
      button: 'Mulai Cek Pemahaman',
      onTap: onStart,
      footnote: '± 1 menit',
    );
  }

  Widget _done(MicroGoalSession s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
        ),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _ind500, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cek pemahaman selesai', style: inter(size: 14.5, weight: FontWeight.w700, color: const Color(0xFF312E81))),
            const SizedBox(height: 2),
            Text.rich(TextSpan(style: inter(size: 12, color: _ind500), children: [
              TextSpan(text: 'Keyakinan ${s.initialConfidence}% '),
              const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.arrow_forward, size: 11, color: _ind500)),
              TextSpan(text: ' ${s.revisedConfidence ?? s.initialConfidence}%'),
            ])),
            Text('Saran AI: ${difficultyLabel(s.insight!.recommendedDifficulty)}', style: inter(size: 12, color: _ind500)),
          ]),
        ),
        TextButton(
          onPressed: onRedo,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Ulangi', style: inter(size: 12.5, weight: FontWeight.w700, color: const Color(0xFF4338CA))),
        ),
      ]),
    );
  }

  Widget _banner({required String title, required String body, required String button, required VoidCallback onTap, String? footnote}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC7D2FE)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          ),
        ),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(
            right: -44,
            top: -50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _ind500.withAlpha(26)),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: _ind500, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: inter(size: 16, weight: FontWeight.w700, color: const Color(0xFF1E1B4B)))),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Text(body, style: inter(size: 13, color: const Color(0xFF4B5563), height: 1.55)),
            ),
            Material(
              color: _indigo,
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              shadowColor: _indigo.withAlpha(110),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: SizedBox(
                  height: 48,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(button, style: inter(size: 14, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ]),
                ),
              ),
            ),
            if (footnote != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(footnote, textAlign: TextAlign.center, style: inter(size: 12, weight: FontWeight.w500, color: kGray500)),
              ),
          ]),
        ]),
      ),
    );
  }
}
