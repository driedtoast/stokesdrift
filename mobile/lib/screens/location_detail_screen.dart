import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../navigation/app_navigator.dart';
import '../components/components.dart';
import 'edit_location_screen.dart';

class LocationDetailScreen extends StatefulWidget {
  final String locationId;
  const LocationDetailScreen({super.key, required this.locationId});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  Location? _location;
  List<Item> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final locations = await DatabaseService.getLocations();
    final loc = locations.firstWhere(
      (l) => l.id == widget.locationId,
      orElse: () => Location(id: '', name: 'Unknown', createdAt: DateTime.now()),
    );
    final items = await DatabaseService.getItemsAtLocation(widget.locationId);
    if (mounted) {
      setState(() {
        _location = loc;
        _items = items;
        _loading = false;
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "${_location?.name ?? ''}"? Items will no longer be grouped here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteLocation(widget.locationId);
              if (mounted) {
                Navigator.pop(ctx); // dialog
                Navigator.of(context).pop(); // screen
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.neutral,
        body: Center(child: CircularProgressIndicator(color: AppColors.tertiary)),
      );
    }

    final loc = _location!;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: Text(loc.name),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => EditLocationScreen(location: loc)),
              );
              if (result == true) _loadData();
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit location',
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete location',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Location info card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppCard(
                  title: loc.name,
                  subtitle: loc.address.isNotEmpty ? loc.address : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loc.latitude != null && loc.longitude != null)
                        Row(
                          children: [
                            const Icon(Icons.pin_drop, size: 16, color: AppColors.tertiary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${loc.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}',
                              style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 13),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Radius: ${loc.radius.toInt()}m',
                              style: AppTypography.label.copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_items.length} item${_items.length == 1 ? '' : 's'} at this location',
                        style: AppTypography.body.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Items list
            if (_items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.secondary.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('No items at this location yet',
                          style: AppTypography.body.copyWith(color: AppColors.secondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Scan an item\'s QR code nearby to assign it here',
                          style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final item = _items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: () => goToItemDetail(context, item.id),
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
                                              color: AppColors.primary, fontWeight: FontWeight.w600)),
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
                    childCount: _items.length,
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}