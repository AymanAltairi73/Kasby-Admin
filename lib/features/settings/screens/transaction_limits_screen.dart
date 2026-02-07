import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';

class TransactionLimitsScreen extends StatelessWidget {
  const TransactionLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حدود المعاملات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLimitSection(
            title: 'المستخدم العادي',
            limits: [
              _LimitItem(label: 'الحد الأدنى للإيداع', value: '50'),
              _LimitItem(label: 'الحد الأقصى للإيداع (يومي)', value: '5000'),
              _LimitItem(label: 'الحد الأدنى للسحب', value: '20'),
              _LimitItem(label: 'الحد الأقصى للسحب (شهري)', value: '10000'),
            ],
          ),
          const SizedBox(height: 24),
          _buildLimitSection(
            title: 'المستخدم الموثق / VIP',
            limits: [
              _LimitItem(label: 'الحد الأدنى للإيداع', value: '10'),
              _LimitItem(label: 'الحد الأقصى للإيداع (يومي)', value: '50000'),
              _LimitItem(label: 'الحد الأدنى للسحب', value: '10'),
              _LimitItem(label: 'الحد الأقصى للسحب (شهري)', value: 'Unlimited'),
            ],
          ),
          const SizedBox(height: 40),
          KasbyButton(
            text: 'حفظ كافة الحدود',
            onPressed: () => Get.snackbar('تم', 'تم تحديث حدود المعاملات'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitSection({
    required String title,
    required List<_LimitItem> limits,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KasbyColors.primaryGold,
          ),
        ),
        const SizedBox(height: 12),
        ...limits.map(
          (limit) => KasbyGlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  limit.label,
                  style: const TextStyle(
                    color: KasbyColors.textBody,
                    fontSize: 14,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: KasbyTextField(
                    controller: TextEditingController(text: limit.value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LimitItem {
  final String label;
  final String value;
  _LimitItem({required this.label, required this.value});
}
