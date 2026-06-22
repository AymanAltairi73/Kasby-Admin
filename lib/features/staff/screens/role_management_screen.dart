// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../../../core/theme/kasby_colors.dart';
// import '../../../core/widgets/kasby_card.dart';
// import '../../../core/widgets/kasby_text_field.dart';
// import '../../../core/services/permission_service.dart';
// import '../controllers/staff_controller.dart';

// class RoleManagementScreen extends StatelessWidget {
//   const RoleManagementScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(StaffController());
//     final permService = Get.find<PermissionService>();
//     final isSuperAdmin = permService.adminPrivilege.value == 'superadmin';

//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('إدارة الموظفين'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: controller.loadStaff,
//             ),
//           ],
//           bottom: const TabBar(
//             indicatorColor: KasbyColors.primaryGold,
//             labelColor: KasbyColors.primaryGold,
//             unselectedLabelColor: KasbyColors.textSecondary,
//             tabs: [
//               Tab(text: 'الموظفون', icon: Icon(FontAwesomeIcons.users, size: 16)),
//               Tab(text: 'الصلاحيات', icon: Icon(FontAwesomeIcons.shieldHalved, size: 16)),
//             ],
//           ),
//         ),
//         floatingActionButton: isSuperAdmin
//             ? FloatingActionButton.extended(
//                 onPressed: () => _showInviteDialog(context, controller),
//                 backgroundColor: KasbyColors.primaryGold,
//                 icon: const Icon(Icons.person_add, color: Colors.black),
//                 label: const Text(
//                   'إضافة مسؤول',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               )
//             : null,
//         body: TabBarView(
//           children: [
//             _buildStaffList(controller, isSuperAdmin),
//             _buildPermissionMatrix(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStaffList(StaffController controller, bool isSuperAdmin) {
//     return Obx(() {
//       if (controller.isLoading.value && controller.staffMembers.isEmpty) {
//         return const Center(
//           child: CircularProgressIndicator(color: KasbyColors.primaryGold),
//         );
//       }

//       if (controller.staffMembers.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 FontAwesomeIcons.userSlash,
//                 size: 56,
//                 color: KasbyColors.textSecondary.withValues(alpha: 0.3),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'لا يوجد موظفون',
//                 style: TextStyle(
//                   color: KasbyColors.textSecondary,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }

//       return RefreshIndicator(
//         onRefresh: controller.loadStaff,
//         color: KasbyColors.primaryGold,
//         child: ListView.separated(
//           padding: const EdgeInsets.all(16),
//           itemCount: controller.staffMembers.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 10),
//           itemBuilder: (context, index) {
//             final member = controller.staffMembers[index];
//             return _buildStaffCard(context, member, controller, isSuperAdmin);
//           },
//         ),
//       );
//     });
//   }

//   Widget _buildStaffCard(
//     BuildContext context,
//     AdminStaffMember member,
//     StaffController controller,
//     bool isSuperAdmin,
//   ) {
//     final roleLabel = StaffController.roleLabels[member.role] ?? member.role;
//     final roleColor = _roleColor(member.role);

//     return KasbyCard(
//       onTap: isSuperAdmin
//           ? () => _showRoleSheet(context, member, controller)
//           : null,
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 24,
//             backgroundColor: roleColor.withValues(alpha: 0.15),
//             backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
//                 ? NetworkImage(member.avatarUrl!)
//                 : null,
//             child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
//                 ? Text(
//                     member.name.isNotEmpty ? member.name[0] : '?',
//                     style: TextStyle(
//                       color: roleColor,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   )
//                 : null,
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   member.name.isNotEmpty ? member.name : member.email,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   member.email,
//                   style: const TextStyle(
//                     color: KasbyColors.textSecondary,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: roleColor.withValues(alpha: 0.12),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: roleColor.withValues(alpha: 0.3)),
//             ),
//             child: Text(
//               roleLabel,
//               style: TextStyle(
//                 color: roleColor,
//                 fontSize: 11,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           if (isSuperAdmin) ...[
//             const SizedBox(width: 8),
//             const Icon(Icons.arrow_forward_ios, size: 14, color: KasbyColors.textSecondary),
//           ],
//         ],
//       ),
//     );
//   }

//   void _showRoleSheet(
//     BuildContext context,
//     AdminStaffMember member,
//     StaffController controller,
//   ) {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(24),
//         decoration: const BoxDecoration(
//           color: KasbyColors.surface,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: KasbyColors.textSecondary.withValues(alpha: 0.3),
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               member.name.isNotEmpty ? member.name : member.email,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: KasbyColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               member.email,
//               style: const TextStyle(
//                 color: KasbyColors.textSecondary,
//                 fontSize: 13,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Align(
//               alignment: Alignment.centerRight,
//               child: Text(
//                 'اختر الصلاحية',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: KasbyColors.textPrimary,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             ...StaffController.adminRoles.map((role) {
//               final isSelected = member.role == role;
//               final label = StaffController.roleLabels[role] ?? role;
//               final color = _roleColor(role);

