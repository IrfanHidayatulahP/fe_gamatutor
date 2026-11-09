import 'package:flutter/material.dart';

import '../utils/reference_ui/task.dart';
import '../widget/theme.dart';

/// Hasil lembar "Pindahkan tugas": kolom tujuan, atau buka rincian.
class MoveSheetResult {
  final String? to;
  final bool openDetail;
  const MoveSheetResult({this.to, this.openDetail = false});
}

Future<MoveSheetResult?> showMoveSheet(BuildContext context, {required Task task, required Map<String, int> counts}) {
  return showAppSheet<MoveSheetResult>(context, (_) => _MoveSheet(task: task, counts: counts));
}

class _MoveSheet extends StatefulWidget {
  final Task task;
  final Map<String, int> counts;
  const _MoveSheet({required this.task, required this.counts});

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  late String? _to = kNextStatus[widget.task.status];

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Text('Pindahkan tugas', style: inter(size: 17, weight: FontWeight.w800)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(t.title, style: inter(size: 13, weight: FontWeight.w600, height: 1.3)),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pop(context, const MoveSheetResult(openDetail: true)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              child: Row(children: [
                const Icon(Icons.description_outlined, size: 16, color: kPrimaryHover),
                const SizedBox(width: 8),
                Expanded(child: Text('Lihat rincian tugas', style: inter(size: 13, weight: FontWeight.w700, color: kPrimaryHover))),
                const Icon(Icons.chevron_right, size: 16, color: kPrimaryHover),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      for (final c in kColumns) _option(c),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.schedule, size: 14, color: kPrimary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(style: inter(size: 12, color: const Color(0xFF374151), height: 1.4), children: [
                const TextSpan(text: 'Waktu pengerjaan mulai dihitung saat kartu masuk '),
                TextSpan(text: 'Monitoring', style: inter(size: 12, weight: FontWeight.w700, color: const Color(0xFF374151))),
                const TextSpan(text: '.'),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        _to != null ? 'Pindahkan ke ${columnOf(_to!).name}' : 'Pilih kolom tujuan',
        onPressed: _to == null ? null : () => Navigator.pop(context, MoveSheetResult(to: _to)),
      ),
    ]);
  }

  Widget _option(BoardColumn c) {
    final cur = widget.task.status == c.key, on = _to == c.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: on ? const Color(0xFFEFF6FF) : (cur ? const Color(0xFFF9FAFB) : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? kPrimaryHover : const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: cur ? null : () => setState(() => _to = c.key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(c.name, style: inter(size: 13.5, weight: FontWeight.w700))),
                    if (cur)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(6)),
                        child: Text('SAAT INI', style: inter(size: 10, weight: FontWeight.w700, color: const Color(0xFF4B5563), spacing: .3)),
                      ),
                  ]),
                  Text(c.description, style: inter(size: 11, color: kGray500)),
                ]),
              ),
              const SizedBox(width: 8),
              Text('${widget.counts[c.key] ?? 0} tugas', style: inter(size: 11, weight: FontWeight.w600, color: const Color(0xFF9CA3AF))),
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? kPrimaryHover : null,
                  border: Border.all(color: on ? kPrimaryHover : const Color(0xFFCBD5E1), width: 2),
                ),
                child: on ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
