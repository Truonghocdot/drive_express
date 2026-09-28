import 'package:flutter/material.dart';

import '../../../api/driver_api.dart';
import '../../driver_app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_feedback.dart';
import '../../widgets/driver_shell.dart';

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key, required this.controller});

  final DriverAppController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final online = profile?.availabilityStatus == 'ONLINE';
    final performance = profile?.performance;
    final vehicle = profile?.vehicles.isNotEmpty == true
        ? profile!.vehicles.first
        : null;
    return RefreshIndicator(
      onRefresh: controller.refreshApplication,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _hero(context, profile, vehicle),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          online ? 'Đang trực tuyến' : 'Đang ngoại tuyến',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          online
                              ? 'Sẵn sàng nhận chuyến gần nhất'
                              : 'Bật online khi bạn sẵn sàng',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: online,
                    onChanged: controller.busy ? null : controller.setOnline,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          DriverSectionTitle('Hiệu suất'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              DriverMetricTile(
                icon: Icons.star_outline,
                label: 'Đánh giá',
                value: performance?.rating?.toStringAsFixed(2) ?? '—',
                color: context.driverTokens.warning,
              ),
              DriverMetricTile(
                icon: Icons.check_circle_outline,
                label: 'Nhận chuyến',
                value: _percent(performance?.acceptanceRate),
                color: context.driverTokens.secondary,
              ),
              DriverMetricTile(
                icon: Icons.task_alt,
                label: 'Hoàn thành',
                value: _percent(performance?.completionRate),
                color: context.driverTokens.primary,
              ),
              DriverMetricTile(
                icon: Icons.route_outlined,
                label: 'Chuyến đã xong',
                value: '${performance?.completedCount ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          DriverSectionTitle('Dịch vụ được duyệt'),
          const SizedBox(height: 10),
          if (profile?.capabilities.isEmpty ?? true)
            const DriverEmptyState(
              icon: Icons.assignment_late_outlined,
              title: 'Chưa có dịch vụ',
              message: 'Hoàn tất hồ sơ để bật dịch vụ.',
            ),
          if (profile != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.capabilities
                  .map(
                    (service) => Chip(
                      avatar: const Icon(Icons.check, size: 16),
                      label: Text(formatDriverValue(service)),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 18),
          DriverSectionTitle('Cài đặt & hỗ trợ'),
          const SizedBox(height: 8),
          _item(
            context,
            Icons.map_outlined,
            'Bản đồ dẫn đường',
            'Goong Maps và quyền vị trí',
            () {},
          ),
          _item(
            context,
            Icons.notifications_active_outlined,
            'Thông báo vận hành',
            'Đơn mới, ví và hỗ trợ',
            () => _notifications(context),
          ),
          _item(
            context,
            Icons.support_agent_outlined,
            'Trung tâm hỗ trợ',
            'Yêu cầu hỗ trợ và chat',
            () => _tickets(context),
          ),
          _item(
            context,
            Icons.emergency_outlined,
            'Trung tâm an toàn',
            'SOS và báo cáo sự cố',
            () => _safety(context),
            danger: true,
          ),
          if (controller.error case final error?)
            DriverErrorBanner(message: error),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất tài khoản'),
          ),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    DriverProfileSummary? profile,
    Map<String, dynamic>? vehicle,
  ) {
    final name = profile?.userName ?? 'Tài xế';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.driverTokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.driverTokens.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: context.driverTokens.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.person, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: context.driverTokens.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(formatDriverValue(profile?.reviewStatus ?? 'PENDING')),
                  ],
                ),
                if (vehicle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${vehicle['plate_number'] ?? 'Chưa có biển số'} · ${vehicle['status'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? context.driverTokens.danger : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        minTileHeight: 64,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _percent(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}%';

  Future<void> _notifications(BuildContext context) async {
    await controller.loadNotifications();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Thông báo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (controller.notifications.isEmpty)
              const DriverEmptyState(
                icon: Icons.notifications_none,
                title: 'Chưa có thông báo',
                message: 'Cập nhật mới sẽ xuất hiện tại đây.',
              ),
            for (final item in controller.notifications)
              ListTile(
                leading: Icon(
                  item.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active_outlined,
                ),
                title: Text(formatDriverValue(item.type)),
                trailing: item.isRead
                    ? null
                    : IconButton(
                        tooltip: 'Đánh dấu đã đọc',
                        icon: const Icon(Icons.done),
                        onPressed: () => controller.readNotification(item.id),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _tickets(BuildContext context) async {
    await controller.loadTickets();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Yêu cầu hỗ trợ',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (controller.tickets.isEmpty)
              const DriverEmptyState(
                icon: Icons.support_agent_outlined,
                title: 'Chưa có yêu cầu',
                message: 'Tạo yêu cầu từ chuyến đang thực hiện.',
              ),
            for (final ticket in controller.tickets)
              ListTile(
                title: Text(ticket.subject),
                subtitle: Text(formatDriverValue(ticket.status)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _ticketDetail(context, ticket),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _ticketDetail(
    BuildContext context,
    DriverTicketSummary ticket,
  ) async {
    final reply = TextEditingController();
    final support = controller.support;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket.subject),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final message in ticket.messages)
                      ListTile(
                        title: Text(message.senderName),
                        subtitle: Text(message.body),
                      ),
                  ],
                ),
              ),
              if (ticket.status != 'CLOSED')
                TextField(
                  controller: reply,
                  decoration: const InputDecoration(labelText: 'Phản hồi'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          if (ticket.status != 'CLOSED')
            FilledButton(
              onPressed: support == null
                  ? null
                  : () async {
                      if (reply.text.trim().isEmpty) return;
                      await support.replyToTicket(
                        session: controller.session,
                        id: ticket.id,
                        body: reply.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Gửi'),
            ),
        ],
      ),
    );
    reply.dispose();
  }

  Future<void> _safety(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Trung tâm an toàn',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'Gọi hỗ trợ hoặc báo cáo sự cố trong chuyến đang chạy.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone_in_talk_outlined),
                label: const Text('Gọi hỗ trợ'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Báo cáo sự cố'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
