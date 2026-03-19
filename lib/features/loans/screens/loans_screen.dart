import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../../../core/widgets/kasby_text_field.dart';
import '../controllers/loan_controller.dart';
import '../models/loan_model.dart';
import 'loan_detail_screen.dart';

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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => controller.loadLoans(),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
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
            _buildCelestialBackground(),
            SafeArea(
              child: Column(
                children: [
                  //const SizedBox(height: 20), // Reduced top spacing
                  _buildSummaryHeader(controller),
                  Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _buildLoansList(List<Loan> loans) {
    final controller = Get.find<LoanController>();

    if (loans.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.loadLoans(),
        color: KasbyColors.primaryGold,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: Get.height * 0.2),
            Center(
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
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadLoans(),
      color: KasbyColors.primaryGold,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          8,
          0,
          8,
          40,
        ), // More horizontal space for cards
        itemCount: loans.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildLoanCard(loans[index], index);
        },
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, int index) {
    final controller = Get.find<LoanController>();
    final isPending = loan.status == LoanStatus.pending;
    final isCurrent = loan.status == LoanStatus.current;
    final isOverdue = loan.isOverdue;

    return KasbyGlassCard(
      padding: const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Section: User & Status
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildPremiumAvatar(loan.userName),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: isOverdue
                                  ? KasbyColors.error
                                  : Colors.white38,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isOverdue
                                    ? 'متأخر عن السداد'
                                    : 'موعد الاستحقاق القادم',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? KasbyColors.error
                                      : Colors.white38,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(loan),
                ],
              ),
            ),

            // Middle Section: Amount & Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white.withValues(alpha: 0.03),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'إجمالي السلفة المستحق',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (loan.interestRate > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: KasbyColors.primaryGold.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: KasbyColors.primaryGold
                                            .withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '+${loan.interestRate}% للفائدة',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: KasbyColors.primaryGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${loan.totalDue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: KasbyColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الأصل: \$${loan.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isCurrent || loan.status == LoanStatus.paid)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              loan.status == LoanStatus.paid
                                  ? 'تم السداد بالكامل'
                                  : '${loan.daysRemaining} يوم متبقي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isOverdue
                                    ? KasbyColors.error
                                    : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'مدفوع: \$${loan.paidAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: KasbyColors.success,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (isCurrent || loan.status == LoanStatus.paid) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'نسبة السداد',
                          style: TextStyle(fontSize: 10, color: Colors.white38),
                        ),
                        Text(
                          '${((loan.paidAmount / (loan.totalDue > 0 ? loan.totalDue : 1)) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loan.totalDue > 0
                            ? (loan.paidAmount / loan.totalDue)
                            : 0,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          loan.status == LoanStatus.paid
                              ? KasbyColors.success
                              : KasbyColors.primaryGold,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الوقت المنقضي',
                          style: TextStyle(fontSize: 10, color: Colors.white38),
                        ),
                        Text(
                          '${(loan.percentProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: loan.percentProgress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverdue ? KasbyColors.error : Colors.white24,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Dates Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildDateInfoCompact('بداية السلفة', loan.loanDate),
                  const Spacer(),
                  _buildDateInfoCompact(
                    'موعد السداد',
                    loan.repaymentDate,
                    highlight: isOverdue,
                  ),
                ],
              ),
            ),

            // Action Buttons Section
            if (isPending || isCurrent)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildActionButton(
                      label: 'التفاصيل',
                      icon: Icons.info_outline_rounded,
                      color: Colors.white,
                      onPressed: () =>
                          Get.to(() => LoanDetailScreen(loan: loan)),
                    ),
                    const VerticalDivider(width: 1, color: Colors.white10),
                    if (isPending) ...[
                      Expanded(
                        child: _buildActionButton(
                          label: 'رفض السلفة',
                          icon: Icons.close_rounded,
                          color: KasbyColors.error,
                          onPressed: () => _showRejectDialog(loan),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      Expanded(
                        child: _buildActionButton(
                          label: 'موافقة',
                          icon: Icons.check_rounded,
                          color: KasbyColors.success,
                          onPressed: () => controller.approveLoan(loan.id),
                        ),
                      ),
                    ],
                    if (isCurrent) ...[
                      Expanded(
                        child: _buildActionButton(
                          label: 'تم السداد',
                          icon: Icons.done_all_rounded,
                          color: KasbyColors.success,
                          onPressed: () => controller.updateLoanStatus(
                            loan.id,
                            LoanStatus.paid,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(LoanController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        children: [
          _buildSummaryItem(
            'نشطة',
            controller.loans
                .where((l) => l.status == LoanStatus.current)
                .length
                .toString(),
            KasbyColors.info,
          ),
          const SizedBox(width: 12),
          _buildSummaryItem(
            'معلقة',
            controller.loans
                .where((l) => l.status == LoanStatus.pending)
                .length
                .toString(),
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildSummaryItem(
            'متأخرة',
            controller.loans.where((l) => l.isOverdue).length.toString(),
            KasbyColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: KasbyGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumAvatar(String name) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: KasbyColors.primaryGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: KasbyColors.primaryGold.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Loan loan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: loan.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: loan.statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        loan.statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: loan.statusColor,
        ),
      ),
    );
  }

  Widget _buildDateInfoCompact(
    String label,
    DateTime date, {
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMMM yyyy', 'ar').format(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: highlight ? KasbyColors.error : Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(Loan loan) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('رفض السلفة', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من رفض سلفة البالغ قيمتها \$${loan.amount} للمستخدم ${loan.userName}؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              // Implementation for rejection
              Get.find<LoanController>().updateLoanStatus(
                loan.id,
                LoanStatus.defaulted,
              );
              Get.back();
            },
            child: const Text(
              'تأكيد الرفض',
              style: TextStyle(color: KasbyColors.error),
            ),
          ),
        ],
      ),
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
        ),
      ],
    );
  }
}
