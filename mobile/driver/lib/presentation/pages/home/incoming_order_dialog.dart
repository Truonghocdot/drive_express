import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/driver_api.dart';
import '../../driver_app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_shell.dart';
import '../../widgets/driver_feedback.dart';

class IncomingOrderDialog extends StatefulWidget {
  const IncomingOrderDialog({
    super.key,
    required this.controller,
    required this.offer,
  });

  final DriverAppController controller;
  final DriverOfferSummary offer;

  @override
  State<IncomingOrderDialog> createState() => _IncomingOrderDialogState();
}

class _IncomingOrderDialogState extends State<IncomingOrderDialog> {
  late int seconds = widget.offer.expiresAt
      .difference(DateTime.now())
      .inSeconds
      .clamp(0, 3600);
  Timer? timer;
  bool responding = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        seconds = widget.offer.expiresAt
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, 3600);
      });
      if (seconds == 3) HapticFeedback.selectionClick();
      if (seconds == 0) timer?.cancel();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đề nghị mới',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Semantics(
                  label: 'Còn $seconds giây để phản hồi',
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.driverTokens.warning.withValues(
                        alpha: 0.16,
                      ),
                      border: Border.all(
                        color: context.driverTokens.warning,
                        width: 3,
                      ),
                    ),
                    child: Text(
                      '$seconds s',
                      style: TextStyle(
                        color: context.driverTokens.warning,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                DriverMetricTile(
                  icon: offer.serviceType == 'DELIVERY'
                      ? Icons.local_shipping_outlined
                      : Icons.local_taxi_outlined,
                  label: 'Dịch vụ',
                  value: formatDriverValue(offer.serviceType),
                  color: context.driverTokens.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DriverMetricTile(
                    icon: Icons.payments_outlined,
                    label: 'Thu nhập dự kiến',
                    value: '${offer.estimatedEarning.toStringAsFixed(0)} đ',
                    color: context.driverTokens.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RoutePoint(
              icon: Icons.radio_button_checked,
              color: context.driverTokens.primary,
              title: 'Điểm đón',
              value:
                  '${(offer.pickupDistanceMeters / 1000).toStringAsFixed(1)} km từ bạn',
            ),
            const SizedBox(height: 10),
            _RoutePoint(
              icon: Icons.location_on,
              color: context.driverTokens.warning,
              title: 'Điểm trả',
              value: 'Tuyến đường sẽ hiển thị sau khi nhận chuyến',
            ),
            const SizedBox(height: 10),
            Text(
              'Khách thanh toán ${formatDriverValue(offer.paymentMethod)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (offer.passengerName case final name?) ...[
              const SizedBox(height: 6),
              Text(
                'Người đi: $name',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (offer.passengerPhone case final phone?)
                Text('Liên hệ: $phone'),
            ],
            if (widget.controller.error case final error?) ...[
              const SizedBox(height: 12),
              DriverErrorBanner(message: error),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: responding || seconds == 0
                        ? null
                        : () => _respond(context, 'decline'),
                    child: const Text('Bỏ qua'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: Key('accept-${offer.id}'),
                    onPressed: responding || seconds == 0
                        ? null
                        : () => _respond(context, 'accept'),
                    icon: responding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      responding ? 'Đang xử lý' : 'Nhận chuyến ($seconds s)',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, String action) async {
    setState(() => responding = true);
    await widget.controller.respond(widget.offer, action);
    if (context.mounted) Navigator.pop(context);
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
