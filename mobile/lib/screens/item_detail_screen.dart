import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../components/components.dart';
import 'package:geolocator/geolocator.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Item? _item;
  List<ItemLocation> _locations = [];
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final item = await DatabaseService.getItemById(widget.itemId);
    final locs = await DatabaseService.getItemLocations(widget.itemId);
    if (mounted) {
      setState(() {
        _item = item;
        _locations = locs;
      });
    }
  }

  Future<void> _markGps() async {
    setState(() => _marking = true);
    try {
      // Check/request permission first
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to mark GPS coordinates.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      await DatabaseService.markItemLocation(
        _item!.id,
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS coordinates saved.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get GPS location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  void _setAddress() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Address'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter address or location name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await DatabaseService.setItemAddress(_item!.id, controller.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editItem() {
    final nameController = TextEditingController(text: _item!.name);
    final detailsController = TextEditingController(text: _item!.details);
    final List<MapEntry<String, String>> fieldEntries = _item!.customFields.entries.toList();
    final List<TextEditingController> fieldKeyControllers = fieldEntries.map((e) => TextEditingController(text: e.key)).toList();
    final List<TextEditingController> fieldValueControllers = fieldEntries.map((e) => TextEditingController(text: e.value)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(labelText: 'Details'),
                  maxLines: 3,
                  minLines: 2,
                ),
                if (fieldKeyControllers.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('CUSTOM FIELDS', style: AppTypography.label.copyWith(color: AppColors.secondary)),
                ],
                ...List.generate(fieldKeyControllers.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(controller: fieldKeyControllers[i], decoration: const InputDecoration(hintText: 'Field name')),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 3,
                        child: TextField(controller: fieldValueControllers[i], decoration: const InputDecoration(hintText: 'Value')),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            fieldKeyControllers[i].dispose();
                            fieldValueControllers[i].dispose();
                            fieldKeyControllers.removeAt(i);
                            fieldValueControllers.removeAt(i);
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      ),
                    ],
                  ),
                )),
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      fieldKeyControllers.add(TextEditingController());
                      fieldValueControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('ADD FIELD'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final fields = <String, String>{};
                for (int i = 0; i < fieldKeyControllers.length; i++) {
                  final key = fieldKeyControllers[i].text.trim();
                  if (key.isNotEmpty) {
                    fields[key] = fieldValueControllers[i].text.trim();
                  }
                }
                await DatabaseService.updateItem(
                  _item!.id,
                  nameController.text.trim(),
                  detailsController.text.trim(),
                  customFields: fields,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${_item!.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteItem(_item!.id);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareQrCode() {
    final key = _qrKey;
    AppQrCode.shareQrCode(key, _item!.name);
  }

  final GlobalKey _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return const Scaffold(
        backgroundColor: AppColors.neutral,
        body: Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            onPressed: _editItem,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit item',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareQrCode();
                  break;
                case 'delete':
                  _deleteItem();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'share', child: Text('Share QR Code')),
              const PopupMenuItem(value: 'delete', child: Text('Delete Item')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QR Code
            RepaintBoundary(
              key: _qrKey,
              child: AppQrCode(value: _item!.qrCodeData, size: 180),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Scan this code to identify and locate the item',
              style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: _shareQrCode,
              icon: const Icon(Icons.share, size: 16),
              label: const Text('SHARE QR CODE'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tertiary,
                textStyle: AppTypography.label,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Item Info
            AppCard(
              title: _item!.name,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_item!.details.isNotEmpty)
                    Text(_item!.details, style: AppTypography.body.copyWith(color: AppColors.secondary)),
                  if (_item!.details.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  // Custom fields
                  if (_item!.customFields.isNotEmpty) ...[
                    ..._item!.customFields.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key,
                              style: AppTypography.label.copyWith(color: AppColors.secondary)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(entry.value,
                                style: AppTypography.body.copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(
                    'Created ${_item!.createdAt.toLocal().toString().split('.').first.substring(0, 10)}',
                    style: AppTypography.label.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Actions
            AppCard(
              title: 'Actions',
              child: Column(
                children: [
                  AppButton(
                    title: 'MARK GPS',
                    onPressed: _markGps,
                    loading: _marking,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    title: 'SET ADDRESS',
                    variant: AppButtonVariant.ghost,
                    onPressed: _setAddress,
                  ),
                ],
              ),
            ),

            // Location History
            if (_locations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                title: 'Location History',
                child: Column(
                  children: _locations.map((loc) => _locationRow(loc)).toList(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(ItemLocation loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppColors.tertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loc.address.isNotEmpty)
                  Text(loc.address,
                      style: AppTypography.body.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                if (loc.latitude != null && loc.longitude != null)
                  Text('${loc.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}',
                      style: AppTypography.body.copyWith(
                          color: AppColors.secondary, fontSize: 12)),
                Text(
                  loc.timestamp.toLocal().toString().split('.').first.substring(0, 16),
                  style: AppTypography.label.copyWith(
                      color: AppColors.secondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}