import 'package:flutter/material.dart';

import '../utils/reference_ui/task.dart';
import '../widget/theme.dart';

const List<double> _qx = [24, 78, 132, 186, 240, 294];
const List<double> _qtop = [78, 70, 56, 44, 32, 22];
const List<IconData> _qicons = [
  Icons.school_outlined,
  Icons.edit_outlined,
  Icons.menu_book_outlined,
  Icons.gps_fixed,
  Icons.event_outlined,
  Icons.bolt,
];
const List<String> kQuestLabels = [
  'Mata kuliah',
  'Nama tugas',
  'Strategi belajar',
  'Tujuan belajar',
  'Deadline & prioritas',
  'Tingkat kesulitan',
];

/// Kartu misi (peta petualangan) di atas form Tugas Baru: pratinjau hidup, 6 pos wajib.
class QuestCard extends StatelessWidget {
  final String title, course;
  final List<bool> done; // 6 pos: course, title, strategy, goal, due, diff
  final String? dueText, dueCls, difficulty, prioLabel;
  final int rewardId;
  final bool compact;
  final ValueChanged<int> onNode;

  const QuestCard({
    super.key,
    required this.title,
    required this.course,
    required this.done,
    required this.dueText,
    required this.dueCls,
    required this.difficulty,
    required this.prioLabel,
    required this.rewardId,
    required this.compact,
    required this.onNode,
  });

  int get _n => done.where((d) => d).length;
  bool get _ok => _n == 6;

  @override
  Widget build(BuildContext context) {
    final n = _n, ok = _ok;
    // var last = 0;
    // for (var i = 0; i < 6; i++) {
    //   if (done[i]) last = i;
    // }
    int last = 0;
    for (var i = 0; i < 6; i++) {
      if (done[i]) last = i;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8E2F8), Color(0xFFEAEEFA), Color(0xFFF3F0F8)],
          stops: [0, .6, 1],
        ),
        boxShadow: const [BoxShadow(color: Color(0x1A1E295A), blurRadius: 18, offset: Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        if (!compact)
          Positioned(left: 0, right: 0, bottom: 0, height: 150, child: CustomPaint(painter: _QMountPainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (ok)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(99)),
                      child: Text('🏁 MISI SIAP BERANGKAT',
                          style: inter(size: 10.5, weight: FontWeight.w800, color: const Color(0xFF4F5FB5), spacing: .6)),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: ok ? 8 : (compact ? 4 : 8)),
                    child: Text(
                      title.isNotEmpty ? titleCase(title) : 'Misi tanpa nama',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: lora(
                        size: 21,
                        weight: title.isNotEmpty ? FontWeight.w700 : FontWeight.w600,
                        color: title.isNotEmpty ? const Color(0xFF1F2D5C) : const Color(0xFF8E98B5),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    course.isNotEmpty ? '🗺️ Wilayah: $course' : 'Pilih wilayah (mata kuliah)',
                    style: inter(size: 12, weight: FontWeight.w600, color: course.isNotEmpty ? const Color(0xFF5B6478) : const Color(0xFF8E98B5)),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              _gem(),
            ]),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: compact
                  ? const SizedBox(width: double.infinity)
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const SizedBox(height: 12),
                      SizedBox(height: 112, child: _map(last)),
                      const SizedBox(height: 8),
                      _chips(n),
                    ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _gem() => Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 13, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [BoxShadow(color: Color(0x24465AA0), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: Color(0xFFE6EFFF), shape: BoxShape.circle),
            child: const Icon(Icons.diamond_outlined, size: 15, color: kPrimary),
          ),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('+10', style: inter(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF1F2D5C), height: 1.1)),
            Text('PERMATA', style: inter(size: 8, weight: FontWeight.w800, color: const Color(0xFF5F76A8), height: 1.1, spacing: .64)),
          ]),
        ]),
      );

  Widget _map(int last) {
    final ok = _ok;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      double nx(int i) => _qx[i] / 336 * w;
      return Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: _QPathPainter(w))),
        for (var i = 0; i < 6; i++)
          Positioned(
            left: nx(i) - 16,
            top: _qtop[i],
            child: GestureDetector(
              onTap: () => onNode(i),
              child: _Node(on: done[i], cur: !ok && i == last && _n > 0, icon: _qicons[i], label: kQuestLabels[i]),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 550),
          curve: const Cubic(.4, .1, .2, 1),
          left: nx(last) - 22,
          top: _qtop[last] - 68,
          width: 44,
          height: 66,
          child: IgnorePointer(
            child: chrImage(ok ? 'win' : 'mid', height: 66, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          right: 2,
          top: 64,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EEFC),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x385064AA), blurRadius: 10, offset: Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: ok
                  ? Image.asset(rewardAsset(rewardId), fit: BoxFit.cover, width: 42, height: 42)
                  : Text('?', style: inter(size: 20, weight: FontWeight.w800, color: const Color(0xFF9FB0DC))),
            ),
            const SizedBox(height: 2),
            Text('HADIAH MISI', style: inter(size: 8, weight: FontWeight.w800, color: const Color(0xFF5F76A8), spacing: .64)),
          ]),
        ),
        if (ok) ...[
          const Positioned(right: -4, top: 56, child: Text('✨', style: TextStyle(fontSize: 14))),
          const Positioned(right: 40, top: 92, child: Text('✨', style: TextStyle(fontSize: 11))),
        ],
      ]);
    });
  }

  Widget _chips(int n) {
    Widget chip(bool on, IconData ic, String txt, String ph) {
      if (!on) {
        return CustomPaint(
          painter: _PillDash(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(ph, style: inter(size: 11, weight: FontWeight.w600, color: const Color(0xFF8E98B5))),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 12, color: const Color(0xFF4B5563)),
          const SizedBox(width: 5),
          Text(txt, style: inter(size: 11, weight: FontWeight.w700, color: const Color(0xFF4B5563))),
        ]),
      );
    }

    IconData dueIcon() => dueCls == 'late'
        ? Icons.star_outline
        : (dueCls == 'today' || dueCls == 'soon' || dueCls == 'far')
            ? Icons.calendar_today_outlined
            : Icons.schedule;
    return Row(children: [
      Expanded(
        child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          chip(dueText != null, dueIcon(), dueText ?? '', 'Tenggat'),
          chip(difficulty != null, kDifficultyIcons[difficulty] ?? Icons.explore_outlined,
              difficulty == null ? '' : difficultyLabelOf(difficulty!), 'Kesulitan'),
          chip(prioLabel != null, Icons.flag_outlined, prioLabel == null ? '' : 'Prio $prioLabel', 'Prioritas'),
        ]),
      ),
      Text('$n/6 pos', style: inter(size: 12, weight: FontWeight.w800, color: const Color(0xFF3B5BB5))),
    ]);
  }
}

