import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/driver_api.dart';
import '../../driver_app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_feedback.dart';
import '../../widgets/driver_shell.dart';
import 'withdraw_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.controller});

  final DriverAppController controller;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.loadWallet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    final wallet = state.wallet;
    return RefreshIndicator(
      onRefresh: state.loadWallet,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _balanceCard(context, wallet, state),
          if (wallet case final current? when current.balance < 0) ...[
            const SizedBox(height: 12),
            DriverErrorBanner(
              message:
                  'Ví đang âm ${current.balance.abs().toStringAsFixed(0)} VND. Nạp tiền để nhận chuyến.',
            ),
          ],
          if (state.error case final error?) ...[
            const SizedBox(height: 10),
            DriverErrorBanner(message: error),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addAccount,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm ngân hàng'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.busy ? null : () => _topUp(context),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Nạp ví'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: state.busy || wallet == null || wallet.balance < 0
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WithdrawPage(controller: state),
                    ),
                  ),
            icon: const Icon(Icons.arrow_upward),
            label: const Text('Rút tiền'),
          ),
          const SizedBox(height: 24),
          DriverSectionTitle('Tài khoản ngân hàng'),
          const SizedBox(height: 8),
          if (state.bankAccounts.isEmpty)
            const DriverEmptyState(
              icon: Icons.account_balance_outlined,
              title: 'Chưa có tài khoản',
              message:
                  'Thêm tài khoản và chờ admin xác minh trước khi rút tiền.',
            ),
          for (final account in state.bankAccounts)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(account.bankCode),
                subtitle: Text(account.accountName),
                trailing: DriverStatusBadge(
                  account.verified ? 'VERIFIED' : 'PENDING',
                ),
              ),
            ),
          const SizedBox(height: 16),
          DriverSectionTitle('Biến động gần đây'),
          const SizedBox(height: 8),
          if (wallet?.entries.isEmpty ?? true)
            const DriverEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có giao dịch',
              message: 'Các khoản thu nhập và rút tiền sẽ xuất hiện tại đây.',
            ),
          for (final entry in wallet?.entries ?? const <DriverWalletEntry>[])
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  entry.direction == 'CREDIT'
                      ? Icons.south_west
                      : Icons.north_east,
                  color: entry.direction == 'CREDIT'
                      ? context.driverTokens.primary
                      : context.driverTokens.warning,
                ),
                title: Text(
                  formatDriverValue(entry.transactionType ?? entry.direction),
                ),
                subtitle: Text(entry.createdAt?.toLocal().toString() ?? ''),
                trailing: Text(
                  '${entry.direction == 'CREDIT' ? '+' : '-'}${entry.amount.toStringAsFixed(0)} đ',
                  style: TextStyle(
                    color: entry.direction == 'CREDIT'
                        ? context.driverTokens.primary
                        : context.driverTokens.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _balanceCard(
    BuildContext context,
    DriverWalletSummary? wallet,
    DriverAppController state,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.driverTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.driverTokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Số dư khả dụng',
                  style: TextStyle(color: context.driverTokens.muted),
                ),
              ),
              IconButton(
                tooltip: obscured ? 'Hiện số dư' : 'Ẩn số dư',
                onPressed: () => setState(() => obscured = !obscured),
                icon: Icon(
                  obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            wallet == null && state.busy
                ? 'Đang tải…'
                : obscured
                ? '••••••'
                : '${wallet?.balance.toStringAsFixed(0) ?? '—'} VND',
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            wallet == null && state.busy
                ? 'Đang đồng bộ số dư'
                : 'Khả dụng ${obscured ? '••••' : '${wallet?.available.toStringAsFixed(0) ?? '—'} VND'}',
            style: TextStyle(color: context.driverTokens.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _addAccount() async {
    final bank = TextEditingController();
    final number = TextEditingController();
    final name = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm tài khoản ngân hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bank,
              decoration: const InputDecoration(labelText: 'Mã ngân hàng'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: number,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tài khoản'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Tên chủ tài khoản'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (confirmed == true &&
        bank.text.trim().isNotEmpty &&
        number.text.trim().isNotEmpty &&
        name.text.trim().isNotEmpty) {
      await widget.controller.addBankAccount(
        bankCode: bank.text.trim(),
        accountNumber: number.text.trim(),
        accountName: name.text.trim(),
      );
    }
    bank.dispose();
    number.dispose();
    name.dispose();
  }

  Future<void> _topUp(BuildContext context) async {
    final amount = TextEditingController(text: '100000');
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nạp ví tài xế',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Tạo mã VietQR và chuyển khoản đúng số tiền.'),
            const SizedBox(height: 16),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền nạp (VND)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Tạo mã VietQR'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      amount.dispose();
      return;
    }
    final value = double.tryParse(amount.text.replaceAll(',', '').trim());
    amount.dispose();
    if (value == null || value < 10000 || !mounted) return;
    final topup = await widget.controller.createTopup(value);
    if (!mounted || topup == null) return;
    await _showTopupCode(topup);
  }

  Future<void> _showTopupCode(DriverWalletTopupSummary topup) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã nạp ví VietQR'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Số tiền: ${topup.amount.toStringAsFixed(0)} VND'),
              if (topup.vietQrImageUrl case final imageUrl?) ...[
                const SizedBox(height: 12),
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Text('Không tải được ảnh QR.'),
                ),
              ],
              const SizedBox(height: 8),
              Text('Nội dung chuyển khoản: ${topup.reference}'),
              const SizedBox(height: 12),
              SelectableText(topup.vietQrPayload),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: topup.vietQrPayload));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Sao chép'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
