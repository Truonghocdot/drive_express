import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'request_id.dart';

abstract interface class BookingSessionStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<String?> readLastRequestId();
  Future<void> writeLastRequestId(String id);
  Future<void> clearLastRequestId();
  Future<void> clear();
}

class FavoriteAddress {
  const FavoriteAddress({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String address;
  final double latitude;
  final double longitude;

  factory FavoriteAddress.fromJson(Map<String, dynamic> json) =>
      FavoriteAddress(
        label: json['label'].toString(),
        address: json['address'].toString(),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}

abstract interface class FavoriteAddressStore {
  Future<List<FavoriteAddress>> readFavoriteAddresses(String namespace);
  Future<void> writeFavoriteAddresses(
    String namespace,
    List<FavoriteAddress> addresses,
  );
}

class SecureBookingSessionStore
    implements BookingSessionStore, FavoriteAddressStore {
  const SecureBookingSessionStore();

  static const _storage = FlutterSecureStorage();

  Future<String> installationId() async {
    final saved = await _storage.read(key: 'customer_device_id');
    if (saved != null) return saved;
    final created = newRequestId();
    await _storage.write(key: 'customer_device_id', value: created);
    return created;
  }

  @override
  Future<String?> readToken() => _storage.read(key: 'customer_token');

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: 'customer_token', value: token);

  @override
  Future<String?> readLastRequestId() =>
      _storage.read(key: 'customer_last_request');

  @override
  Future<void> writeLastRequestId(String id) =>
      _storage.write(key: 'customer_last_request', value: id);

  @override
  Future<void> clearLastRequestId() =>
      _storage.delete(key: 'customer_last_request');

  @override
  Future<List<FavoriteAddress>> readFavoriteAddresses(String namespace) async {
    final raw = await _storage.read(
      key: 'customer_favorite_addresses_$namespace',
    );
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((item) => FavoriteAddress.fromJson(item.cast<String, dynamic>()))
          .take(10)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writeFavoriteAddresses(
    String namespace,
    List<FavoriteAddress> addresses,
  ) => _storage.write(
    key: 'customer_favorite_addresses_$namespace',
    value: jsonEncode(
      addresses.take(10).map((address) => address.toJson()).toList(),
    ),
  );

  @override
  Future<void> clear() async {
    await _storage.delete(key: 'customer_token');
    await _storage.delete(key: 'customer_last_request');
  }
}
