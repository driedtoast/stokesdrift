import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/items_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/locations_screen.dart';
import '../screens/add_item_screen.dart';
import '../screens/add_location_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/location_detail_screen.dart';
import '../screens/start_checkout_screen.dart';
import '../theme/theme.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => MainTabsState();
}

class MainTabsState extends State<MainTabs> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ItemsScreen(),
    ScanScreen(),
    LocationsScreen(),
  ];

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.tertiary,
        unselectedItemColor: AppColors.secondary,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.place_outlined), label: 'Locations'),
        ],
      ),
    );
  }
}

// ─── Route helpers ────────────────────────────────────────────────────────────

void goToAddItem(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddItemScreen()));
}

void goToItemDetail(BuildContext context, String itemId) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: itemId)));
}

void goToAddLocation(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddLocationScreen()));
}

void goToLocationDetail(BuildContext context, String locationId) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => LocationDetailScreen(locationId: locationId)));
}

void goToCheckout(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StartCheckoutScreen()));
}

/// Find the MainTabsState in the widget tree and switch to the given tab.
void switchTab(BuildContext context, int index) {
  final state = context.findAncestorStateOfType<MainTabsState>();
  state?.switchToTab(index);
}