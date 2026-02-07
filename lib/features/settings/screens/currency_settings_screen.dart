import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_button.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات العملات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrencyCard(
            name: 'الدولار الأمريكي',
            code: 'USD',
            rate: '1.00',
            isBase: true,
            icon: FontAwesomeIcons.dollarSign,
          ),
          const SizedBox(height: 12),
          _buildCurrencyCard(
            name: 'الدرهم الإماراتي',
            code: 'AED',
            rate: '3.67',
            isBase: false,
            icon: FontAwesomeIcons.briefcase,
          ),
          const SizedBox(height: 12),
          _buildCurrencyCard(
            name: 'الريال السعودي',
            code: 'SAR',
            rate: '3.75',
            isBase: false,
            icon: FontAwesomeIcons.coins,
          ),
          const SizedBox(height: 24),
          KasbyButton(
            text: 'إضافة عملة جديدة',
            onPressed: () {},
            isOutlined: true,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard({
    required String name,
    required String code,
    required String rate,
    required bool isBase,
    required IconData icon,
  }) {
    return KasbyGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: KasbyColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isBase)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KasbyColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'الأساسية',
                          style: TextStyle(
                            color: KasbyColors.success,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '1 USD = $rate $code',
                  style: const TextStyle(
                    color: KasbyColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: KasbyColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
