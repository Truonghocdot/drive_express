import 'package:flutter/material.dart';

import '../driver_app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/driver_shell.dart';
import 'history/driver_history_page.dart';
import 'home/driver_home_page.dart';
import 'profile/driver_profile_page.dart';
import 'wallet/wallet_page.dart';

class MainDriverNavigationPage extends StatefulWidget {
  const MainDriverNavigationPage({super.key, required this.controller});

  final DriverAppController controller;

  @override
  State<MainDriverNavigationPage> createState() =>
      _MainDriverNavigationPageState();
}

class _MainDriverNavigationPageState extends State<MainDriverNavigationPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DriverHomePage(controller: widget.controller),
      DriverHistoryPage(controller: widget.controller),
      WalletPage(controller: widget.controller),
      DriverProfilePage(controller: widget.controller),
    ];
    const titles = ['Hoạt động', 'Lịch sử', 'Thu nhập', 'Hồ sơ'];
    final online = widget.controller.profile?.availabilityStatus == 'ONLINE';

    return Scaffold(
      extendBody: index == 0,
      extendBodyBehindAppBar: index == 0,
      appBar: index == 0
          ? null
          : DriverShellAppBar(
              title: titles[index],
              online: online,
              onProfile: () => setState(() => index = 3),
            ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.driverTokens.surfaceLow.withValues(
          alpha: 0.95,
        ),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me),
            label: 'Hoạt động',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Thu nhập',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
