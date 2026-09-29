import 'package:flutter/material.dart';

import '../client_app_controller.dart';
import 'home/home_page.dart';
import 'order/order_history_page.dart';
import 'profile/notifications_page.dart';
import 'profile/profile_page.dart';
import 'promotion/promotions_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int index = 0;

  static const _titles = ['Trang chủ', 'Hoạt động', 'Ưu đãi', 'Tài khoản'];
  static const _eyebrows = [
    'VỊ TRÍ HIỆN TẠI',
    'VỊ TRÍ ĐÓN',
    'DÀNH CHO BẠN',
    'TÀI KHOẢN',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(controller: widget.controller),
      OrderHistoryPage(controller: widget.controller),
      PromotionsPage(controller: widget.controller),
      ProfilePage(controller: widget.controller),
    ];

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                title: _titles[index],
                eyebrow: _eyebrows[index],
                unreadCount: widget.controller.unreadNotificationCount,
                onNotifications: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        NotificationsPage(controller: widget.controller),
                  ),
                ),
                onProfile: () => setState(() => index = 3),
              ),
              Expanded(
                child: IndexedStack(index: index, children: pages),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Hoạt động',
            ),
            NavigationDestination(
              icon: Icon(Icons.redeem_outlined),
              selectedIcon: Icon(Icons.redeem),
              label: 'Ưu đãi',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.eyebrow,
    required this.unreadCount,
    required this.onNotifications,
    required this.onProfile,
  });

  final String title;
  final String eyebrow;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .94),
        border: Border(bottom: BorderSide(color: colors.surfaceContainer)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              title == 'Trang chủ'
                  ? Icons.near_me_outlined
                  : Icons.location_on_outlined,
              color: colors.secondary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: .6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 18, color: colors.outline),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('customer-notifications-button'),
            tooltip: 'Thông báo',
            onPressed: onNotifications,
            icon: _NotificationBell(unreadCount: unreadCount),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onProfile,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: colors.primary,
              child: Icon(Icons.person, color: colors.onPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) return const Icon(Icons.notifications_none_outlined);

    final label = unreadCount > 99 ? '99+' : unreadCount.toString();
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(child: Icon(Icons.notifications_outlined)),
          Positioned(
            top: -2,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
