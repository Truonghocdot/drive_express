import 'package:flutter/material.dart';

import '../../../api/driver_api.dart';
import '../../driver_app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/driver_feedback.dart';
import '../../widgets/driver_shell.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key, required this.controller});

  final DriverAppController controller;

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.controller.loadHistory(),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller;
    final jobs = state.history;
    final summary = state.historySummary;
    return RefreshIndicator(
      onRefresh: () => state.loadHistory(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applySearch(),
            decoration: InputDecoration(
              hintText: 'Tìm mã chuyến hoặc địa chỉ',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Lọc lịch sử',
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.tune),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: state.historyFilter.status == null,
                  onSelected: () =>
                      _apply(state.historyFilter.copyWith(clearStatus: true)),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Hoàn tất',
                  selected: state.historyFilter.status == 'COMPLETED',
                  onSelected: () =>
                      _apply(state.historyFilter.copyWith(status: 'COMPLETED')),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Đã hủy',
                  selected: state.historyFilter.status == 'CANCELLED',
                  onSelected: () =>
                      _apply(state.historyFilter.copyWith(status: 'CANCELLED')),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Giao hàng',
                  selected: state.historyFilter.serviceType == 'DELIVERY',
                  onSelected: () => _apply(
                    state.historyFilter.copyWith(serviceType: 'DELIVERY'),
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Chở khách',
                  selected: state.historyFilter.serviceType == 'DRIVE',
                  onSelected: () => _apply(
                    state.historyFilter.copyWith(serviceType: 'DRIVE'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DriverSectionTitle(
            'Tổng kết ca chạy',
            action: TextButton.icon(
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(_dateLabel(state.historyFilter)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DriverMetricTile(
                  icon: Icons.check_circle_outline,
                  label: 'Chuyến hoàn tất',
                  value: '${summary.completedCount}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DriverMetricTile(
                  icon: Icons.payments_outlined,
                  label: 'Thu nhập',
                  value: '${summary.netEarning.toStringAsFixed(0)} đ',
                  color: context.driverTokens.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          DriverSectionTitle('Chuyến đã thực hiện (${jobs.length})'),
          const SizedBox(height: 10),
          if (state.error case final error?) DriverErrorBanner(message: error),
          if (jobs.isEmpty && state.busy)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (jobs.isEmpty)
            const DriverEmptyState(
              icon: Icons.history,
              title: 'Chưa có lịch sử',
              message: 'Các chuyến đã đóng sẽ xuất hiện tại đây.',
            )
          else
            for (final job in jobs) _jobCard(context, job),
        ],
      ),
    );
  }

  Widget _jobCard(BuildContext context, DriverJobSummary job) {
    final completed = job.status == 'COMPLETED';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: completed ? () => _rate(context, job.id) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.driverTokens.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    job.serviceType == 'DELIVERY'
                        ? Icons.local_shipping_outlined
                        : Icons.local_taxi_outlined,
                    color: context.driverTokens.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatDriverValue(job.serviceType),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          DriverStatusBadge(job.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.pickupAddress ?? job.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        job.dropoffAddress ?? 'Địa chỉ điểm trả',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${(job.driverNetEarning ?? 0).toStringAsFixed(0)} đ',
                            style: TextStyle(
                              color: context.driverTokens.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDriverValue(job.paymentMethod),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (completed) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applySearch() {
    _apply(
      widget.controller.historyFilter.copyWith(
        query: searchController.text,
        page: 1,
        clearQuery: searchController.text.trim().isEmpty,
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
    );
    if (selected == null) return;
    _apply(
      widget.controller.historyFilter.copyWith(
        from: selected.start,
        to: selected.end,
        page: 1,
      ),
    );
  }

  void _apply(DriverHistoryFilter filter) {
    searchController.text = filter.query ?? '';
    widget.controller.loadHistory(filter: filter);
  }

  String _dateLabel(DriverHistoryFilter filter) {
    if (filter.from == null && filter.to == null) return 'Ngày';
    return '${filter.from!.day}/${filter.from!.month} - ${filter.to!.day}/${filter.to!.month}';
  }

  Future<void> _rate(BuildContext context, String requestId) async {
    var score = 5;
    final comment = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đánh giá khách hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: score,
                decoration: const InputDecoration(labelText: 'Số sao'),
                items: [1, 2, 3, 4, 5]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value sao'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setDialogState(() => score = value ?? 5),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: comment,
                decoration: const InputDecoration(labelText: 'Nhận xét'),
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
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
    if (send == true) {
      await widget.controller.support?.submitRating(
        session: widget.controller.session,
        serviceRequestId: requestId,
        score: score,
        comment: comment.text,
      );
    }
    await disposeTextControllerAfterRoute(comment);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: context.driverTokens.primary.withValues(alpha: 0.2),
      side: BorderSide(
        color: selected
            ? context.driverTokens.primary
            : context.driverTokens.divider,
      ),
    );
  }
}
