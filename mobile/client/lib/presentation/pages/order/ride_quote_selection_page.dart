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
                  child: _QuoteCard(
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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.selected,
    required this.onTap,
  });

  final QuoteSummary quote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = quote.vehicleName ??
        (quote.vehicleKey == 'MOTORBIKE' ? 'Xe máy' : 'Ô tô 4 chỗ');
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
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
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
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
}
