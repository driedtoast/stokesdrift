import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../components/components.dart';
import 'item_detail_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final List<_CustomFieldEntry> _customFields = [];
  bool _saving = false;
  Item? _createdItem;

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final fields = <String, String>{};
      for (final f in _customFields) {
        if (f.keyController.text.trim().isNotEmpty) {
          fields[f.keyController.text.trim()] = f.valueController.text.trim();
        }
      }
      final item = await DatabaseService.createItem(
        _nameController.text.trim(),
        details: _detailsController.text.trim(),
        customFields: fields,
      );
      setState(() => _createdItem = item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(_CustomFieldEntry(
        keyController: TextEditingController(),
        valueController: TextEditingController(),
      ));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index].keyController.dispose();
      _customFields[index].valueController.dispose();
      _customFields.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    for (final f in _customFields) {
      f.keyController.dispose();
      f.valueController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_createdItem != null) {
      return Scaffold(
        backgroundColor: AppColors.neutral,
        appBar: AppBar(title: const Text('Item Created')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✓', style: TextStyle(fontSize: 48, color: AppColors.tertiary)),
                const SizedBox(height: AppSpacing.sm),
                Text('Item Created!', style: AppTypography.h1.copyWith(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.xs),
                Text(_createdItem!.name,
                    style: AppTypography.body.copyWith(color: AppColors.secondary)),
                const SizedBox(height: AppSpacing.md),
                AppQrCode(value: _createdItem!.qrCodeData, size: 220),
                const SizedBox(height: AppSpacing.sm),
                Text('Scan this code to identify and locate the item',
                    style: AppTypography.body.copyWith(
                        color: AppColors.secondary, fontSize: 12),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  title: 'VIEW ITEM',
                  onPressed: () {
                    final itemId = _createdItem!.id;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(itemId: itemId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  title: 'ADD ANOTHER',
                  variant: AppButtonVariant.ghost,
                  onPressed: () {
                    setState(() {
                      _createdItem = null;
                      _nameController.clear();
                      _detailsController.clear();
                      for (final f in _customFields) {
                        f.keyController.dispose();
                        f.valueController.dispose();
                      }
                      _customFields.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(title: const Text('Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ITEM NAME', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Shure SM58 Microphone'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('DETAILS', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(hintText: 'Description, serial number, notes…'),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),

              // Custom fields
              Text('CUSTOM FIELDS', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              ...List.generate(_customFields.length, (i) {
                final field = _customFields[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: field.keyController,
                          decoration: const InputDecoration(hintText: 'Field name'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: field.valueController,
                          decoration: const InputDecoration(hintText: 'Value'),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeCustomField(i),
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addCustomField,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD FIELD'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Text(
                'A QR code will be generated automatically when you create the item.',
                style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                title: 'CREATE ITEM',
                onPressed: _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomFieldEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _CustomFieldEntry({required this.keyController, required this.valueController});
}