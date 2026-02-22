import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import '../theme/kasby_colors.dart';

class KasbyLegendaryNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const KasbyLegendaryNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      height: 70,
      child: Stack(
        children: [
          // Glass Background
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),

          // Flying Glow Indicator
          _buildFlyingGlow(context),

          // Navigation Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'الرئيسية'),
              _buildNavItem(1, Icons.people_alt_rounded, 'المستخدمين'),
              _buildNavItem(
                2,
                Icons.account_balance_wallet_rounded,
                'المعاملات',
              ),
              _buildNavItem(3, Icons.settings_rounded, 'الإعدادات'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlyingGlow(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 48;
    final itemWidth = width / 4;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      left: currentIndex * itemWidth + (itemWidth / 2) - 25,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: KasbyColors.primaryGold,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: KasbyColors.primaryGold.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: KasbyColors.primaryGold.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                Icon(
                  icon,
                  color: isSelected
                      ? KasbyColors.primaryGold
                      : KasbyColors.textSecondary,
                  size: isSelected ? 28 : 24,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? KasbyColors.primaryGold
                    : KasbyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
