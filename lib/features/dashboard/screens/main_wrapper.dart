import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../users/screens/user_list_screen.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/widgets/kasby_legendary_nav_bar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late final PageController _pageController;
  final controller = Get.put(MainController());

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: controller.currentIndex.value,
    );

    // Listen to controller changes to sync PageView
    ever(controller.currentIndex, (index) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutExpo,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardScreen(),
      const UserListScreen(),
      const TransactionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Only via Nav Bar
        children: screens,
      ),
      bottomNavigationBar: Obx(
        () => KasbyLegendaryNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) => controller.changePage(index),
        ),
      ),
    );
  }
}
