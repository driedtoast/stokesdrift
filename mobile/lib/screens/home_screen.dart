import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../components/components.dart';
import '../navigation/app_navigator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stats _stats = const Stats(totalItems: 0, totalLocations: 0, recentScans: 0);
  List<Item> _recentItems = [];
  List<Location> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DatabaseService.getStats();
    final items = await DatabaseService.getItems();
    final locations = await DatabaseService.getLocations();
    if (mounted) {
      setState(() {
        _stats = stats;
        _recentItems = items.take(5).toList();
        _locations = locations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Hero
              const SizedBox(height: AppSpacing.lg),
              Text('stokesdrift', style: AppTypography.display.copyWith(color: AppColors.primary)),
              const SizedBox(height: AppSpacing.xs),
              Text('Track items. Mark locations. Stay organized.',
                  style: AppTypography.body.copyWith(color: AppColors.secondary)),

              const SizedBox(height: AppSpacing.md),

              // Stats row
              Row(
                children: [
                  _statCard('${_stats.totalItems}', 'ITEMS'),
                  const SizedBox(width: AppSpacing.sm),
                  _statCard('${_stats.totalLocations}', 'LOCATIONS'),
                  const SizedBox(width: AppSpacing.sm),
                  _statCard('${_stats.recentScans}', 'SCANS'),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Quick actions
              AppCard(
                title: 'Quick Actions',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            title: '+ ADD ITEM',
                            onPressed: () => goToAddItem(context),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            title: 'SCAN QR',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => switchTab(context, 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        title: 'CHECKOUT SCAN',
                        variant: AppButtonVariant.ghost,
                        onPressed: () => goToCheckout(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Recent Items
              if (_recentItems.isNotEmpty)
                AppCard(
                  title: 'Recent Items',
                  child: Column(
                    children: _recentItems.map((item) => _itemRow(item)).toList(),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              // Locations
              if (_locations.isNotEmpty)
                AppCard(
                  title: 'Locations',
                  child: Column(
                    children: _locations.map((loc) => _locationRow(loc)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(number, style: AppTypography.h1.copyWith(color: AppColors.primary)),
            Text(label, style: AppTypography.label.copyWith(color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(Item item) {
    return InkWell(
      onTap: () => goToItemDetail(context, item.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
            const SizedBox(width: AppSpacing.sm),
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
    );
  }

  Widget _locationRow(Location loc) {
    return InkWell(
      onTap: () => goToLocationDetail(context, loc.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.name,
                      style: AppTypography.body.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                  if (loc.address.isNotEmpty)
                    Text(loc.address,
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
    );
  }
}