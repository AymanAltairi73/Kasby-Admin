import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';
import '../../../core/widgets/kasby_text_field.dart';

class FeeSettingsScreen extends StatelessWidget {
  const FeeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الرسوم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeeSection(
              title: 'رسوم الإيداع',
              icon: FontAwesomeIcons.arrowDown,
              fees: [
                _FeeItem(label: 'الإيداع البنكي', value: '1.5%'),
                _FeeItem(label: 'بطاقة الائتمان', value: '2.5%'),
                _FeeItem(label: 'العملات الرقمية', value: '0.0%'),
              ],
            ),
            const SizedBox(height: 24),
            _buildFeeSection(
              title: 'رسوم السحب',
              icon: FontAwesomeIcons.arrowUp,
              fees: [
                _FeeItem(label: 'السحب البنكي', value: '\$10.00'),
                _FeeItem(label: 'المحفظة الإلكترونية', value: '1.0%'),
              ],
            ),
            const SizedBox(height: 24),
            _buildFeeSection(
              title: 'رسوم الاستثمار',
              icon: FontAwesomeIcons.chartPie,
              fees: [
                _FeeItem(label: 'رسوم الإدارة سنوية', value: '2.0%'),
                _FeeItem(label: 'رسوم الأداء', value: '15.0%'),
              ],
            ),
            const SizedBox(height: 40),
            KasbyButton(
              text: 'حفظ التغييرات',
              onPressed: () =>
                  Get.snackbar('تم', 'تم حفظ إعدادات الرسوم بنجاح'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSection({
    required String title,
    required IconData icon,
    required List<_FeeItem> fees,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: KasbyColors.primaryGold, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(children: fees.map((fee) => _buildFeeCard(fee)).toList()),
      ],
    );
  }

  Widget _buildFeeCard(_FeeItem fee) {
    return KasbyGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fee.label,
            style: const TextStyle(color: KasbyColors.textBody, fontSize: 14),
          ),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: KasbyTextField(
                  controller: TextEditingController(text: fee.value),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 16,
                  color: KasbyColors.primaryGold,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeItem {
  final String label;
  final String value;
  _FeeItem({required this.label, required this.value});
}
