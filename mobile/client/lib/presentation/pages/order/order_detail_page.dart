import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/booking_api.dart';
import '../../client_app_controller.dart';
import '../../widgets/app_feedback.dart';
import '../chat/chat_with_driver_page.dart';
import '../profile/rating_review_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.controller,
    required this.request,
  });

  final ClientAppController controller;
  final ServiceRequestSummary request;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  TrackingSummary? tracking;
  String? error;
  bool loadingDriver = true;
  late bool ratingSubmitted = widget.request.customerRatingSubmitted == true;

  ClientAppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTracking());
  }

  @override
  Widget build(BuildContext context) {
    final current = controller.activeRequest?.id == widget.request.id
        ? controller.activeRequest!
        : widget.request;
    final canContact = current.status != 'CANCELLED';
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết dịch vụ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(switch (current.service) {
                  ServiceKind.delivery => 'Đơn giao hàng',
                  ServiceKind.hourly => 'Thuê giờ',
                  ServiceKind.drive => 'Chuyến xe',
                }, style: Theme.of(context).textTheme.titleLarge),
              ),
              StatusBadge(current.status),
            ],
          ),
          const SizedBox(height: 16),
          if (loadingDriver)
            const LinearProgressIndicator(minHeight: 2)
          else if (tracking?.driverName != null) ...[
            _DriverCard(tracking: tracking!),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row('Mã yêu cầu', current.id),
                  _row('Điểm đón', current.pickupAddress ?? 'Không có dữ liệu'),
                  _row(
                    'Điểm đến',
                    current.dropoffAddress ?? 'Không có dữ liệu',
                  ),
                  _row(
                    'Thanh toán',
                    formatClientValue(current.paymentMethod.apiValue),
                  ),
                  _row(
                    'Tổng tiền',
                    '${current.customerPayable.toStringAsFixed(0)} VND',
                  ),
                  if (current.driverNetEarning != null)
                    _row(
                      'Đã quyết toán',
                      '${current.driverNetEarning!.toStringAsFixed(0)} VND',
                    ),
                ],
              ),
            ),
          ),
          if (error case final message?) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: message),
          ],
          if (canContact) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatWithDriverPage(
                        controller: controller,
                        request: current,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Nhắn tin'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _support(context, current),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: const Text('Hỗ trợ'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _report(context, current),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Báo cáo'),
                ),
              ],
            ),
          ],
          if (current.status == 'COMPLETED' && !ratingSubmitted) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _rate(current),
              icon: const Icon(Icons.star_outline),
              label: const Text('Đánh giá tài xế'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadTracking() async {
    final gateway = controller.gateway is BookingTrackingGateway
        ? controller.gateway as BookingTrackingGateway
        : null;
    if (gateway == null) {
      if (mounted) setState(() => loadingDriver = false);
      return;
    }
    try {
      final loaded = controller.tracking?.requestId == widget.request.id
          ? controller.tracking!
          : await gateway.loadTracking(controller.session, widget.request.id);
      if (mounted) setState(() => tracking = loaded);
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loadingDriver = false);
    }
  }

  Future<void> _rate(ServiceRequestSummary request) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RatingReviewPage(controller: controller, request: request),
      ),
    );
    if (submitted == true && mounted) setState(() => ratingSubmitted = true);
  }

  Future<void> _support(
    BuildContext context,
    ServiceRequestSummary request,
  ) async {
    final subject = TextEditingController(text: 'Hỗ trợ chuyến ${request.id}');
    final body = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu hỗ trợ'),
        content: TextField(
          controller: body,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Mô tả vấn đề'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (send == true && body.text.trim().isNotEmpty) {
      try {
        await controller.supportGateway?.createSupportTicket(
          session: controller.session,
          serviceRequestId: request.id,
          subject: subject.text,
          description: body.text.trim(),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu hỗ trợ.')));
      } catch (exception) {
        if (mounted) setState(() => error = exception.toString());
      }
    }
    subject.dispose();
    body.dispose();
  }

  Future<void> _report(
    BuildContext context,
    ServiceRequestSummary request,
  ) async {
    final description = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo sự cố'),
        content: TextField(
          controller: description,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Nội dung báo cáo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi báo cáo'),
          ),
        ],
      ),
    );
    if (send == true && description.text.trim().isNotEmpty) {
      try {
        await controller.supportGateway?.reportIncident(
          session: controller.session,
          serviceRequestId: request.id,
          incidentType: 'OTHER',
          description: description.text.trim(),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã gửi báo cáo sự cố.')));
      } catch (exception) {
        if (mounted) setState(() => error = exception.toString());
      }
    }
    description.dispose();
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.tracking});

  final TrackingSummary tracking;

  @override
  Widget build(BuildContext context) {
    final name = tracking.driverName ?? 'Tài xế';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final details = [
      tracking.vehicleType,
      tracking.vehiclePlate,
      tracking.driverPhone,
    ].whereType<String>().join(' · ');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          child: Text(initials.isEmpty ? '?' : initials),
        ),
        title: Text(name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          details.isEmpty ? 'Thông tin tài xế đang cập nhật' : details,
        ),
      ),
    );
  }
}
