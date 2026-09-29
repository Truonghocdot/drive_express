import 'package:flutter/material.dart';

import '../../../api/booking_api.dart';
import '../../../api/session_store.dart';
import '../../client_app_controller.dart';
import '../../widgets/app_feedback.dart';
import '../order/active_order_tracking_page.dart';
import '../order/create_order_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  Widget build(BuildContext context) {
    final recent = controller.history.take(2).toList(growable: false);
    final active = controller.hasActiveRequest
        ? controller.activeRequest
        : null;
    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadHistory();
        await controller.refreshActiveRequest();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          if (active case final request?) ...[
            _ActiveRequestCard(
              request: request,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ActiveOrderTrackingPage(controller: controller),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _DestinationCard(
            onTap: () => _openOrder(context, ServiceKind.drive),
            favorites: controller.favoriteAddresses,
            onFavoriteTap: (favorite) =>
                _openOrder(context, ServiceKind.drive, initialPickup: favorite),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Dịch vụ cốt lõi',
            action: 'Xem tất cả (4)',
            onAction: () => _comingSoon(context),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 136,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ServiceTile(
                icon: Icons.two_wheeler_outlined,
                title: 'Đặt xe',
                subtitle: 'Xe máy & ô tô',
                onTap: () => _openOrder(context, ServiceKind.drive),
              ),
              _ServiceTile(
                icon: Icons.local_shipping_outlined,
                title: 'Giao hàng',
                subtitle: 'Nội thành nhanh chóng',
                onTap: () => _openOrder(context, ServiceKind.delivery),
              ),
              _ServiceTile(
                icon: Icons.person_pin_circle_outlined,
                title: 'Đặt hộ',
                subtitle: 'Theo dõi lộ trình',
                onTap: () => _openOrder(
                  context,
                  ServiceKind.drive,
                  isProxyBooking: true,
                ),
              ),
              _ServiceTile(
                icon: Icons.schedule_outlined,
                title: 'Thuê giờ',
                subtitle: 'Kèm tài xế',
                onTap: () => _openOrder(context, ServiceKind.hourly),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PromoStrip(onTap: () => _comingSoon(context)),
          const SizedBox(height: 22),
          _SectionHeader(title: 'Điểm đến gần đây', action: 'Xóa lịch sử'),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Các điểm đến thường dùng sẽ xuất hiện ở đây.'),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    _RecentDestination(request: recent[i]),
                    if (i < recent.length - 1)
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                  ],
                ],
              ),
            ),
          if (controller.error case final error?) ...[
            const SizedBox(height: 16),
            ErrorBanner(message: error),
          ],
        ],
      ),
    );
  }

  void _openOrder(
    BuildContext context,
    ServiceKind service, {
    bool isProxyBooking = false,
    FavoriteAddress? initialPickup,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderPage(
          controller: controller,
          service: service,
          isProxyBooking: isProxyBooking,
          initialPickup: initialPickup,
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang được phát triển.')),
    );
  }
}

class _ActiveRequestCard extends StatelessWidget {
  const _ActiveRequestCard({required this.request, required this.onTap});

  final ServiceRequestSummary request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primary,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.navigation_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dịch vụ đang theo dõi',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: colors.onPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatClientValue(request.status),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.primaryFixedDim),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.onTap,
    required this.favorites,
    required this.onFavoriteTap,
  });

  final VoidCallback onTap;
  final List<FavoriteAddress> favorites;
  final ValueChanged<FavoriteAddress> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: colors.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn muốn đi đâu hôm nay?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: favorites.isEmpty
                    ? [
                        _PlaceChip(
                          icon: Icons.apartment_outlined,
                          label: 'Văn phòng',
                        ),
                        const SizedBox(width: 8),
                        _PlaceChip(
                          icon: Icons.home_outlined,
                          label: 'Nhà riêng',
                        ),
                      ]
                    : [
                        for (final favorite in favorites.take(3)) ...[
                          _PlaceChip(
                            icon: Icons.bookmark_border,
                            label: favorite.label,
                            onTap: () => onFavoriteTap(favorite),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 5),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (action != null)
          Flexible(
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.percent, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Giảm 30K cho chuyến đầu tiên',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(84, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Dùng ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDestination extends StatelessWidget {
  const _RecentDestination({required this.request});

  final ServiceRequestSummary request;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        child: const Icon(Icons.history, size: 19),
      ),
      title: Text(
        request.dropoffAddress ?? formatClientValue(request.service.apiValue),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        request.pickupAddress ?? 'Điểm đón gần đây',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.north_east, size: 19),
    );
  }
}
