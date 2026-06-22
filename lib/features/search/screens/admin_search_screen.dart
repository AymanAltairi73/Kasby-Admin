import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_glass_card.dart';
import '../controllers/admin_search_controller.dart';

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  final controller = Get.put(AdminSearchController());
  final _focusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: controller.onQueryChanged,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) controller.addToRecent(val.trim());
          },
          style: TextStyle(color: onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'بحث في النظام...',
            hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.4)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        actions: [
          Obx(() => controller.query.value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: onSurface.withValues(alpha: 0.5)),
                  onPressed: () {
                    _textController.clear();
                    controller.onQueryChanged('');
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(theme),
          Expanded(
            child: Obx(() {
              if (controller.query.value.isEmpty) {
                return _buildRecentSearches(theme, onSurface);
              }
              if (controller.isLoading.value) {
                return _buildShimmerLoading(theme);
              }
              if (controller.results.isEmpty) {
                return _buildEmptyState(onSurface);
              }
              return _buildResultsList(theme, onSurface);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    final categories = [
      (SearchCategory.all, 'الكل', FontAwesomeIcons.globe),
      (SearchCategory.users, 'المستخدمين', FontAwesomeIcons.users),
      (SearchCategory.transactions, 'المعاملات', FontAwesomeIcons.moneyBillTransfer),
      (SearchCategory.investments, 'الاستثمارات', FontAwesomeIcons.chartPie),
      (SearchCategory.agents, 'الوكلاء', FontAwesomeIcons.networkWired),
      (SearchCategory.loans, 'السلفات', FontAwesomeIcons.handHoldingDollar),
    ];

    return SizedBox(
      height: 48,
      child: Obx(() => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (cat, label, icon) = categories[index];
              final selected = controller.selectedCategory.value == cat;
              return GestureDetector(
                onTap: () => controller.setCategory(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? KasbyColors.primaryGold.withValues(alpha: 0.15)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? KasbyColors.primaryGold.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: selected ? KasbyColors.primaryGold : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? KasbyColors.primaryGold : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }

  Widget _buildRecentSearches(ThemeData theme, Color onSurface) {
    return Obx(() {
      if (controller.recentSearches.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, size: 64, color: onSurface.withValues(alpha: 0.15)),
              const SizedBox(height: 16),
              Text(
                'ابحث عن مستخدمين، معاملات، استثمارات...',
                style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عمليات بحث سابقة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: const Text('مسح الكل', style: TextStyle(color: KasbyColors.primaryGold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...controller.recentSearches.map((term) => ListTile(
                leading: Icon(Icons.history_rounded, color: onSurface.withValues(alpha: 0.3), size: 20),
                title: Text(term, style: TextStyle(color: onSurface, fontSize: 14)),
                onTap: () {
                  _textController.text = term;
                  controller.onQueryChanged(term);
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
        ],
      );
    });
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.15),
      highlightColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color onSurface) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب كلمات بحث مختلفة',
            style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, Color onSurface) {
    final grouped = <SearchCategory, List<SearchResult>>{};
    for (final r in controller.results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Row(
              children: [
                Icon(_categoryIcon(entry.key), size: 14, color: KasbyColors.primaryGold),
                const SizedBox(width: 8),
                Text(
                  _categoryLabel(entry.key),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.value.length}',
                    style: const TextStyle(fontSize: 10, color: KasbyColors.primaryGold, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ...entry.value.map((result) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: KasbyGlassCard(
                  onTap: () => _navigateToResult(result),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _categoryColor(result.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _categoryIcon(result.type),
                          size: 16,
                          color: _categoryColor(result.type),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _categoryColor(result.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _categoryLabel(result.type),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _categoryColor(result.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ];
      }).toList(),
    );
  }

  void _navigateToResult(SearchResult result) {
    controller.addToRecent(controller.query.value);
    switch (result.type) {
      case SearchCategory.users:
        Get.toNamed('/users');
        break;
      case SearchCategory.transactions:
        Get.toNamed('/transactions');
        break;
      case SearchCategory.investments:
        Get.toNamed('/investment-plans');
        break;
      case SearchCategory.agents:
        Get.toNamed('/agents');
        break;
      case SearchCategory.loans:
        Get.toNamed('/loans');
        break;
      case SearchCategory.all:
        break;
    }
  }

  IconData _categoryIcon(SearchCategory cat) {
    switch (cat) {
      case SearchCategory.users:
        return FontAwesomeIcons.users;
      case SearchCategory.transactions:
        return FontAwesomeIcons.moneyBillTransfer;
      case SearchCategory.investments:
        return FontAwesomeIcons.chartPie;
      case SearchCategory.agents:
        return FontAwesomeIcons.networkWired;
      case SearchCategory.loans:
        return FontAwesomeIcons.handHoldingDollar;
      case SearchCategory.all:
        return FontAwesomeIcons.globe;
    }
  }

  String _categoryLabel(SearchCategory cat) {
    switch (cat) {
      case SearchCategory.users:
        return 'المستخدمين';
      case SearchCategory.transactions:
        return 'المعاملات';
      case SearchCategory.investments:
        return 'الاستثمارات';
      case SearchCategory.agents:
        return 'الوكلاء';
      case SearchCategory.loans:
        return 'السلفات';
      case SearchCategory.all:
        return 'الكل';
    }
  }

  Color _categoryColor(SearchCategory cat) {
    switch (cat) {
      case SearchCategory.users:
        return KasbyColors.primaryGold;
      case SearchCategory.transactions:
        return KasbyColors.error;
      case SearchCategory.investments:
        return KasbyColors.info;
      case SearchCategory.agents:
        return KasbyColors.glowOrange;
      case SearchCategory.loans:
        return KasbyColors.success;
      case SearchCategory.all:
        return KasbyColors.primaryGold;
    }
  }
}