String difficultyLabelOf(String k) => const {'mudah': 'Mudah', 'sedang': 'Sedang', 'sulit': 'Sulit'}[k] ?? k;

class _Node extends StatelessWidget {
  final bool on, cur;
  final IconData icon;
  final String label;
  const _Node({required this.on, required this.cur, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? const Color(0xFF4F86E8) : Colors.white,
          border: on ? null : Border.all(color: const Color(0xFFC9D2E6), width: 2),
          boxShadow: on
              ? [
                  if (cur) BoxShadow(color: const Color(0xFF4F86E8).withAlpha(56), spreadRadius: 6),
                  BoxShadow(color: const Color(0xFF3B82F6).withAlpha(140), blurRadius: 10, spreadRadius: -2, offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Icon(icon, size: 15, color: on ? Colors.white : const Color(0xFFB3BCD0)),
      ),
    );
  }
}

class _QMountPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path poly(List<List<double>> pts) {
      final p = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = pts[i][0] * size.width / 364, y = pts[i][1] * size.height / 150;
        i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      return p..close();
    }

    canvas.drawPath(
      poly([[0, 150], [0, 118], [52, 84], [98, 112], [150, 70], [214, 116], [268, 82], [364, 122], [364, 150]]),
      Paint()..color = const Color(0xFFC9D3F0).withOpacity(.7),
    );
    canvas.drawPath(
      poly([[0, 150], [0, 132], [70, 104], [130, 130], [200, 98], [270, 130], [330, 106], [364, 124], [364, 150]]),
      Paint()..color = const Color(0xFFB3BFE6).withOpacity(.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _QPathPainter extends CustomPainter {
  final double w;
  _QPathPainter(this.w);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (var i = 0; i < 6; i++) Offset(_qx[i] / 336 * w, _qtop[i] + 16)];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      final mx = pts[i - 1].dx + (pts[i].dx - pts[i - 1].dx) / 2;
      path.cubicTo(mx, pts[i - 1].dy, mx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(.9),
    );
    final dot = Paint()..color = const Color(0xFF8FB0F2);
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QPathPainter old) => old.w != w;
}

class _PillDash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white.withOpacity(.35);
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.drawRRect(r, bg);
    final stroke = Paint()
      ..color = const Color(0xFFBAC4DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(r.deflate(.75));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 6) {
        canvas.drawPath(m.extractPath(d, (d + 3.5).clamp(0.0, m.length).toDouble()), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
