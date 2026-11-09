import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../reference_ui/task.dart';

/// Warna dan gaya yang sama dengan prototipe web (styles.css).
const Color kPrimary = Color(0xFF3B82F6);
const Color kPrimaryHover = Color(0xFF2563EB);
const Color kInk = Color(0xFF111827);
const Color kGray500 = Color(0xFF6B7280);

TextStyle inter({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = kInk,
  double? height,
  double? spacing,
  TextDecoration? decoration,
}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
      decoration: decoration,
    );

/// Judul besar bergaya serif (Lora) seperti halaman rincian.
TextStyle lora({double size = 20, FontWeight weight = FontWeight.w700, Color color = kInk, double? height}) =>
    GoogleFonts.lora(fontSize: size, fontWeight: weight, color: color, height: height);

String titleCase(String s) => s.replaceAllMapped(RegExp(r'(^|\s)(\S)'), (m) => '${m[1]}${m[2]!.toUpperCase()}');

/// Palet node peta tugas / kolom papan.
class NodeStyle {
  final Color c, bg;
  final IconData icon;
  const NodeStyle(this.c, this.bg, this.icon);
}

const Map<String, NodeStyle> kNodes = {
  'planning': NodeStyle(Color(0xFF3B82F6), Color(0xFFE6EEFC), Icons.edit_outlined),
  'in_progress': NodeStyle(Color(0xFFF59E0B), Color(0xFFFFEFD9), Icons.bolt),
  'review': NodeStyle(Color(0xFF8B5CF6), Color(0xFFEDE6FA), Icons.search),
  'done': NodeStyle(Color(0xFF10B981), Color(0xFFDDF3EA), Icons.emoji_events_outlined),
};
NodeStyle nodeOf(String k) => kNodes[k] ?? kNodes['planning']!;

/// Palet prioritas kartu: garis kiri, latar tag, teks tag, label.
class PrioStyle {
  final Color bar, bg, fg;
  final String label;
  const PrioStyle(this.bar, this.bg, this.fg, this.label);
}

const Map<String, PrioStyle> kPrio = {
  'tinggi': PrioStyle(Color(0xFFEF4444), Color(0xFFFDECEC), Color(0xFFC2413F), 'Tinggi'),
  'sedang': PrioStyle(Color(0xFFF59E0B), Color(0xFFFEF3D6), Color(0xFFB45309), 'Sedang'),
  'rendah': PrioStyle(Color(0xFF9CA3AF), Color(0xFFF1F3F6), Color(0xFF5B6478), 'Rendah'),
};
PrioStyle prioOf(String? k) => kPrio[k] ?? kPrio['rendah']!;

const Map<String, int> kDiffLevel = {'mudah': 1, 'sedang': 2, 'sulit': 3};

/// Toast ringan di atas layar (hijau bila berhasil, gelap bila galat).
void toast(BuildContext context, String msg, {bool ok = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg, style: inter(size: 13, weight: FontWeight.w600, color: Colors.white)),
    backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFF1F2937),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 3),
  ));
}

/// Bottom sheet putih berujung bulat 26 dengan pegangan, seperti `.sheet-body` di web.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    barrierColor: const Color(0x73111827),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 22 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(9)),
            ),
          ),
          builder(ctx),
        ]),
      ),
    ),
  );
}

/// Tombol biru penuh (btn-primary).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon, trailing;
  const PrimaryButton(this.label, {super.key, this.onPressed, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    return Opacity(
      opacity: on ? 1 : .5,
      child: Material(
        color: kPrimary,
        borderRadius: BorderRadius.circular(12),
        elevation: on ? 3 : 0,
        shadowColor: kPrimary.withAlpha(90),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 19), const SizedBox(width: 8)],
              Text(label, style: inter(size: 15, weight: FontWeight.w700, color: Colors.white)),
              if (trailing != null) ...[const SizedBox(width: 8), Icon(trailing, color: Colors.white, size: 19)],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Alias agar file lain bisa memakai warna kolom dari task.dart.
Color columnColor(String key) => columnOf(key).color;


/// Gambar karakter yang tidak merusak layar bila berkasnya gagal dimuat.
Widget chrImage(String name, {double? height, Alignment alignment = Alignment.center, BoxFit? fit}) => Image.asset(
      'assets/img/$name.png',
      height: height,
      alignment: alignment,
      fit: fit,
      errorBuilder: (_, __, ___) => SizedBox(height: height),
    );
