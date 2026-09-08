import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../components/components.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.add_circle_outline,
      title: 'Add your gear',
      description:
          "Create an item and stokesdrift generates a QR code automatically. Print it, stick it on your case, and you're ready to track.",
      accent: AppColors.tertiary,
    ),
    _OnboardingPage(
      icon: Icons.qr_code_scanner,
      title: 'Scan to locate',
      description:
          'Point your phone at any QR code to instantly log where that item is. GPS coordinates are recorded automatically — even without cell service.',
      accent: AppColors.secondary,
    ),
    _OnboardingPage(
      icon: Icons.check_circle_outline,
      title: 'Check out & go',
      description:
          "Before leaving a venue, tap Checkout Scan and scan everything. stokesdrift instantly shows you what's missing. Never leave gear behind again.",
      accent: AppColors.primary,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  'SKIP',
                  style: AppTypography.label.copyWith(color: AppColors.secondary),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _buildPage(_pages[i]),
              ),
            ),

            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  return Container(
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == i ? AppColors.tertiary : AppColors.secondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              child: AppButton(
                title: _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 56,
              color: page.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            page.title,
            style: AppTypography.h1.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.description,
            style: AppTypography.body.copyWith(color: AppColors.secondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });
}

/// Check if the onboarding has been completed before.
/// Returns true if the user has already seen and dismissed the onboarding.
Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}