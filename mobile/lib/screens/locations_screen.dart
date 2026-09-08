import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../navigation/app_navigator.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<Location> _locations = [];
  List<Location> _filteredLocations = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final locations = await DatabaseService.getLocations();
    final counts = <String, int>{};
    for (final loc in locations) {
      final items = await DatabaseService.getItemsAtLocation(loc.id);
      counts[loc.id] = items.length;
    }
    if (mounted) {
      setState(() {
        _locations = locations;
        _counts = counts;
        _loading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredLocations = _locations;
    } else {
      final q = _searchQuery.toLowerCase();
      _filteredLocations = _locations.where((loc) {
        return loc.name.toLowerCase().contains(q) ||
            loc.address.toLowerCase().contains(q);
      }).toList();
    }
  }

  void _deleteLocation(Location loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${loc.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseService.deleteLocation(loc.id);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
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
        title: const Text('Locations'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: () => goToAddLocation(context),
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
                hintText: 'Search locations…',
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
          // Locations list
          Expanded(
            child: _filteredLocations.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _searchQuery.isNotEmpty ? 'No matching locations' : 'No locations yet',
                          style: AppTypography.h2.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add locations to group items by place',
                          style: AppTypography.body.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _filteredLocations.length,
                      itemBuilder: (ctx, i) {
                        final loc = _filteredLocations[i];
                        final count = _counts[loc.id] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            onTap: () => goToLocationDetail(context, loc.id),
                            onLongPress: () => _deleteLocation(loc),
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
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(loc.name,
                                            style: AppTypography.body.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600)),
                                        if (loc.address.isNotEmpty)
                                          Text(loc.address,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.body.copyWith(
                                                  color: AppColors.secondary, fontSize: 13))
                                        else if (loc.latitude != null && loc.longitude != null)
                                          Text(
                                              '${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}',
                                              style: AppTypography.body.copyWith(
                                                  color: AppColors.secondary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('$count',
                                        style: AppTypography.label.copyWith(
                                            color: AppColors.onPrimary, fontSize: 11)),
                                  ),
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