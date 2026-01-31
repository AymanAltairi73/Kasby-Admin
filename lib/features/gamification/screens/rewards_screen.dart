import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../../../core/widgets/kasby_button.dart';

/// Rewards Screen
/// Manage daily rewards, spin wheel, and points system
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المكافآت والنقاط')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Check-in
            const Text(
              'تسجيل الحضور اليومي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            KasbyCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: KasbyColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.calendarCheck,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مكافأة يومية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: KasbyColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '50 نقطة لكل يوم متتالي',
                              style: TextStyle(
                                fontSize: 14,
                                color: KasbyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'المستخدمون النشطون اليوم',
                          '1,234',
                          FontAwesomeIcons.users,
                          KasbyColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'إجمالي النقاط الموزعة',
                          '61,700',
                          FontAwesomeIcons.coins,
                          KasbyColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Spin Wheel
            const Text(
              'عجلة الحظ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            KasbyCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KasbyColors.primaryGold,
                              KasbyColors.success,
                              KasbyColors.info,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.dharmachakra,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'عجلة الحظ اليومية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: KasbyColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'فرصة واحدة يومياً للفوز',
                              style: TextStyle(
                                fontSize: 14,
                                color: KasbyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الجوائز المتاحة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPrizeChip('10 نقاط', KasbyColors.info),
                      _buildPrizeChip('25 نقاط', KasbyColors.success),
                      _buildPrizeChip('50 نقاط', KasbyColors.primaryGold),
                      _buildPrizeChip('100 نقاط', KasbyColors.warning),
                      _buildPrizeChip('\$5 رصيد', KasbyColors.error),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'المشاركون اليوم',
                          '856',
                          FontAwesomeIcons.userGroup,
                          KasbyColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'إجمالي الجوائز',
                          '\$425',
                          FontAwesomeIcons.gift,
                          KasbyColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Points System
            const Text(
              'نظام النقاط',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KasbyColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            KasbyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'طرق كسب النقاط',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPointsRule('تسجيل الدخول اليومي', '10 نقاط'),
                  const Divider(color: KasbyColors.background),
                  _buildPointsRule('إحالة صديق', '100 نقاط'),
                  const Divider(color: KasbyColors.background),
                  _buildPointsRule('أول استثمار', '200 نقاط'),
                  const Divider(color: KasbyColors.background),
                  _buildPointsRule('إكمال الملف الشخصي', '50 نقاط'),
                  const SizedBox(height: 16),
                  const Text(
                    'استبدال النقاط',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: KasbyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPointsRule('1000 نقطة', '\$10 رصيد'),
                  const Divider(color: KasbyColors.background),
                  _buildPointsRule('2500 نقطة', '\$30 رصيد'),
                  const Divider(color: KasbyColors.background),
                  _buildPointsRule('5000 نقطة', '\$75 رصيد'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Configuration Button
            KasbyButton(
              text: 'إعدادات المكافآت',
              onPressed: () {
                Get.snackbar(
                  'قريباً',
                  'ستتمكن من تعديل قيم المكافآت والنقاط',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: FontAwesomeIcons.gear,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: KasbyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPointsRule(String action, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: const TextStyle(fontSize: 14, color: KasbyColors.textBody),
          ),
          Text(
            points,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: KasbyColors.primaryGold,
            ),
          ),
        ],
      ),
    );
  }
}
