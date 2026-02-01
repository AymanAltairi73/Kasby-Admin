import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/kasby_colors.dart';
import '../../../core/widgets/kasby_card.dart';
import '../models/admin_model.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for admins
    final admins = [
      AdminUser(
        id: '1',
        name: 'أحمد علي',
        email: 'ahmed@kasby.com',
        role: AdminRole.superAdmin,
        status: 'Active',
        createdAt: DateTime(2023, 1, 1),
        lastLogin: 'منذ 5 دقائق',
      ),
      AdminUser(
        id: '2',
        name: 'سارة خالد',
        email: 'sara@kasby.com',
        role: AdminRole.manager,
        status: 'Active',
        createdAt: DateTime(2023, 5, 12),
        lastLogin: 'منذ ساعة',
      ),
      AdminUser(
        id: '3',
        name: 'ناصر فهد',
        email: 'nasser@kasby.com',
        role: AdminRole.support,
        status: 'Inactive',
        createdAt: DateTime(2024, 2, 20),
        lastLogin: 'منذ 3 أيام',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المشرفين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Get.snackbar('قريباً', 'إضافة مشرف جديد قيد التطوير');
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: admins.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final admin = admins[index];
          return _buildAdminCard(admin);
        },
      ),
    );
  }

  Widget _buildAdminCard(AdminUser admin) {
    return KasbyCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: admin.role == AdminRole.superAdmin
                      ? KasbyColors.primaryGradient
                      : null,
                  color: admin.role != AdminRole.superAdmin
                      ? KasbyColors.surface
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KasbyColors.primaryGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    admin.name[0],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: admin.role == AdminRole.superAdmin
                          ? Colors.black
                          : KasbyColors.primaryGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KasbyColors.textPrimary,
                      ),
                    ),
                    Text(
                      admin.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KasbyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRoleBadge(admin.role),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: KasbyColors.surface, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'آخر ظهور',
                    style: TextStyle(
                      fontSize: 10,
                      color: KasbyColors.textSecondary,
                    ),
                  ),
                  Text(
                    admin.lastLogin,
                    style: const TextStyle(
                      fontSize: 12,
                      color: KasbyColors.textBody,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: KasbyColors.info),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      admin.status == 'Active'
                          ? Icons.block
                          : Icons.check_circle_outline,
                      color: admin.status == 'Active'
                          ? KasbyColors.error
                          : KasbyColors.success,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(AdminRole role) {
    String label = '';
    Color color = Colors.grey;

    switch (role) {
      case AdminRole.superAdmin:
        label = 'مدير عام';
        color = KasbyColors.primaryGold;
        break;
      case AdminRole.manager:
        label = 'مدير';
        color = KasbyColors.success;
        break;
      case AdminRole.support:
        label = 'دعم فني';
        color = KasbyColors.info;
        break;
      case AdminRole.viewer:
        label = 'مشاهد';
        color = KasbyColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
