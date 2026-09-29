import 'package:flutter/material.dart';

import '../../../api/booking_api.dart';
import '../../client_app_controller.dart';
import 'order_checkout_page.dart';

class RideQuoteSelectionPage extends StatelessWidget {
  const RideQuoteSelectionPage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  Widget build(BuildContext context) {
    final quotes = controller.quotes;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.selectedQuote;
        return Scaffold(
          appBar: AppBar(title: const Text('Chọn loại xe')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Báo giá chuyến xe',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text('Chọn phương tiện phù hợp với nhu cầu của bạn.'),
              const SizedBox(height: 16),
              for (final quote in quotes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RideQuoteCard(
                    quote: quote,
                    selected: selected?.id == quote.id,
                    onTap: () => controller.selectQuote(quote),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: selected == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderCheckoutPage(controller: controller),
                        ),
                      ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Tiếp tục'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RideQuoteCard extends StatelessWidget {
  const RideQuoteCard({
    super.key,
    required this.quote,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final QuoteSummary quote;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name =
        quote.vehicleName ??
        (quote.vehicleKey == 'MOTORBIKE' ? 'Xe máy' : 'Ô tô 4 chỗ');
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: compact
              ? _compactContent(context, name)
              : Row(
                  children: [
                    Icon(
                      quote.vehicleKey == 'MOTORBIKE'
                          ? Icons.two_wheeler_outlined
                          : Icons.directions_car_outlined,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(quote.distanceMeters / 1000).toStringAsFixed(1)} km · '
                            '${(quote.durationSeconds / 60).ceil()} phút',
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${quote.customerPayable.toStringAsFixed(0)} VND',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _compactContent(BuildContext context, String name) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              quote.vehicleKey == 'MOTORBIKE'
                  ? Icons.two_wheeler_outlined
                  : Icons.directions_car_outlined,
              color: colors.primary,
            ),
            const Spacer(),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.primary : colors.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Text(
          '${quote.customerPayable.toStringAsFixed(0)} VND',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${(quote.durationSeconds / 60).ceil()} phút',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
