import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../api/goong_navigation_api.dart';
import '../theme/app_theme.dart';

class DriverGoongMap extends StatefulWidget {
  const DriverGoongMap({
    super.key,
    required this.mapKey,
    this.current,
    this.pickup,
    this.dropoff,
    this.route,
    this.height = 260,
    this.fullScreen = false,
    this.styleUrl,
    this.showLegend = true,
  });

  final String mapKey;
  final NavigationCoordinate? current;
  final NavigationCoordinate? pickup;
  final NavigationCoordinate? dropoff;
  final List<NavigationCoordinate>? route;
  final double height;
  final bool fullScreen;
  final String? styleUrl;
  final bool showLegend;

  @override
  State<DriverGoongMap> createState() => _DriverGoongMapState();
}

class _DriverGoongMapState extends State<DriverGoongMap> {
  MapLibreMapController? _controller;
  bool _styleReady = false;

  @override
  void didUpdateWidget(covariant DriverGoongMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleReady &&
        (oldWidget.current != widget.current ||
            oldWidget.pickup != widget.pickup ||
            oldWidget.dropoff != widget.dropoff ||
            oldWidget.route != widget.route)) {
      _drawMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _visiblePoints;
    if (widget.mapKey.trim().isEmpty) {
      return _MapMessage(
        height: widget.height,
        message: 'Chưa có GOONG_MAP_KEY để tải nền bản đồ.',
        current: widget.current,
      );
    }
    if (points.isEmpty) {
      return _MapMessage(
        height: widget.height,
        message: 'Đang chờ vị trí GPS của tài xế.',
        current: widget.current,
      );
    }
    final center = NavigationCoordinate(
      latitude:
          points.fold<double>(0, (sum, point) => sum + point.latitude) /
          points.length,
      longitude:
          points.fold<double>(0, (sum, point) => sum + point.longitude) /
          points.length,
    );
    final map = SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          MapLibreMap(
            styleString: widget.styleUrl?.isNotEmpty == true
                ? widget.styleUrl!
                : 'https://tiles.goong.io/assets/goong_map_highlight.json?api_key=${Uri.encodeComponent(widget.mapKey)}',
            initialCameraPosition: CameraPosition(
              target: LatLng(center.latitude, center.longitude),
              zoom: points.length == 1 ? 15 : 13,
            ),
            compassEnabled: false,
            logoEnabled: false,
            onMapCreated: (controller) => _controller = controller,
            onStyleLoadedCallback: () {
              _styleReady = true;
              _drawMap();
            },
          ),
          if (widget.showLegend)
            Positioned(
              top: 12,
              left: 12,
              child: IgnorePointer(
                child: _DriverMapLegend(
                  hasCurrent: widget.current != null,
                  hasPickup: widget.pickup != null,
                  hasDropoff: widget.dropoff != null,
                ),
              ),
            ),
        ],
      ),
    );
    return widget.fullScreen
        ? map
        : ClipRRect(borderRadius: BorderRadius.circular(8), child: map);
  }

  List<NavigationCoordinate> get _visiblePoints => [
    if (widget.current != null) widget.current!,
    if (widget.pickup != null) widget.pickup!,
    if (widget.dropoff != null) widget.dropoff!,
  ];

  Future<void> _drawMap() async {
    final controller = _controller;
    if (controller == null || !_styleReady || !mounted) return;
    await controller.clearLines();
    await controller.clearSymbols();
    await controller.clearCircles();
    final route = widget.route;
    if (route != null && route.length > 1) {
      await controller.addLine(
        LineOptions(
          geometry: route
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          lineColor: '#155EEF',
          lineWidth: 6,
          lineOpacity: 0.9,
        ),
      );
    }
    await _addMarker(controller, widget.current, color: '#155EEF', radius: 9);
    await _addMarker(controller, widget.pickup, color: '#047857', radius: 10);
    await _addMarker(controller, widget.dropoff, color: '#B42318', radius: 10);
    await _fitCamera(controller);
  }

  Future<void> _addMarker(
    MapLibreMapController controller,
    NavigationCoordinate? coordinate, {
    required String color,
    required double radius,
  }) async {
    if (coordinate == null) return;
    await controller.addCircle(
      CircleOptions(
        geometry: LatLng(coordinate.latitude, coordinate.longitude),
        circleRadius: radius,
        circleColor: color,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 3,
        circleOpacity: 1,
        circleStrokeOpacity: 1,
      ),
    );
  }

  Future<void> _fitCamera(MapLibreMapController controller) async {
    final route = widget.route;
    final points = <NavigationCoordinate>[
      if (route != null && route.isNotEmpty) route.first,
      if (route != null && route.length > 1) route.last,
      if (widget.current != null) widget.current!,
      if (route == null || route.isEmpty) ..._visiblePoints,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(points.first.latitude, points.first.longitude),
          15,
        ),
      );
      return;
    }
    final minLatitude = points
        .map((point) => point.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLatitude = points
        .map((point) => point.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLongitude = points
        .map((point) => point.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLongitude = points
        .map((point) => point.longitude)
        .reduce((a, b) => a > b ? a : b);
    if ((maxLatitude - minLatitude).abs() < 0.00001 &&
        (maxLongitude - minLongitude).abs() < 0.00001) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(points.first.latitude, points.first.longitude),
          15,
        ),
      );
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLatitude, minLongitude),
          northeast: LatLng(maxLatitude, maxLongitude),
        ),
        left: 42,
        top: 42,
        right: 42,
        bottom: widget.fullScreen ? 240 : 42,
      ),
    );
  }
}

class _DriverMapLegend extends StatelessWidget {
  const _DriverMapLegend({
    required this.hasCurrent,
    required this.hasPickup,
    required this.hasDropoff,
  });

  final bool hasCurrent;
  final bool hasPickup;
  final bool hasDropoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.driverTokens.surfaceLow.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.driverTokens.divider),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCurrent)
            const _DriverLegendItem(
              color: Color(0xFF155EEF),
              label: 'Vị trí tài xế',
            ),
          if (hasPickup) ...[
            if (hasCurrent) const SizedBox(height: 4),
            const _DriverLegendItem(
              color: Color(0xFF047857),
              label: 'Điểm đón',
            ),
          ],
          if (hasDropoff) ...[
            if (hasCurrent || hasPickup) const SizedBox(height: 4),
            const _DriverLegendItem(
              color: Color(0xFFB42318),
              label: 'Điểm đến',
            ),
          ],
        ],
      ),
    );
  }
}

class _DriverLegendItem extends StatelessWidget {
  const _DriverLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({
    required this.height,
    required this.message,
    this.current,
  });

  final double height;
  final String message;
  final NavigationCoordinate? current;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.driverTokens.surfaceLow,
        border: Border.all(color: context.driverTokens.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                color: context.driverTokens.secondary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          if (current != null) ...[
            const SizedBox(height: 16),
            Text(
              'VỊ TRÍ TÀI XẾ',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${current!.latitude.toStringAsFixed(6)}, ${current!.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ],
      ),
    );
  }
}
