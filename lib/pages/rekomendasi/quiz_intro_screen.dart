import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamatutor_kanban/model/user.dart';
import 'quiz_questions_screen.dart';

class QuizIntroScreen extends StatelessWidget {
  final User? user;

  const QuizIntroScreen({Key? key, this.user, required String userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // ─── 1. GAMBAR ILUSTRASI ───
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -8 * value), 
                    child: child,
                  );
                },
                child: Image.asset(
                  'lib/assets/quiz_intro_illustration.png',
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.psychology_rounded,
                    size: 120,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // ─── 2. JUDUL ───
              const Text(
                'Yuk kenalan dulu sama gaya belajarmu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B), // Warna teks gelap elegan
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              // ─── 3. DESKRIPSI ───
              const Text(
                'Biar rekomendasi strategi belajar di Gamatutormu makin pas buat kamu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B), // Abu-abu soft
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),

              // ─── 4. INFO DETAIL (Pertanyaan & Waktu) ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.list_alt_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                        SizedBox(height: 6),
                        Text(
                          '6 pertanyaan',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'sekitar 1 menit',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),

              // ─── 5. TOMBOL MULAI (CTA) ───
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6), // Biru terang khas tombol
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizQuestionsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Mulai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}