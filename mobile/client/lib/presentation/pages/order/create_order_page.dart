import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/booking_api.dart';
import '../../../api/goong_location_api.dart';
import '../../../api/session_store.dart';
import '../../client_app_controller.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/goong_map_preview.dart';
import 'order_checkout_page.dart';
import 'ride_quote_selection_page.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    required this.controller,
    required this.service,
    this.isProxyBooking = false,
    this.initialPickup,
  });

  final ClientAppController controller;
  final ServiceKind service;
  final bool isProxyBooking;
  final FavoriteAddress? initialPickup;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final formKey = GlobalKey<FormState>();
  final pickupAddress = TextEditingController();
  final dropoffAddress = TextEditingController();
  final goodsType = TextEditingController(text: 'GENERAL');
  final weight = TextEditingController(text: '5');
  final duration = TextEditingController(text: '1');
  final passengerName = TextEditingController();
  final passengerPhone = TextEditingController();
  late final TextEditingController voucher = TextEditingController(
    text: widget.controller.selectedVoucherCode ?? '',
  );
  GoongCoordinate _pickup = const GoongCoordinate(latitude: 0, longitude: 0);
  GoongCoordinate _dropoff = const GoongCoordinate(latitude: 0, longitude: 0);
  GoongRoute? _route;
  String? _routeError;
  bool _pickupConfirmed = false;
  bool _dropoffConfirmed = false;
  DateTime? scheduledAt;
  Timer? _voucherDebounce;

  @override
  void initState() {
    super.initState();
    final favorite = widget.initialPickup;
    if (favorite != null) {
      pickupAddress.text = favorite.address;
      _pickup = GoongCoordinate(
        latitude: favorite.latitude,
        longitude: favorite.longitude,
      );
      _pickupConfirmed = true;
    }
    // Location fields intentionally start empty. Coordinates must come from a
    // confirmed Goong place or the device location action.
  }

  @override
  void dispose() {
    for (final controller in [
      pickupAddress,
      dropoffAddress,
      goodsType,
      weight,
      duration,
      passengerName,
      passengerPhone,
      voucher,
    ]) {
      controller.dispose();
    }
    _voucherDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.service == ServiceKind.delivery;
    final hourly = widget.service == ServiceKind.hourly;
    final drive = widget.service == ServiceKind.drive;
    final goong = widget.controller.goong;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            delivery
                ? 'Tạo đơn giao hàng'
                : hourly
                ? 'Thuê xe theo giờ'
                : 'Tạo chuyến xe',
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _StepHeader(
                step: '1',
                title: hourly ? 'Chọn điểm đón' : 'Chọn điểm đón và điểm đến',
                subtitle: hourly
                    ? 'Tài xế sẽ phục vụ tại điểm đón trong thời lượng đã chọn.'
                    : 'Tìm và chọn đúng địa chỉ để tài xế đến chính xác.',
              ),
              if (!hourly) const SizedBox(height: 12),
              GoongLocationField(
                key: const Key('pickup-location-field'),
                label: 'Điểm đón / lấy hàng',
                icon: Icons.radio_button_checked,
                controller: pickupAddress,
                api: goong,
                initialCoordinate: _pickup,
                onSelected: (place) {
                  setState(() {
                    _pickup = place.coordinate;
                    _pickupConfirmed = true;
                    pickupAddress.text = place.address;
                  });
                  unawaited(_updateRoute());
                  unawaited(_refreshDriveQuotes());
                },
                onInputChanged: () {
                  setState(() {
                    _pickupConfirmed = false;
                    _route = null;
                  });
                  _clearDriveQuotes();
                },
                onUseCurrentLocation: widget.controller.currentPosition == null
                    ? null
                    : _useCurrentLocation,
              ),
              if (!hourly) const SizedBox(height: 12),
              if (!hourly)
                GoongLocationField(
                  key: const Key('dropoff-location-field'),
                  label: 'Điểm đến / giao hàng',
                  icon: Icons.location_on_outlined,
                  controller: dropoffAddress,
                  api: goong,
                  initialCoordinate: _dropoff,
                  onSelected: (place) {
                    setState(() {
                      _dropoff = place.coordinate;
                      _dropoffConfirmed = true;
                      dropoffAddress.text = place.address;
                    });
                    unawaited(_updateRoute());
                    unawaited(_refreshDriveQuotes());
                  },
                  onInputChanged: () {
                    setState(() {
                      _dropoffConfirmed = false;
                      _route = null;
                    });
                    _clearDriveQuotes();
                  },
                ),
              if (drive && widget.controller.busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
              if (drive &&
                  _driveLocationsReady &&
                  widget.controller.quotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chọn xe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final quote in widget.controller.quotes) ...[
                      Expanded(
                        child: SizedBox(
                          height: 140,
                          child: RideQuoteCard(
                            key: Key('ride-quote-${quote.id}'),
                            quote: quote,
                            selected:
                                widget.controller.selectedQuote?.id == quote.id,
                            compact: true,
                            onTap: () => widget.controller.selectQuote(quote),
                          ),
                        ),
                      ),
                      if (quote != widget.controller.quotes.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
              if (!hourly && _pickupConfirmed && _dropoffConfirmed)
                GoongMapPreview(
                  pickup: _pickup,
                  dropoff: _dropoff,
                  route: _route?.geometry,
                  mapKey: const String.fromEnvironment('GOONG_MAP_KEY'),
                )
              else if (!hourly)
                const _MapPending(),
              if (!hourly && _route != null) ...[
                const SizedBox(height: 8),
                _RouteSummary(route: _route!),
              ],
              if (!hourly && _routeError != null) ...[
                const SizedBox(height: 8),
                ErrorBanner(message: _routeError!),
              ],
              if (!hourly && goong?.configured != true) ...[
                const SizedBox(height: 8),
                const ErrorBanner(
                  message:
                      'Chưa cấu hình GOONG_API_KEY; tìm kiếm địa chỉ đang tắt.',
                ),
              ],
              if (widget.controller.locationError case final error?) ...[
                const SizedBox(height: 10),
                ErrorBanner(message: error),
              ],
              if (!drive) ...[
                const SizedBox(height: 22),
                _StepHeader(
                  step: '2',
                  title: delivery ? 'Thông tin hàng hóa' : 'Thời lượng thuê',
                  subtitle: delivery
                      ? 'Nhập đủ thông tin để hệ thống tính cước chính xác.'
                      : 'Chọn số giờ phục vụ, tối đa 12 giờ.',
                ),
                const SizedBox(height: 12),
              ],
              if (delivery) ...[
                TextFormField(
                  controller: goodsType,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập loại hàng hóa.'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Loại hàng hóa',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: weight,
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    return parsed == null || parsed <= 0
                        ? 'Khối lượng phải lớn hơn 0.'
                        : null;
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Khối lượng (kg)',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                ),
              ],
              if (hourly)
                TextFormField(
                  controller: duration,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    return parsed == null || parsed < 1 || parsed > 12
                        ? 'Thời lượng từ 1 đến 12 giờ.'
                        : null;
                  },
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số giờ thuê',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                ),
              if (!delivery && widget.isProxyBooking) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: passengerName,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập tên người đi.'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Tên người đi',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passengerPhone,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập số điện thoại người đi.'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại người đi',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: voucher,
                onChanged: drive
                    ? (_) {
                        _voucherDebounce?.cancel();
                        _voucherDebounce = Timer(
                          const Duration(milliseconds: 450),
                          () => unawaited(_refreshDriveQuotes()),
                        );
                      }
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Mã giảm giá (không bắt buộc)',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
              ),
              const SizedBox(height: 10),
              if (!delivery)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    scheduledAt == null
                        ? 'Đặt ngay'
                        : 'Đặt lúc ${scheduledAt!.day}/${scheduledAt!.month} '
                              '${scheduledAt!.hour.toString().padLeft(2, '0')}:'
                              '${scheduledAt!.minute.toString().padLeft(2, '0')}',
                  ),
                  subtitle: const Text('Bạn có thể đặt trước tối đa 30 ngày.'),
                  trailing: IconButton(
                    tooltip: 'Chọn thời gian',
                    onPressed: _pickSchedule,
                    icon: const Icon(Icons.edit_calendar_outlined),
                  ),
                ),
              if (widget.controller.error case final error?) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: error),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: drive
                    ? FilledButton.icon(
                        key: const Key('continue-button'),
                        onPressed:
                            widget.controller.busy ||
                                widget.controller.selectedQuote == null
                            ? null
                            : _continue,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Tiếp tục'),
                      )
                    : FilledButton.icon(
                        key: const Key('quote-button'),
                        onPressed: widget.controller.busy ? null : _quote,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Nhận báo giá'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final position = await widget.controller.refreshLocation();
    if (position == null || !mounted) return;
    final coordinate = GoongCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    setState(() {
      _pickup = coordinate;
      _pickupConfirmed = true;
      pickupAddress.text = 'Vị trí hiện tại';
    });
    unawaited(_updateRoute());
    unawaited(_refreshDriveQuotes());
  }

  Future<void> _quote() async {
    final hourly = widget.service == ServiceKind.hourly;
    if (!formKey.currentState!.validate()) return;
    final goong = widget.controller.goong;
    if (goong?.configured != true ||
        pickupAddress.text.trim().isEmpty ||
        !_pickupConfirmed ||
        (!hourly &&
            (dropoffAddress.text.trim().isEmpty || !_dropoffConfirmed))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hourly
                ? 'Hãy cấu hình Goong và chọn điểm đón.'
                : 'Hãy cấu hình Goong và chọn đủ điểm đón, điểm đến.',
          ),
        ),
      );
      return;
    }
    if (goong?.configured == true && _route == null) {
      await _updateRoute();
    }
    await widget.controller.requestQuote(_draft());
    if (widget.controller.error != null || !mounted) return;
    if (widget.controller.quote != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderCheckoutPage(controller: widget.controller),
        ),
      );
    }
  }

  bool get _driveLocationsReady =>
      _pickupConfirmed &&
      _dropoffConfirmed &&
      pickupAddress.text.trim().isNotEmpty &&
      dropoffAddress.text.trim().isNotEmpty;

  void _clearDriveQuotes() {
    if (widget.service == ServiceKind.drive) widget.controller.clearQuotes();
  }

  Future<void> _refreshDriveQuotes() async {
    if (widget.service != ServiceKind.drive || !_driveLocationsReady) return;
    await widget.controller.requestQuote(_draft());
  }

  BookingDraft _draft() {
    final delivery = widget.service == ServiceKind.delivery;
    final hourly = widget.service == ServiceKind.hourly;
    return BookingDraft(
      service: widget.service,
      pickup: LocationDraft(
        address: pickupAddress.text.trim(),
        latitude: _pickup.latitude,
        longitude: _pickup.longitude,
      ),
      dropoff: hourly
          ? null
          : LocationDraft(
              address: dropoffAddress.text.trim(),
              latitude: _dropoff.latitude,
              longitude: _dropoff.longitude,
            ),
      goodsType: goodsType.text.trim(),
      weightKg: double.tryParse(weight.text.replaceAll(',', '.')) ?? 0,
      passengerCount: 1,
      voucherCode: voucher.text.trim().isEmpty ? null : voucher.text.trim(),
      scheduledAt: delivery ? null : scheduledAt,
      vehicleTypeId: hourly || delivery
          ? widget.controller.vehicleIdForKey('MOTORBIKE')
          : null,
      vehicleTypeIds: delivery || hourly
          ? null
          : [
              widget.controller.vehicleIdForKey('MOTORBIKE'),
              widget.controller.vehicleIdForKey('CAR_4_SEAT'),
            ].whereType<String>().toList(growable: false),
      passengerName: widget.isProxyBooking ? passengerName.text.trim() : null,
      passengerPhone: widget.isProxyBooking ? passengerPhone.text.trim() : null,
      durationHours: hourly ? int.tryParse(duration.text) : null,
    );
  }

  void _continue() {
    if (widget.controller.selectedQuote == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderCheckoutPage(controller: widget.controller),
      ),
    );
  }

  Future<void> _updateRoute() async {
    final goong = widget.controller.goong;
    if (goong?.configured != true || !_pickupConfirmed || !_dropoffConfirmed) {
      return;
    }
    try {
      final route = await goong!.directions(
        origin: _pickup,
        destination: _dropoff,
        vehicle: widget.service == ServiceKind.delivery ? 'bike' : 'car',
      );
      if (mounted) {
        setState(() {
          _route = route;
          _routeError = null;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          _route = null;
          _routeError = exception.toString();
        });
      }
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(
      () => scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
    unawaited(_refreshDriveQuotes());
  }
}

class GoongLocationField extends StatefulWidget {
  const GoongLocationField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.api,
    required this.initialCoordinate,
    required this.onSelected,
    this.onInputChanged,
    this.onUseCurrentLocation,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final GoongLocationApi? api;
  final GoongCoordinate initialCoordinate;
  final ValueChanged<GoongPlace> onSelected;
  final VoidCallback? onInputChanged;
  final VoidCallback? onUseCurrentLocation;

  @override
  State<GoongLocationField> createState() => _GoongLocationFieldState();
}

class _GoongLocationFieldState extends State<GoongLocationField> {
  Timer? _debounce;
  List<GoongPlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (_) => _geocodeTypedAddress(),
          decoration: InputDecoration(
            labelText: 'Nhập địa chỉ',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.onUseCurrentLocation == null
                ? null
                : IconButton(
                    tooltip: 'Dùng vị trí hiện tại',
                    onPressed: widget.onUseCurrentLocation,
                    icon: const Icon(Icons.my_location_outlined),
                  ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              children: [
                for (final suggestion in _suggestions)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(suggestion.mainText ?? suggestion.description),
                    subtitle: suggestion.secondaryText == null
                        ? null
                        : Text(suggestion.secondaryText!),
                    onTap: () => _selectSuggestion(suggestion),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _onChanged(String value) {
    widget.onInputChanged?.call();
    _debounce?.cancel();
    setState(() {
      _suggestions = const [];
      _message = null;
    });
    if (value.trim().length < 2 || widget.api?.configured != true) return;
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final suggestions = await widget.api!.autocomplete(
          value,
          location: widget.initialCoordinate,
        );
        if (mounted) setState(() => _suggestions = suggestions.toList());
      } catch (exception) {
        if (mounted) setState(() => _message = exception.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _selectSuggestion(GoongPlaceSuggestion suggestion) async {
    final api = widget.api;
    if (api == null) return;
    setState(() {
      _loading = true;
      _suggestions = const [];
      _message = null;
    });
    try {
      final place = await api.placeDetail(suggestion.placeId);
      widget.controller.text = place.address;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
      widget.onSelected(place);
    } catch (exception) {
      if (mounted) setState(() => _message = exception.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _geocodeTypedAddress() async {
    final api = widget.api;
    if (api == null ||
        !api.configured ||
        widget.controller.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final place = await api.geocode(widget.controller.text);
      widget.controller.text = place.address;
      widget.onSelected(place);
    } catch (exception) {
      if (mounted) setState(() => _message = exception.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _MapPending extends StatelessWidget {
  const _MapPending();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.map_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Chọn điểm đón và điểm đến để xem tuyến đường.'),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          child: Text(step),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.route});

  final GoongRoute route;

  @override
  Widget build(BuildContext context) {
    final kilometers = route.distanceMeters / 1000;
    final minutes = (route.durationSeconds / 60).ceil();
    return Row(
      children: [
        const Icon(Icons.route_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 16,
            runSpacing: 2,
            children: [
              Text('${kilometers.toStringAsFixed(1)} km'),
              Text('$minutes phút dự kiến'),
            ],
          ),
        ),
      ],
    );
  }
}
