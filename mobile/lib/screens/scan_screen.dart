import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import 'item_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _processing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkGpsPermission();
  }

  Future<void> _checkGpsPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Will request when user scans
      setState(() {
        _errorMessage = null;
      });
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permission is permanently denied. Enable it in Settings to mark item locations automatically.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || _processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() {
      _scanned = true;
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
          _scanned = false;
          _processing = false;
        });
      }
      return;
    }

    // Try to get GPS and mark location
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        await DatabaseService.markItemLocation(
          item.id,
          position.latitude,
          position.longitude,
        );
      } else {
        // GPS denied — still navigate to item but warn
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS permission denied. Location not recorded. Enable in Settings for automatic tracking.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (_) {
      // GPS not available, proceed without it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get GPS location. Item found but location not recorded.')),
        );
      }
    }

    if (mounted) {
      _controller.stop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
      ).then((_) {
        // When coming back, reset scanner
        if (mounted) {
          setState(() {
            _scanned = false;
            _processing = false;
            _errorMessage = null;
          });
          _controller.start();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scan frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tertiary, width: 3),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _processing ? 'Processing…' : 'Point the camera at a QR code',
                    style: AppTypography.body.copyWith(color: AppColors.onPrimary),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.body.copyWith(color: AppColors.onPrimary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (_scanned && !_processing) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => setState(() {
                      _scanned = false;
                      _errorMessage = null;
                    }),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.tertiary,
                    ),
                    child: const Text('TAP TO SCAN AGAIN'),
                  ),
                ],
              ],
            ),
          ),
          // Close button — switches tab instead of popping
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.sm,
            child: SafeArea(
              child: IconButton(
                onPressed: () {
                  // Reset state when leaving scan
                  setState(() {
                    _scanned = false;
                    _processing = false;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.close, color: AppColors.onPrimary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}