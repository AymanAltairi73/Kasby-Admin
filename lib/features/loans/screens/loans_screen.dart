import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/loan_controller.dart';
import '../models/loan_model.dart';

/// Kasby Loans Screen
/// Table-based management for user loans
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoanController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('سلفات كاسبي'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: KasbyTextField(
                    hintText: 'البحث باسم المستخدم أو المبلغ...',
                    prefixIcon: Icons.search,
                    onChanged: (value) => controller.updateSearch(value),
                  ),
                ),
                const TabBar(
                  indicatorColor: KasbyColors.primaryGold,
                  labelColor: KasbyColors.primaryGold,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: 'السلفات الحالية'),
                    Tab(text: 'السلفات المدفوعة'),
                    Tab(text: 'السلفات المتأخرة'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background Layer
            _buildCelestialBackground(),

            Padding(
              padding: const EdgeInsets.only(top: 220),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: KasbyColors.primaryGold,
                    ),
                  );
                }

                return TabBarView(
                  children: [
                    _buildLoansList(controller.currentLoans),
                    _buildLoansList(controller.paidLoans),
                    _buildLoansList(controller.delayedLoans),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansList(List<Loan> loans) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FontAwesomeIcons.clipboardCheck,
                size: 48,
                color: KasbyColors.primaryGold.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد سلفات متاحة',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).scale(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      itemCount: loans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildLoanCard(loans[index], index);
      },
    );
  }

  Widget _buildLoanCard(Loan loan, int index) {
    return KasbyGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.user,
                      size: 14,
                      color: KasbyColors.primaryGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loan.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: loan.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: loan.statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  loan.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: loan.statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),

          // Amount
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مبلغ السلفة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      '\$${loan.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: KasbyColors.primaryGold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dates
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDateInfo(
                  'تاريخ السلفة',
                  DateFormat('yyyy/MM/dd', 'en').format(loan.loanDate),
                  Icons.calendar_today_rounded,
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                _buildDateInfo(
                  'تاريخ الاسترجاع',
                  DateFormat('yyyy/MM/dd', 'en').format(loan.repaymentDate),
                  Icons.event_repeat_rounded,
                  isOverdue: loan.status == LoanStatus.delayed,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1);
  }

  Widget _buildDateInfo(
    String label,
    String date,
    IconData icon, {
    bool isOverdue = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isOverdue
                ? KasbyColors.error
                : Colors.white.withValues(alpha: 0.9),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildCelestialBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0F172A)),
        Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KasbyColors.primaryGold.withValues(alpha: 0.03),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -20, end: 20, duration: const Duration(seconds: 4)),
      ],
    );
  }
}
