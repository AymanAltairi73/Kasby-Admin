import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'كيف يمكنني إضافة مشرف جديد لوحدة التحكم؟',
      'answer':
          'يمكنك ذلك من خلال قسم "إدارة المشرفين" في الإعدادات، ثم النقر على زر الإضافة وتعبئة بيانات المشرف الجديد مع تحديد الصلاحيات المطلوبة.',
    },
    {
      'question': 'ما هي طريقة تفعيل وضع الصيانة للتطبيق؟',
      'answer':
          'يتم التفعيل من قسم "وضع الصيانة" في الإعدادات، حيث يمكنك كتابة رسالة مخصصة تظهر للمستخدمين أثناء فترة العمل على النظام.',
    },
    {
      'question': 'كيف يتم تأمين بيانات الاستثمارات المالية؟',
      'answer':
          'تستخدم Kasby Panel أنظمة تشفير متطورة (End-to-End Encryption) لضمان عدم وصول أي طرف غير مصرح له لبيانات المستخدمين أو الحركات المالية.',
    },
    {
      'question': 'هل يمكنني استخراج تقارير بصيغة PDF؟',
      'answer':
          'نعم، في قسم المعاملات والاستثمارات، يتوفر خيار "تصدير" الذي يتيح لك تحميل التقارير بصيغ متعددة تشمل PDF و CSV.',
    },
    {
      'question': 'كيف يمكنني استعادة كلمة المرور الخاصة بي؟',
      'answer':
          'من شاشة تسجيل الدخول، انقر على "نسيت كلمة المرور" وأدخل بريدك الإلكتروني، سيصلك رمز سحري لاستعادة الوصول فوراً.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الأسئلة الشائعة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildCelestialBackground(),
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _faqs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildHeader();
                final faq = _faqs[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildFaqItem(
                    faq['question']!,
                    faq['answer']!,
                    index: index,
                  ),
                );
              },
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
            Icons.help_outline_rounded,
            size: 48,
            color: KasbyColors.primaryGold,
          ),
        ).animate().scale(duration: const Duration(milliseconds: 600)).shake(),
        const SizedBox(height: 16),
        const Text(
          'هل لديك أي استفسار؟',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer, {required int index}) {
    return KasbyGlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          iconColor: KasbyColors.primaryGold,
          collapsedIconColor: KasbyColors.textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: KasbyColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 150).milliseconds).slideX(begin: 0.1);
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        _buildOrb(
          top: 100,
          right: -100,
          size: 350,
          color: KasbyColors.info.withValues(alpha: 0.05),
        ),
        _buildOrb(
          bottom: -100,
          left: -100,
          size: 450,
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
              .moveY(begin: -20, end: 20, duration: const Duration(seconds: 5))
              .moveX(begin: -20, end: 20, duration: const Duration(seconds: 7)),
    );
  }
}
