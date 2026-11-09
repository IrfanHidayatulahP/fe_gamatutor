import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../utils/reference_ui/task.dart';
import '../widget/theme.dart';

Future<void> _modal(BuildContext context, Color barrier, bool blur, WidgetBuilder builder) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'tutup',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, a, b) {
      Widget bg = Container(color: barrier);
      if (blur) bg = BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: bg);
      return Stack(children: [
        Positioned.fill(child: bg),
        Center(child: builder(ctx)),
      ]);
    },
    transitionBuilder: (ctx, a, b, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween<double>(begin: .94, end: 1).animate(c), child: child),
      );
    },
  );
}

/// Pop-up hadiah setelah tugas disimpan ("Misi Berhasil Dicatat!").
Future<void> showRewardDialog(BuildContext context, int rewardId) {
  final name = rewardName(rewardId);
  return _modal(context, const Color(0x8C6270AC), true, (ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              margin: const EdgeInsets.only(top: 62),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Color(0x47283270), blurRadius: 60, offset: Offset(0, 24))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 62),
                Text('Misi Berhasil Dicatat!', textAlign: TextAlign.center, style: lora(size: 25, color: const Color(0xFF1F2D5C), height: 1.2)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                  child: Row(children: [
                    const Expanded(child: Divider(color: Color(0xFFD5DEF3), height: 1)),
                    const SizedBox(width: 10),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFF7FA0EE)),
                    const SizedBox(width: 10),
                    const Expanded(child: Divider(color: Color(0xFFD5DEF3), height: 1)),
                  ]),
                ),
                Text.rich(
                  TextSpan(style: inter(size: 14, color: const Color(0xFF5B6584), height: 1.6), children: [
                    const TextSpan(text: 'Selamat, Penjelajah! Kamu mendapat '),
                    TextSpan(text: '10 Permata Ilmu', style: inter(size: 14, weight: FontWeight.w700, color: const Color(0xFF1F2D5C), height: 1.6)),
                    const TextSpan(text: ' dan sebuah '),
                    TextSpan(text: name, style: inter(size: 14, weight: FontWeight.w700, color: const Color(0xFF1F2D5C), height: 1.6)),
                    const TextSpan(text: ' yang akan menemanimu menyelesaikan misi.'),
                  ]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFE6ECFA)),
                      boxShadow: const [BoxShadow(color: Color(0x29465AA0), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(color: Color(0xFFE6EFFF), shape: BoxShape.circle),
                        child: const Icon(Icons.diamond_outlined, size: 15, color: kPrimary),
                      ),
                      const SizedBox(width: 7),
                      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('+10', style: inter(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF1F2D5C), height: 1.1)),
                        Text('PERMATA ILMU', style: inter(size: 8, weight: FontWeight.w800, color: const Color(0xFF5F76A8), height: 1.1, spacing: .64)),
                      ]),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FD),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFE6ECFA)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.verified_outlined, size: 15, color: Color(0xFF5F76A8)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(name,
                              maxLines: 2, textAlign: TextAlign.center,
                              style: inter(size: 11, weight: FontWeight.w700, color: const Color(0xFF3B4F86), height: 1.15)),
                        ),
                      ]),
                    ),
                  ),
                ])),
                const SizedBox(height: 14),
                Material(
                  color: const Color(0xFF4177F5),
                  borderRadius: BorderRadius.circular(16),
                  elevation: 4,
                  shadowColor: const Color(0x594177F5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(ctx),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Lanjut Petualangan', style: inter(size: 15, weight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEFC),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x4D4658AA), blurRadius: 24, offset: Offset(0, 10))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
  'assets/rw/${rewardId.toString().padLeft(2, '0')}.png',
  errorBuilder: (context, error, stackTrace) {
    // Fallback jika asset tidak ada
    return Container(
      width: 200,
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFFEDE9FE),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('💎', style: TextStyle(fontSize: 80)),
      ),
    );
  },
),
              ),
            ),
            const Positioned(left: 40, top: 4, child: Text('✦', style: TextStyle(color: Color(0xFFF4C95D), fontSize: 18))),
            const Positioned(right: 36, top: -6, child: Text('✦', style: TextStyle(color: Color(0xFFF4C95D), fontSize: 24))),
            const Positioned(right: 70, top: 44, child: Text('✦', style: TextStyle(color: Color(0xFF9DB8F5), fontSize: 14))),
            const Positioned(left: 74, top: 48, child: Text('✦', style: TextStyle(color: Color(0xFF9DB8F5), fontSize: 13))),
          ]),
        ),
      ),
    );
  });
}

bool _reflectorShown = false;

/// Badge "Reflector": hadiah pertama kali menyelesaikan refleksi (bukan untuk skor tinggi).
/// Hanya sekali per sesi aplikasi.
Future<void> showReflectorBadge(BuildContext context) async {
  if (_reflectorShown) return;
  _reflectorShown = true;
  await _modal(context, const Color(0x8C111827), false, (ctx) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(size: const Size(104, 104), painter: _BadgePainter()),
                    const Icon(Icons.menu_book_outlined, size: 38, color: Colors.white),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text('BADGE BARU TERBUKA',
                  textAlign: TextAlign.center, style: inter(size: 11, weight: FontWeight.w700, color: const Color(0xFF6366F1), spacing: 1.7)),
              const SizedBox(height: 4),
              Text('Reflector', textAlign: TextAlign.center, style: inter(size: 22, weight: FontWeight.w900, spacing: -.5)),
              const SizedBox(height: 8),
              Text(
                'Evaluasi diri pasca pembelajaran. Kamu mendapatkannya karena sudah meluangkan waktu merefleksikan pemahamanmu, apa pun hasilnya.',
                textAlign: TextAlign.center,
                style: inter(size: 13, color: kGray500, height: 1.625),
              ),
              const SizedBox(height: 24),
              PrimaryButton('Lanjut', onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
        ),
      ),
    );
  });
}

class _BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final c = size.center(Offset.zero);
    final rect = Offset.zero & size;
    canvas.drawCircle(
      c,
      45 * k,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4338CA), Color(0xFF6366F1)]).createShader(rect),
    );
    canvas.drawCircle(
      c,
      37 * k,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)]).createShader(rect),
    );
    final dash = Paint()
      ..color = Colors.white.withOpacity(.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * k;
    final ring = Path()..addOval(Rect.fromCircle(center: c, radius: 33 * k));
    for (final m in ring.computeMetrics()) {
      for (double d = 0; d < m.length; d += 7 * k) {
        canvas.drawPath(m.extractPath(d, (d + 3 * k).clamp(0.0, m.length).toDouble()), dash);
      }
    }
    canvas.drawArc(Rect.fromCircle(center: c, radius: 37 * k), 3.14159, 3.14159, true, Paint()..color = Colors.white.withOpacity(.15));
    canvas.drawCircle(c, 41 * k, Paint()..color = const Color(0xFF4338CA).withOpacity(.5)..style = PaintingStyle.stroke..strokeWidth = k);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
