import 'package:flutter/material.dart';

import '../../client_app_controller.dart';
import '../../../api/booking_api.dart';

class PromotionsPage extends StatelessWidget {
  const PromotionsPage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => RefreshIndicator(
        onRefresh: controller.loadCommerce,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _memberCard(context),
            const SizedBox(height: 20),
            _heading(
              context,
              'Ưu đãi dành cho bạn',
              'Kho voucher (${controller.vouchers.length})',
            ),
            const SizedBox(height: 10),
            if (controller.vouchers.isEmpty)
              const Card(
                child: ListTile(title: Text('Chưa có voucher khả dụng')),
              )
            else
              for (final voucher in controller.vouchers) ...[
                _voucherCard(context, voucher),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 14),
            _heading(context, 'Đổi điểm lấy voucher', 'Dùng điểm thành viên'),
            const SizedBox(height: 10),
            if (controller.loyaltyRewards.isEmpty)
              const Card(
                child: ListTile(title: Text('Chưa có phần thưởng đổi điểm')),
              )
            else
              for (final reward in controller.loyaltyRewards) ...[
                _rewardCard(context, reward),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  Widget _memberCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final account = controller.loyaltyAccount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${account?.tier ?? 'BRONZE'} Member',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: colors.onPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ưu đãi riêng cho hành trình của bạn',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.primaryFixedDim),
                ),
              ],
            ),
          ),
          Text(
            '${account?.pointsBalance ?? 0}\nđiểm',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.secondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String title, String action) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(action, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _voucherCard(BuildContext context, VoucherSummary voucher) {
    final badge = voucher.discountType == 'PERCENT'
        ? '${voucher.discountValue.toStringAsFixed(0)}%'
        : '${voucher.discountValue.toStringAsFixed(0)}đ';
    return _OfferCard(
      badge: badge,
      caption:
          '${voucher.serviceScope ?? 'Mọi dịch vụ'} • HSD ${voucher.endsAt.day}/${voucher.endsAt.month}',
      title: voucher.name,
      subtitle: 'Mã ${voucher.code}',
      onPressed: () {
        controller.selectVoucher(voucher.code);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chọn mã ${voucher.code} cho đơn tiếp theo.'),
          ),
        );
      },
    );
  }

  Widget _rewardCard(BuildContext context, LoyaltyRewardSummary reward) {
    final enabled =
        (controller.loyaltyAccount?.pointsBalance ?? 0) >= reward.pointsCost;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.redeem,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(reward.name),
        subtitle: Text('${reward.pointsCost} điểm'),
        trailing: SizedBox(
          width: 64,
          child: FilledButton(
            onPressed: enabled
                ? () async {
                    final result = await controller.redeemLoyaltyReward(
                      reward.id,
                    );
                    if (context.mounted && result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã đổi ${result.voucher.code}.'),
                        ),
                      );
                    }
                  }
                : null,
            child: const Text('Đổi'),
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.badge,
    required this.caption,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String badge;
  final String caption;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.secondaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 42),
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
