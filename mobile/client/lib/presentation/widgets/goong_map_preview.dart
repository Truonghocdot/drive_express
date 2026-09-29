import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../api/goong_location_api.dart';

class GoongMapPreview extends StatefulWidget {
  const GoongMapPreview({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.mapKey,
    this.route,
    this.current,
  });

  final GoongCoordinate pickup;
  final GoongCoordinate dropoff;
  final String mapKey;
  final List<GoongCoordinate>? route;
  final GoongCoordinate? current;

  @override
  State<GoongMapPreview> createState() => _GoongMapPreviewState();
}

class _GoongMapPreviewState extends State<GoongMapPreview> {
  MapLibreMapController? _map;
  bool _styleReady = false;

  @override
  void didUpdateWidget(covariant GoongMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleReady &&
        (oldWidget.pickup != widget.pickup ||
            oldWidget.dropoff != widget.dropoff ||
            oldWidget.route != widget.route ||
            oldWidget.current != widget.current)) {
      _drawAnnotations();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapKey.trim().isEmpty) {
      return _MapUnavailableCard(
        message: 'Thêm GOONG_MAP_KEY để hiển thị bản đồ Goong.',
      );
    }
    final points = [
      widget.pickup,
      widget.dropoff,
      ...?(widget.current == null ? null : <GoongCoordinate>[widget.current!]),
    ];
    final center = GoongCoordinate(
      latitude:
          points.map((point) => point.latitude).reduce((a, b) => a + b) /
          points.length,
      longitude:
          points.map((point) => point.longitude).reduce((a, b) => a + b) /
          points.length,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            MapLibreMap(
              styleString:
                  'https://tiles.goong.io/assets/goong_map_highlight.json?api_key=${Uri.encodeComponent(widget.mapKey)}',
              initialCameraPosition: CameraPosition(
                target: LatLng(center.latitude, center.longitude),
                zoom: 13,
              ),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
              },
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              dragEnabled: true,
              compassEnabled: false,
              logoEnabled: false,
              onMapCreated: (controller) => _map = controller,
              onStyleLoadedCallback: () {
                _styleReady = true;
                _drawAnnotations();
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IgnorePointer(
                child: _MapLegend(hasDriver: widget.current != null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _drawAnnotations() async {
    final map = _map;
    if (map == null || !_styleReady || !mounted) return;
    await map.clearLines();
    await map.clearSymbols();
    final geometry = widget.route ?? [widget.pickup, widget.dropoff];
    if (geometry.length > 1) {
      await map.addLine(
        LineOptions(
          geometry: geometry
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          lineColor: '#006C49',
          lineWidth: 5,
          lineOpacity: 0.9,
        ),
      );
    }
    await map.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget.pickup.latitude, widget.pickup.longitude),
        textField: 'Điểm đón',
        textColor: '#047857',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 2,
        textSize: 16,
      ),
    );
    await map.addSymbol(
      SymbolOptions(
        geometry: LatLng(widget.dropoff.latitude, widget.dropoff.longitude),
        textField: 'Điểm đến',
        textColor: '#B42318',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 2,
        textSize: 16,
      ),
    );
    if (widget.current case final current?) {
      await map.addSymbol(
        SymbolOptions(
          geometry: LatLng(current.latitude, current.longitude),
          textField: 'Tài xế',
          textColor: '#155EEF',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 2,
          textSize: 14,
        ),
      );
    }
    await _fitCamera(map, geometry);
  }

  Future<void> _fitCamera(
    MapLibreMapController map,
    List<GoongCoordinate> route,
  ) async {
    final points = <GoongCoordinate>[
      if (route.isNotEmpty) route.first,
      if (route.length > 1) route.last,
      if (widget.current != null) widget.current!,
    ];
    if (points.length < 2) return;
    final minLatitude = points
        .map((point) => point.latitude)
        .reduce((left, right) => left < right ? left : right);
    final maxLatitude = points
        .map((point) => point.latitude)
        .reduce((left, right) => left > right ? left : right);
    final minLongitude = points
        .map((point) => point.longitude)
        .reduce((left, right) => left < right ? left : right);
    final maxLongitude = points
        .map((point) => point.longitude)
        .reduce((left, right) => left > right ? left : right);
    if ((maxLatitude - minLatitude).abs() < .00001 &&
        (maxLongitude - minLongitude).abs() < .00001) {
      return;
    }
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLatitude, minLongitude),
          northeast: LatLng(maxLatitude, maxLongitude),
        ),
        left: 36,
        top: 70,
        right: 36,
        bottom: 36,
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.hasDriver});

  final bool hasDriver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest
            .withValues(alpha: .96),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0B1C30),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LegendItem(color: Color(0xFF047857), label: 'Điểm đón'),
          const SizedBox(height: 4),
          const _LegendItem(color: Color(0xFFB42318), label: 'Điểm đến'),
          if (hasDriver) ...[
            const SizedBox(height: 4),
            const _LegendItem(color: Color(0xFF155EEF), label: 'Vị trí tài xế'),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

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

class _MapUnavailableCard extends StatelessWidget {
  const _MapUnavailableCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EFEA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8D7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: Color(0xFF146B52), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
