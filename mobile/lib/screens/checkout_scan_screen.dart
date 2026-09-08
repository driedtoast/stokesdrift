import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../components/components.dart';
import '../services/review_prompt.dart';

class CheckoutScanScreen extends StatefulWidget {
  final CheckoutSession session;
  const CheckoutScanScreen({super.key, required this.session});

  @override
  State<CheckoutScanScreen> createState() => _CheckoutScanScreenState();
}

class _CheckoutScanScreenState extends State<CheckoutScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  Set<String> _checkedOutItemIds = {};
  bool _processing = false;
  String? _errorMessage;
  String? _lastScannedName;

  @override
  void initState() {
    super.initState();
    _loadCheckedOutItems();
  }

  Future<void> _loadCheckedOutItems() async {
    final ids = await DatabaseService.getCheckedOutItemIds(widget.session.id);
    if (mounted) {
      setState(() => _checkedOutItemIds = ids);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    _processCode(barcode.rawValue!);
  }

  Future<void> _processCode(String data) async {
    final item = await DatabaseService.getItemByQrCode(data);

    if (item == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unknown QR code — not a stokesdrift item.';
          _processing = false;
        });
      }
      return;
    }

    // Already checked out in this session
    if (_checkedOutItemIds.contains(item.id)) {
      if (mounted) {
        setState(() {
          _lastScannedName = item.name;
          _errorMessage = null;
          _processing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.name}" already checked out'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Try to get GPS
    double? latitude;
    double? longitude;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        latitude = position.latitude;
        longitude = position.longitude;
      }
    } catch (_) {
      // GPS not available, proceed without it
    }

    await DatabaseService.checkoutItem(
      sessionId: widget.session.id,
      itemId: item.id,
      latitude: latitude,
      longitude: longitude,
    );

    if (mounted) {
      setState(() {
        _checkedOutItemIds.add(item.id);
        _lastScannedName = item.name;
        _processing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${item.name} checked out'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _finishCheckout() async {
    // Show the results screen
    final allItems = await DatabaseService.getItems();
    final missingItems = allItems
        .where((item) => !_checkedOutItemIds.contains(item.id))
        .toList();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CheckoutResultScreen(
          session: widget.session,
          checkedOutIds: _checkedOutItemIds,
          missingItems: missingItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.onPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black26,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          '${_checkedOutItemIds.length} scanned',
                          style: AppTypography.label.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Scan frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _processing ? AppColors.secondary : AppColors.tertiary,
                      width: 3,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Status messages
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _processing
                            ? 'Processing…'
                            : 'Scan items to check them out',
                        style: AppTypography.body.copyWith(color: AppColors.onPrimary),
                      ),
                      if (_lastScannedName != null && !_processing)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            'Last: $_lastScannedName',
                            style: AppTypography.body.copyWith(
                              color: AppColors.tertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body.copyWith(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                // Finish button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'FINISH CHECKOUT (${_checkedOutItemIds.length} items)',
                        style: AppTypography.label.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Checkout Result Screen ─────────────────────────────────────────────────

class _CheckoutResultScreen extends StatefulWidget {
  final CheckoutSession session;
  final Set<String> checkedOutIds;
  final List<Item> missingItems;

  const _CheckoutResultScreen({
    required this.session,
    required this.checkedOutIds,
    required this.missingItems,
  });

  @override
  State<_CheckoutResultScreen> createState() => _CheckoutResultScreenState();
}

class _CheckoutResultScreenState extends State<_CheckoutResultScreen> {
  @override
  Widget build(BuildContext context) {
    final allGood = widget.missingItems.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text('Checkout Complete'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Status icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: allGood ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                allGood ? Icons.check : Icons.warning_amber_rounded,
                color: AppColors.onPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Status text
            Text(
              allGood
                  ? 'All items checked out!'
                  : '${widget.missingItems.length} item${widget.missingItems.length == 1 ? '' : 's'} missing!',
              style: AppTypography.h1.copyWith(
                color: allGood ? AppColors.success : AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              allGood
                  ? '${widget.checkedOutIds.length} item${widget.checkedOutIds.length == 1 ? '' : 's'} scanned for "${widget.session.name}"'
                  : 'Scanned ${widget.checkedOutIds.length} item${widget.checkedOutIds.length == 1 ? '' : 's'}. The following items were not checked out:',
              style: AppTypography.body.copyWith(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            // Session info
            AppCard(
              title: 'Session: ${widget.session.name}',
              subtitle: 'Created ${widget.session.createdAt.toLocal().toString().split('.').first.substring(0, 16)}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statBadge('${widget.checkedOutIds.length}', 'Scanned', AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      _statBadge('${widget.missingItems.length}', 'Missing', widget.missingItems.isEmpty ? AppColors.secondary : AppColors.error),
                    ],
                  ),
                ],
              ),
            ),

            // Missing items list
            if (widget.missingItems.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                title: '⚠ Missing Items',
                child: Column(
                  children: widget.missingItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
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
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Actions
            AppButton(
              title: 'DONE',
              onPressed: () async {
                // Record checkout completion for review prompt
                await ReviewPrompt.recordCheckoutComplete();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              title: 'DELETE SESSION',
              variant: AppButtonVariant.ghost,
              onPressed: () async {
                await DatabaseService.deleteCheckoutSession(widget.session.id);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String number, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(number, style: AppTypography.h1.copyWith(color: color)),
            Text(label, style: AppTypography.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}