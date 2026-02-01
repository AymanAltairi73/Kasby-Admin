import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الشروط والأحكام',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildTermSection(
                    '1. قبول الشروط',
                    'باستخدامك للوحة التحكم Kasby Panel، فإنك توافق على الالتزام بجميع الشروط والأحكام المذكورة هنا. إذا كنت لا توافق على أي جزء من هذه الشروط، يرجى عدم استخدام النظام.',
                    delay: 200,
                  ),
                  const SizedBox(height: 16),
                  _buildTermSection(
                    '2. مسؤولية الحساب',
                    'يتحمل المشرف كامل المسؤولية عن سرية حوزته وكلمة السر الخاصة به. يجب إخطار الإدارة فوراً عن أي استخدام غير مصرح به للحساب.',
                    delay: 400,
                  ),
                  const SizedBox(height: 16),
                  _buildTermSection(
                    '3. الاستخدام المصرح به',
                    'يقتصر استخدام هذه اللوحة على الأغراض الإدارية والرقابية للعمليات المالية والاستثمارات الخاصة بمنصة Kasby فقط.',
                    delay: 600,
                  ),
                  const SizedBox(height: 16),
                  _buildTermSection(
                    '4. خصوصية البيانات',
                    'نحن نلتزم بحماية بيانات المستخدمين والمشرفين. يتم تشفير جميع العمليات والبيانات الحساسة وفق أعلى المعايير الأمنية.',
                    delay: 800,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'آخر تحديث: 1 فبراير 2026',
                    style: TextStyle(
                      color: KasbyColors.textSecondary,
                      fontSize: 12,
                    ),
                  ).animate().fadeIn(delay: 1.seconds),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KasbyColors.primaryGold.withValues(alpha: 0.1),
            border: Border.all(
              color: KasbyColors.primaryGold.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.description_rounded,
            size: 48,
            color: KasbyColors.primaryGold,
          ),
        ).animate().scale(duration: const Duration(milliseconds: 600)).shake(),
        const SizedBox(height: 16),
        const Text(
          'اتفاقية الاستخدام الآمن',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
      ],
    );
  }

  Widget _buildTermSection(String title, String content, {required int delay}) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: KasbyColors.primaryGold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: KasbyColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1);
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        _buildOrb(
          top: -100,
          left: -100,
          size: 400,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -150,
          right: -150,
          size: 500,
          color: KasbyColors.primaryGold.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  Widget _buildOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color, blurRadius: 100, spreadRadius: 50),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -30, end: 30, duration: const Duration(seconds: 6))
              .moveX(begin: -30, end: 30, duration: const Duration(seconds: 8)),
    );
  }
}
