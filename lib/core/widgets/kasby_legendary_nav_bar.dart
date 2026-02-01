import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 800))
        .slideY(begin: 0.5);
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
                      color: KasbyColors.primaryGold.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: const Duration(seconds: 2),
                color: Colors.white.withOpacity(0.3),
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
                              color: KasbyColors.primaryGold.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: const Duration(seconds: 2),
                      )
                      .fadeIn(),

                Icon(
                      icon,
                      color: isSelected
                          ? KasbyColors.primaryGold
                          : KasbyColors.textSecondary,
                      size: isSelected ? 28 : 24,
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                    )
                    .shimmer(
                      duration: const Duration(seconds: 2),
                      color: Colors.white.withOpacity(0.2),
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