//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: InkWell(
//                   onTap: () {
//                     Get.back();
//                     if (!isSelected) {
//                       controller.updateRole(member.id, role);
//                     }
//                   },
//                   borderRadius: BorderRadius.circular(12),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isSelected
//                           ? color.withValues(alpha: 0.1)
//                           : Colors.transparent,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: isSelected
//                             ? color.withValues(alpha: 0.4)
//                             : KasbyColors.textSecondary.withValues(alpha: 0.15),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           _roleIcon(role),
//                           size: 18,
//                           color: isSelected ? color : KasbyColors.textSecondary,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             label,
//                             style: TextStyle(
//                               color: isSelected ? color : KasbyColors.textPrimary,
//                               fontWeight: isSelected
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                         ),
//                         if (isSelected)
//                           Icon(Icons.check_circle, color: color, size: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: TextButton.icon(
//                 onPressed: () {
//                   Get.back();
//                   _confirmRemoveAdmin(member, controller);
//                 },
//                 icon: const Icon(Icons.person_remove, color: KasbyColors.error),
//                 label: const Text(
//                   'إزالة من المسؤولين',
//                   style: TextStyle(color: KasbyColors.error),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }

//   void _confirmRemoveAdmin(AdminStaffMember member, StaffController controller) {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: KasbyColors.surface,
//         title: const Text(
//           'تأكيد الإزالة',
//           style: TextStyle(color: KasbyColors.textPrimary),
//         ),
//         content: Text(
//           'هل تريد إزالة "${member.name}" من المسؤولين؟\nسيتم تحويل صلاحيته إلى مستخدم عادي.',
//           style: const TextStyle(color: KasbyColors.textBody),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text(
//               'إلغاء',
//               style: TextStyle(color: KasbyColors.textSecondary),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               controller.removeAdmin(member.id);
//             },
//             child: const Text(
//               'إزالة',
//               style: TextStyle(color: KasbyColors.error),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showInviteDialog(BuildContext context, StaffController controller) {
//     final textController = TextEditingController();
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: KasbyColors.surface,
//         title: const Text(
//           'إضافة مسؤول جديد',
//           style: TextStyle(color: KasbyColors.textPrimary),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'أدخل البريد الإلكتروني أو رقم الهاتف',
//               style: TextStyle(color: KasbyColors.textSecondary, fontSize: 13),
//             ),
//             const SizedBox(height: 16),
//             KasbyTextField(
//               controller: textController,
//               hintText: 'البريد أو رقم الهاتف',
//               prefixIcon: FontAwesomeIcons.userPlus,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text(
//               'إلغاء',
//               style: TextStyle(color: KasbyColors.textSecondary),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               final identifier = textController.text.trim();
//               if (identifier.isEmpty) {
//                 Get.snackbar('خطأ', 'الرجاء إدخال بريد أو رقم هاتف');
//                 return;
//               }
//               Get.back();
//               controller.inviteAdmin(identifier);
//             },
//             child: const Text(
//               'إضافة',
//               style: TextStyle(color: KasbyColors.primaryGold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPermissionMatrix() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'مصفوفة الصلاحيات',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: KasbyColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           const Text(
//             'ما يمكن لكل دور القيام به',
//             style: TextStyle(
//               color: KasbyColors.textSecondary,
//               fontSize: 13,
//             ),
//           ),
//           const SizedBox(height: 16),
//           ...StaffController.adminRoles.map((role) {
//             final label = StaffController.roleLabels[role] ?? role;
//             final permissions = StaffController.permissionMatrix[role] ?? {};
//             final color = _roleColor(role);

//             return Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: KasbyCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(_roleIcon(role), size: 18, color: color),
//                         const SizedBox(width: 10),
//                         Text(
//                           label,
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 15,
//                             color: color,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 6,
//                       children: permissions.entries.map((entry) {
//                         final permLabel =
//                             StaffController.permissionLabels[entry.key] ??
//                                 entry.key;
//                         return Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 5,
//                           ),
//                           decoration: BoxDecoration(
//                             color: entry.value
//                                 ? KasbyColors.success.withValues(alpha: 0.1)
//                                 : KasbyColors.error.withValues(alpha: 0.08),
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color: entry.value
//                                   ? KasbyColors.success.withValues(alpha: 0.3)
//                                   : KasbyColors.error.withValues(alpha: 0.2),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 entry.value ? Icons.check : Icons.close,
//                                 size: 12,
//                                 color: entry.value
//                                     ? KasbyColors.success
//                                     : KasbyColors.error,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 permLabel,
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: entry.value
//                                       ? KasbyColors.success
//                                       : KasbyColors.error,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Color _roleColor(String role) {
//     switch (role) {
//       case 'superadmin':
//         return KasbyColors.primaryGold;
//       case 'admin':
//         return KasbyColors.info;
//       case 'finance_ops':
//         return KasbyColors.success;
//       case 'support':
//         return KasbyColors.warning;
//       case 'viewer':
//         return KasbyColors.textSecondary;
//       default:
//         return KasbyColors.textSecondary;
//     }
//   }

//   IconData _roleIcon(String role) {
//     switch (role) {
//       case 'superadmin':
//         return FontAwesomeIcons.crown;
//       case 'admin':
//         return FontAwesomeIcons.userShield;
//       case 'finance_ops':
//         return FontAwesomeIcons.moneyBillTransfer;
//       case 'support':
//         return FontAwesomeIcons.headset;
//       case 'viewer':
//         return FontAwesomeIcons.eye;
//       default:
//         return FontAwesomeIcons.user;
//     }
//   }
// }
