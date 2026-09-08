import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../components/components.dart';
import 'checkout_scan_screen.dart';

class StartCheckoutScreen extends StatefulWidget {
  const StartCheckoutScreen({super.key});

  @override
  State<StartCheckoutScreen> createState() => _StartCheckoutScreenState();
}

class _StartCheckoutScreenState extends State<StartCheckoutScreen> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    setState(() => _creating = true);
    try {
      final name = _nameController.text.trim().isEmpty
          ? 'Checkout ${DateTime.now().month}/${DateTime.now().day}'
          : _nameController.text.trim();

      final session = await DatabaseService.createCheckoutSession(name: name);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckoutScanScreen(session: session),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text('Checkout Scan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explanation
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.tertiary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Checkout scan compares scanned items against your full inventory. After scanning, you\'ll see a list of anything that\'s missing.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('SESSION NAME', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Load-out from Main Stage',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Give this checkout a name so you can find it later. Defaults to today\'s date.',
                style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 13),
              ),

              const SizedBox(height: AppSpacing.lg),

              AppButton(
                title: 'START SCANNING',
                onPressed: _startCheckout,
                loading: _creating,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You\'ll scan each item\'s QR code to mark it as checked out.',
                style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}