import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Latar pemandangan Cek Pemahaman (gunung, matahari, bendera, pohon), skala "meet" dari kanvas 390x844.
class FlowScene extends StatelessWidget {
  const FlowScene({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.expand(child: CustomPaint(painter: _ScenePainter()));
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 390, size.height / 844);
    canvas.save();
    canvas.translate((size.width - 390 * s) / 2, (size.height - 844 * s) / 2);
    canvas.scale(s);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 390, 844));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 390, 844),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD5DFF5), Color(0xFFE6EBF8), Color(0xFFF0EDF6)],
          stops: [0, .55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 390, 844)),
    );

    canvas.save();
    canvas.translate(0, 120);
    canvas.drawCircle(const Offset(150, 590), 40, Paint()..color = const Color(0xFFF0D488).withOpacity(.28));
    canvas.drawCircle(const Offset(150, 590), 24, Paint()..color = const Color(0xFFF0D488));

    Path poly(List<List<double>> pts) {
      final p = Path();
      for (var i = 0; i < pts.length; i++) {
        i == 0 ? p.moveTo(pts[i][0], pts[i][1]) : p.lineTo(pts[i][0], pts[i][1]);
      }
      return p..close();
    }

    canvas.drawPath(poly([[0, 640], [70, 560], [130, 620], [200, 520], [270, 610], [330, 560], [390, 620], [390, 844], [0, 844]]),
        Paint()..color = const Color(0xFFCBD2ED));
    canvas.drawPath(poly([[0, 700], [90, 610], [170, 690], [250, 600], [330, 680], [390, 640], [390, 844], [0, 844]]),
        Paint()..color = const Color(0xFFB1BBE2));
    canvas.drawPath(poly([[0, 760], [110, 690], [200, 750], [290, 660], [390, 740], [390, 844], [0, 844]]),
        Paint()..color = const Color(0xFF949FD1));

    // bendera
    canvas.drawLine(const Offset(236, 618), const Offset(236, 572),
        Paint()..color = const Color(0xFF6B7390)..strokeWidth = 3);
    canvas.drawPath(
      Path()
        ..moveTo(236, 572)
        ..lineTo(266, 581)
        ..lineTo(236, 591)
        ..close(),
      Paint()..color = const Color(0xFFD99AA2),
    );

    void tree(double x, double y, double sc) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(sc);
      final p = Path()
        ..moveTo(0, 0)
        ..relativeLineTo(10, -26)
        ..relativeLineTo(10, 26)
        ..close()
        ..moveTo(2, -14)
        ..relativeLineTo(8, -22)
        ..relativeLineTo(8, 22)
        ..close();
      canvas.drawPath(p, Paint()..color = const Color(0xFF7C86BC));
      canvas.drawRect(const Rect.fromLTWH(9, 0, 3, 6), Paint()..color = const Color(0xFF6B7390));
      canvas.restore();
    }

    tree(30, 770, 1.1);
    tree(62, 790, .9);
    tree(326, 780, 1.2);
    tree(352, 796, .9);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Konfeti jatuh (level keyakinan tertinggi).
class FlowConfetti extends StatefulWidget {
  final bool on;
  const FlowConfetti({super.key, required this.on});

  @override
  State<FlowConfetti> createState() => _FlowConfettiState();
}

class _FlowConfettiState extends State<FlowConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 600))..repeat();
  static const _cols = [Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF10B981), Color(0xFF3B82F6), Color(0xFF8B5CF6)];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.on ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: LayoutBuilder(builder: (context, box) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value * 600;
              return Stack(clipBehavior: Clip.hardEdge, children: [
                for (var i = 0; i < 24; i++) _piece(i, t, box),
              ]);
            },
          );
        }),
      ),
    );
  }

  Widget _piece(int i, double t, BoxConstraints box) {
    final dur = 2.6 + (i % 5) * .35;
    final delay = -(i * .37);
    final ph = (((t - delay) / dur) % 1.0);
    return Positioned(
      left: box.maxWidth * ((i * 37) % 100) / 100,
      top: -14 + ph * (box.maxHeight + 40),
      child: Transform.rotate(
        angle: ph * 3 * math.pi,
        child: Container(
          width: 7,
          height: 11,
          decoration: BoxDecoration(color: _cols[i % 5], borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}
