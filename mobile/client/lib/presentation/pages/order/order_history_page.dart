import 'package:flutter/material.dart';

import '../../../api/booking_api.dart';
import '../../client_app_controller.dart';
import '../../widgets/app_feedback.dart';
import 'active_order_tracking_page.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: tabs,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Đang diễn ra${_activeCountLabel()}'),
                const Tab(text: 'Lịch sử'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _activeList(),
              _list(
                widget.controller.history
                    .where(
                      (request) => widget.controller.isTerminal(request.status),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _activeCountLabel() {
    final count = widget.controller.history
        .where((request) => !widget.controller.isTerminal(request.status))
        .length;
    return count == 0 ? '' : '  $count';
  }

  Widget _activeList() {
    final requests = widget.controller.history
        .where((request) => !widget.controller.isTerminal(request.status))
        .toList();
    final active = widget.controller.activeRequest;
    if (active != null &&
        !widget.controller.isTerminal(active.status) &&
        !requests.any((request) => request.id == active.id)) {
      requests.insert(0, active);
    }
    return _list(requests, active: true);
  }

  Widget _list(List<ServiceRequestSummary> requests, {bool active = false}) {
    return RefreshIndicator(
      onRefresh: widget.controller.loadHistory,
      child: requests.isEmpty
          ? ListView(
              children: [
                EmptyState(
                  icon: active
                      ? Icons.route_outlined
                      : Icons.receipt_long_outlined,
                  title: active
                      ? 'Chưa có chuyến đang chạy'
                      : 'Chưa có lịch sử',
                  message: active
                      ? 'Các đơn đang thực hiện sẽ xuất hiện tại đây.'
                      : 'Các đơn và chuyến xe đã hoàn thành sẽ xuất hiện tại đây.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => active
                  ? _activeTile(requests[index])
                  : _historyTile(requests[index]),
            ),
    );
  }

  Widget _activeTile(ServiceRequestSummary request) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => _openRequest(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      request.service == ServiceKind.delivery
                          ? 'Giao hàng hoả tốc'
                          : 'Chuyến xe',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatClientValue(request.status),
                    style: TextStyle(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                pickup: request.pickupAddress ?? 'Đang xác nhận điểm lấy',
                dropoff: request.dropoffAddress ?? 'Đang xác nhận điểm đến',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: colors.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${request.customerPayable.toStringAsFixed(0)} VND',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyTile(ServiceRequestSummary request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                request.service == ServiceKind.delivery
                    ? Icons.inventory_2_outlined
                    : Icons.directions_car_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _openRequest(request),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.pickupAddress ?? request.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusBadge(request.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.dropoffAddress ??
                          formatClientValue(request.service.apiValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${request.customerPayable.toStringAsFixed(0)} VND',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRequest(ServiceRequestSummary request) async {
    await widget.controller.selectHistoryRequest(request);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.controller.isTerminal(request.status)
            ? OrderDetailPage(controller: widget.controller, request: request)
            : ActiveOrderTrackingPage(controller: widget.controller),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.pickup, required this.dropoff});

  final String pickup;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Icon(Icons.circle, size: 11, color: colors.secondary),
              Container(width: 2, height: 28, color: colors.outlineVariant),
              Icon(Icons.circle, size: 11, color: colors.primary),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lấy hàng', style: Theme.of(context).textTheme.bodySmall),
              Text(pickup, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Text('Giao đến', style: Theme.of(context).textTheme.bodySmall),
              Text(dropoff, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
