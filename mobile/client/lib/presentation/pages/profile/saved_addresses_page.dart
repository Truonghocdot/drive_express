import 'package:flutter/material.dart';

import '../../../api/session_store.dart';
import '../../client_app_controller.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key, required this.controller});

  final ClientAppController controller;

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  Future<void> _add() async {
    final address = TextEditingController();
    final label = TextEditingController(text: 'Địa chỉ mới');
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm địa chỉ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Tên gợi nhớ'),
            ),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              label.text.trim(),
              address.text.trim(),
            )),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    address.dispose();
    label.dispose();
    if (!mounted || result == null || result.$1.isEmpty || result.$2.isEmpty) {
      return;
    }
    final geocoder = widget.controller.goong;
    if (geocoder == null) return;
    try {
      final place = await geocoder.geocode(result.$2);
      await widget.controller.saveFavoriteAddress(
        FavoriteAddress(
          label: result.$1,
          address: place.address,
          latitude: place.coordinate.latitude,
          longitude: place.coordinate.longitude,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _rename(FavoriteAddress address) async {
    final label = TextEditingController(text: address.label);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên địa chỉ'),
        content: TextField(controller: label, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, label.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    label.dispose();
    if (!mounted || next == null || next.isEmpty || next == address.label) {
      return;
    }
    await widget.controller.saveFavoriteAddress(
      FavoriteAddress(
        label: next,
        address: address.address,
        latitude: address.latitude,
        longitude: address.longitude,
      ),
    );
    await widget.controller.deleteFavoriteAddress(address);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Địa chỉ đã lưu')),
        floatingActionButton: FloatingActionButton(
          onPressed: widget.controller.favoriteAddresses.length >= 10
              ? null
              : _add,
          tooltip: 'Thêm địa chỉ',
          child: const Icon(Icons.add),
        ),
        body: widget.controller.favoriteAddresses.isEmpty
            ? const Center(child: Text('Chưa có địa chỉ yêu thích.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.controller.favoriteAddresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final address = widget.controller.favoriteAddresses[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.bookmark_outline),
                      title: Text(address.label),
                      subtitle: Text(address.address),
                      onTap: () => _rename(address),
                      trailing: IconButton(
                        tooltip: 'Xóa địa chỉ',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            widget.controller.deleteFavoriteAddress(address),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
