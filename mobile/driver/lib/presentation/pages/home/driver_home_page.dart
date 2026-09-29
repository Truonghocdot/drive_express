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
  NavigationRoute? route;
  String? routeError;
  String? loadedRouteKey;
  bool routeLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.refreshPosition(),
    );
  }

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
    final routeKey = active == null
        ? null
        : '${active.id}:${active.serviceStatus}';
    if (active case final currentActive?
        when routeKey != loadedRouteKey && !routeLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.goong?.configured == true) {
          _loadRoute(currentActive);
        } else {
          _markRouteUnavailable(routeKey!);
        }
      });
    }

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
          route: active == null ? null : route?.geometry,
          showLegend: false,
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
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
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        child: const Icon(Icons.person_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _DriverLocationPill(
                      position: controller.currentPosition,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 188,
          right: 16,
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
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 86,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .42,
            ),
            child: SingleChildScrollView(
              child: _buildBottomPanel(
                context,
                controller,
                online,
                active,
                pending,
                routeLoading: routeLoading,
                routeError: routeError,
              ),
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
    List<DriverOfferSummary> pending, {
    required bool routeLoading,
    required String? routeError,
  }) {
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
          if (routeLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (routeError case final error?) ...[
            const SizedBox(height: 10),
            DriverErrorBanner(message: error),
            TextButton.icon(
              onPressed: () {
                final current = controller.activeOffer;
                if (current != null) _loadRoute(current, force: true);
              },
              icon: const Icon(Icons.alt_route_outlined),
              label: const Text('Thử lại chỉ đường'),
            ),
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

  Future<void> _loadRoute(
    DriverOfferSummary offer, {
    bool force = false,
  }) async {
    if (!mounted || routeLoading) return;
    final key = '${offer.id}:${offer.serviceStatus}';
    if (!force && loadedRouteKey == key) return;
    setState(() {
      routeLoading = true;
      routeError = null;
      route = null;
    });
    try {
      final nextRoute = await widget.controller.calculateRoute(offer);
      if (mounted &&
          '${widget.controller.activeOffer?.id}:${widget.controller.activeOffer?.serviceStatus}' ==
              key) {
        setState(() {
          route = nextRoute;
          loadedRouteKey = key;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          loadedRouteKey = key;
          routeError = exception.toString();
        });
      }
    } finally {
      if (mounted) setState(() => routeLoading = false);
    }
  }

  void _markRouteUnavailable(String key) {
    if (!mounted || loadedRouteKey == key) return;
    setState(() {
      loadedRouteKey = key;
      routeError = 'Chưa cấu hình GOONG_API_KEY để chỉ đường cho tài xế.';
    });
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

class _DriverLocationPill extends StatelessWidget {
  const _DriverLocationPill({required this.position});

  final DriverPosition? position;

  @override
  Widget build(BuildContext context) {
    final available = position != null;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 32,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: context.driverTokens.surfaceLow.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: available
              ? context.driverTokens.secondary.withValues(alpha: .7)
              : context.driverTokens.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.my_location : Icons.location_searching,
            size: 18,
            color: available
                ? context.driverTokens.secondary
                : context.driverTokens.muted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VỊ TRÍ HIỆN TẠI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  available
                      ? 'GPS chính xác khoảng ${position!.accuracy.toStringAsFixed(0)} m'
                      : 'Đang xác định GPS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
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
