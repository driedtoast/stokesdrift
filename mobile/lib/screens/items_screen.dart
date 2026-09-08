import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../navigation/app_navigator.dart';
import '../services/csv_export.dart';
import '../services/plan_service.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  bool _loading = true;
  String _searchQuery = '';
  bool _canExport = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadItems();
  }

  Future<void> _loadData() async {
    final canExport = await PlanService.canExportCsv();
    if (mounted) {
      setState(() => _canExport = canExport);
    }
  }

  Future<void> _loadItems() async {
    final items = await DatabaseService.getItems();
    if (mounted) {
      setState(() {
        _items = items;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = _items;
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredItems = _items.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.details.toLowerCase().contains(q);
      }).toList();
    }
  }

  void _deleteItem(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteItem(item.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadItems();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    if (!_canExport) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Upgrade to Export'),
          content: const Text(
            'CSV export is available on the Crew and Enterprise plans. '
            'Upgrade your plan to export your inventory data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export to CSV'),
        content: const Text(
          'Export all items and their most recent locations as a CSV file. '
          'You can share or save the exported file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await CsvExportService.exportAndShare();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: () {
                goToAddItem(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('+ ADD'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilter();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search items…',
                prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.secondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Items list
          Expanded(
            child: _filteredItems.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _searchQuery.isNotEmpty ? 'No matching items' : 'No items yet',
                          style: AppTypography.h2.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first item to get started',
                          style: AppTypography.body.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadItems,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _filteredItems.length,
                      itemBuilder: (ctx, i) {
                        final item = _filteredItems[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => goToItemDetail(context, item.id),
                            onLongPress: () => _deleteItem(item),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.tertiary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: AppTypography.body.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600)),
                                        if (item.details.isNotEmpty)
                                          Text(item.details,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.body.copyWith(
                                                  color: AppColors.secondary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.secondary),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}