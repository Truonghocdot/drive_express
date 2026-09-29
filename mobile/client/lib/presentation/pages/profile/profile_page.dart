import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

import '../../client_app_controller.dart';
import '../../widgets/app_feedback.dart';
import 'saved_addresses_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  Widget build(BuildContext context) {
    final account = controller.customerProfile;
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.surfaceContainerLow,
                  child: Icon(
                    Icons.person_outline,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account?.name ?? 'Tài khoản khách hàng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account?.phone ?? 'Số điện thoại chưa cập nhật',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (account?.email?.isNotEmpty ?? false)
                        Text(
                          account!.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: _item(
            context,
            Icons.logout,
            'Đăng xuất',
            'Thu hồi phiên trên thiết bị này',
            controller.logout,
            danger: true,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: colors.primaryContainer,
          child: InkWell(
            onTap: () => _wallet(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số dư ví lạnh',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryContainer.withValues(
                            alpha: .82,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        color: colors.onPrimaryContainer.withValues(alpha: .88),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.wallet == null
                        ? '—'
                        : '${controller.wallet!.available.toStringAsFixed(0)} đ',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _walletAction(
                          context,
                          Icons.add_circle_outline,
                          'Nạp tiền',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _walletAction(
                          context,
                          Icons.qr_code_2,
                          'Quét mã',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'CÀI ĐẶT & TIỆN ÍCH',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Card(
          child: Column(
            children: [
              _item(
                context,
                Icons.account_balance_wallet_outlined,
                'Ví lạnh',
                'Xem số dư và tạo mã nạp tiền',
                () => _wallet(context),
              ),
              const Divider(height: 1, indent: 68),
              _item(
                context,
                Icons.notifications_outlined,
                'Thông báo',
                'Cập nhật chuyến và hỗ trợ',
                () => _notifications(context),
              ),
              const Divider(height: 1, indent: 68),
              _item(
                context,
                Icons.bookmark_border,
                'Địa chỉ đã lưu',
                'Lưu tối đa 10 điểm đón và điểm đến',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SavedAddressesPage(controller: controller),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 68),
              _item(
                context,
                Icons.support_agent_outlined,
                'Yêu cầu hỗ trợ',
                'Theo dõi và phản hồi ticket',
                () => _tickets(context),
              ),
            ],
          ),
        ),
        if (controller.error case final error?) ...[
          const SizedBox(height: 12),
          ErrorBanner(message: error),
        ],
      ],
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
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      minVerticalPadding: 5,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: danger ? colors.errorContainer : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: danger ? colors.error : colors.primary),
      ),
      title: Text(title, style: TextStyle(color: danger ? colors.error : null)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: colors.outline),
      onTap: onTap,
    );
  }

  Widget _walletAction(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.onPrimaryContainer.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: colors.onPrimaryContainer, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _wallet(BuildContext context) async {
    await controller.loadWallet();
    if (!context.mounted || controller.wallet == null) return;
    final amount = TextEditingController(text: '100000');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ví lạnh', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '${controller.wallet!.available.toStringAsFixed(0)} VND',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền nạp'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final value = double.tryParse(amount.text);
                if (value == null || value <= 0) return;
                final topup = await controller.createTopup(value);
                if (context.mounted && topup != null) {
                  Navigator.pop(context);
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Thông tin VietQR'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (topup.vietQrImageUrl case final imageUrl?)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                      ? child
                                      : const SizedBox(
                                          height: 240,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                  errorBuilder: (_, _, _) => const Text(
                                    'Không tải được ảnh QR. Bạn vẫn có thể dùng payload bên dưới.',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text('Nội dung: ${topup.reference}'),
                          ],
                        ),
                      ),
                      actions: [
                        if (topup.vietQrImageUrl case final imageUrl?)
                          TextButton.icon(
                            onPressed: () => _saveQrImage(
                              context,
                              imageUrl,
                              topup.reference,
                            ),
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Lưu ảnh QR'),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Tạo mã nạp tiền'),
            ),
          ],
        ),
      ),
    );
    await disposeTextControllerAfterRoute(amount);
  }

  Future<void> _saveQrImage(
    BuildContext context,
    String imageUrl,
    String reference,
  ) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('QR image request failed');
      }
      await Gal.putImageBytes(
        response.bodyBytes,
        name: 'vietqr_$reference',
        album: 'Drive',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu ảnh QR vào thư viện.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể lưu ảnh QR.')));
      }
    }
  }

  Future<void> _notifications(BuildContext context) async {
    await controller.loadNotifications();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Thông báo', style: Theme.of(context).textTheme.titleLarge),
          if (controller.notifications.isEmpty)
            const EmptyState(
              icon: Icons.notifications_none,
              title: 'Chưa có thông báo',
              message: 'Các cập nhật mới sẽ xuất hiện ở đây.',
            ),
          for (final notification in controller.notifications)
            ListTile(
              leading: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active_outlined,
              ),
              title: Text(
                notification.title ?? formatClientValue(notification.type),
              ),
              subtitle: notification.body == null
                  ? null
                  : Text(notification.body!),
              trailing: notification.isRead
                  ? null
                  : IconButton(
                      tooltip: 'Đánh dấu đã đọc',
                      icon: const Icon(Icons.done),
                      onPressed: () =>
                          controller.readNotification(notification.id),
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _tickets(BuildContext context) async {
    await controller.loadTickets();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Yêu cầu hỗ trợ', style: Theme.of(context).textTheme.titleLarge),
          if (controller.tickets.isEmpty)
            const EmptyState(
              icon: Icons.support_agent_outlined,
              title: 'Chưa có yêu cầu',
              message: 'Bạn có thể tạo yêu cầu từ chi tiết chuyến.',
            ),
          for (final ticket in controller.tickets)
            ListTile(
              title: Text(ticket.subject),
              subtitle: Text(formatClientValue(ticket.status)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _ticketDetail(context, ticket.id),
            ),
        ],
      ),
    );
  }

  Future<void> _ticketDetail(BuildContext context, String id) async {
    final support = controller.supportGateway;
    if (support == null) return;
    final ticket = await support.loadTicket(controller.session, id);
    if (!context.mounted) return;
    final reply = TextEditingController();
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
                constraints: const BoxConstraints(maxHeight: 260),
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
              onPressed: () async {
                if (reply.text.trim().isEmpty) return;
                await support.replyToTicket(
                  session: controller.session,
                  id: id,
                  body: reply.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Gửi'),
            ),
        ],
      ),
    );
    await disposeTextControllerAfterRoute(reply);
  }
}
