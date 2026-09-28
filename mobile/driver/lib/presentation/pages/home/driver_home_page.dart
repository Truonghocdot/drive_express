import 'package:flutter/material.dart';

import '../../../api/device_location.dart';
import '../../../api/driver_api.dart';
import '../../../api/goong_navigation_api.dart';
import '../../driver_app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_feedback.dart';
import '../../widgets/driver_goong_map.dart';
import '../../widgets/driver_shell.dart';
import '../active_job/job_navigation_page.dart';
import 'incoming_order_dialog.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key, required this.controller});

  final DriverAppController controller;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final shownOffers = <String>{};

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final active = controller.activeOffer;
    final pending = controller.offers
        .where((offer) => offer.status == 'PENDING')
        .toList();
    final online = controller.profile?.availabilityStatus == 'ONLINE';
    final unseen = pending
        .where((offer) => !shownOffers.contains(offer.id))
        .firstOrNull;

    if (unseen != null) {
      shownOffers.add(unseen.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showOfferSheet(unseen);
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        DriverGoongMap(
          height: double.infinity,
          fullScreen: true,
          mapKey: const String.fromEnvironment('GOONG_MAP_KEY'),
          styleUrl: const String.fromEnvironment('GOONG_MAP_STYLE_URL'),
          current: _coordinate(controller.currentPosition),
          pickup: active == null
              ? null
              : NavigationCoordinate(
                  latitude: active.pickupLatitude,
                  longitude: active.pickupLongitude,
                ),
          dropoff: active == null
              ? null
              : NavigationCoordinate(
                  latitude: active.dropoffLatitude,
                  longitude: active.dropoffLongitude,
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.driverTokens.canvas.withValues(alpha: 0.78),
                    Colors.transparent,
                    context.driverTokens.canvas.withValues(alpha: 0.62),
                  ],
                  stops: const [0, 0.32, 1],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    DriverStatusPill(
                      label: online ? 'TRỰC TUYẾN' : 'NGOẠI TUYẾN',
                      online: online,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'SOS khẩn cấp',
                      onPressed: () => _showSos(context),
                      icon: const Icon(Icons.emergency_outlined),
                      color: context.driverTokens.danger,
                      style: IconButton.styleFrom(
                        backgroundColor: context.driverTokens.surfaceLow
                            .withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: context.driverTokens.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: const Icon(Icons.person_outline),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: [
                      _MapAction(
                        icon: Icons.layers_outlined,
                        label: 'Lớp bản đồ',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 10),
                      _MapAction(
                        icon: Icons.my_location,
                        label: 'Định vị lại',
                        onPressed: controller.refreshPosition,
                      ),
                      const SizedBox(height: 10),
                      _MapAction(
                        icon: Icons.radar,
                        label: 'Radar tìm khách',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildBottomPanel(context, controller, online, active, pending),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    DriverAppController controller,
    bool online,
    DriverOfferSummary? active,
    List<DriverOfferSummary> pending,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: context.driverTokens.surfaceLow.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.driverTokens.divider),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.driverTokens.muted,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? 'Đang nhận chuyến' : 'Đang ngoại tuyến',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      online
                          ? '${pending.length} đề nghị gần bạn'
                          : 'Bật trực tuyến khi bạn sẵn sàng.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: online,
                onChanged: controller.busy || active != null
                    ? null
                    : controller.setOnline,
              ),
            ],
          ),
          if (controller.error case final error?) ...[
            const SizedBox(height: 10),
            DriverErrorBanner(message: error),
          ],
          if (controller.locationError case final locationError?
              when locationError != controller.error) ...[
            const SizedBox(height: 10),
            DriverErrorBanner(message: locationError),
            TextButton.icon(
              onPressed: controller.prepareLocation,
              icon: const Icon(Icons.my_location_outlined),
              label: const Text('Thử lại vị trí'),
            ),
          ],
          if (active != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobNavigationPage(controller: controller),
                ),
              ),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Tiếp tục chuyến đang chạy'),
            ),
          ] else if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Đề nghị mới', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showOfferSheet(pending.first),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.driverTokens.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.driverTokens.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      pending.first.serviceType == 'DELIVERY'
                          ? Icons.local_shipping_outlined
                          : Icons.local_taxi_outlined,
                      color: context.driverTokens.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${formatDriverValue(pending.first.serviceType)} · ${(pending.first.pickupDistanceMeters / 1000).toStringAsFixed(1)} km',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pending.first.estimatedEarning.toStringAsFixed(0)} đ',
                      style: TextStyle(
                        color: context.driverTokens.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Giữ trực tuyến để nhận cuốc gần vị trí của bạn.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showOfferSheet(DriverOfferSummary offer) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          IncomingOrderDialog(controller: widget.controller, offer: offer),
    );
  }

  Future<void> _showSos(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Trung tâm an toàn',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gọi hỗ trợ khẩn cấp hoặc báo cáo sự cố trong chuyến đang chạy.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.phone_in_talk_outlined),
                label: const Text('Gọi hỗ trợ'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Báo cáo sự cố'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationCoordinate? _coordinate(DriverPosition? position) {
    if (position == null) return null;
    return NavigationCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: context.driverTokens.surfaceLow.withValues(
            alpha: 0.92,
          ),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
