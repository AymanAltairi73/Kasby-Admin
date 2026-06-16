import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../users/controllers/user_controller.dart';
import '../../users/screens/user_list_screen.dart';

/// Shared list screen for role-based staff management (owner / worker).
class RoleManagementScreen extends StatelessWidget {
  final String role;
  final String title;

  const RoleManagementScreen({
    super.key,
    required this.role,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Obx(() {
        final staff =
            userController.users.where((u) => u.role == role).toList();

        if (userController.isLoading.value && staff.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (staff.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('لا يوج $title'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.to(() => const UserListScreen()),
                  child: const Text('إدارة المستخدمين'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: staff.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = staff[index];
            return ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(user.name),
              subtitle: Text('${user.email} • ${user.status}'),
              trailing: Text(user.country),
            );
          },
        );
      }),
    );
  }
}
