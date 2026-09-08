import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'db/database.dart';
import 'splash/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'navigation/app_navigator.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the CRDT database on the device filesystem
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = join(dir.path, 'stokesdrift.db');
  await DatabaseService.init(dbPath);

  runApp(const StokesdriftApp());
}

class StokesdriftApp extends StatefulWidget {
  const StokesdriftApp({super.key});

  @override
  State<StokesdriftApp> createState() => _StokesdriftAppState();
}

class _StokesdriftAppState extends State<StokesdriftApp> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    SplashController.markReady();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final complete = await isOnboardingComplete();
    if (mounted) {
      setState(() {
        _showOnboarding = !complete;
      });
    }
  }

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  void _onOnboardingComplete() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'stokesdrift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _showSplash
          ? SplashScreen(onComplete: _onSplashComplete)
          : _showOnboarding
              ? OnboardingScreen(onComplete: _onOnboardingComplete)
              : const MainTabs(),
    );
  }
}