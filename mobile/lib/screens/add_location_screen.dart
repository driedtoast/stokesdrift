import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/theme.dart';
import '../db/database.dart';
import '../components/components.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController(text: '50');
  bool _useGps = false;
  bool _saving = false;

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      double? latitude;
      double? longitude;

      if (_useGps) {
        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        latitude = position.latitude;
        longitude = position.longitude;
      }

      await DatabaseService.createLocation(
        _nameController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        radius: double.tryParse(_radiusController.text) ?? 50,
        address: _addressController.text.trim(),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleGps() async {
    if (!_useGps) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        setState(() => _useGps = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is needed to use GPS.')),
          );
        }
      }
    } else {
      setState(() => _useGps = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(title: const Text('Add Location')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LOCATION NAME', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Main Stage, Warehouse B'),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('ADDRESS (OPTIONAL)', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(hintText: 'e.g. 123 Main St, City, State'),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('PROXIMITY RADIUS (METERS)', style: AppTypography.label.copyWith(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '50'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Items scanned within this radius will be automatically assigned to this location.',
                style: AppTypography.body.copyWith(color: AppColors.secondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _toggleGps,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _useGps ? AppColors.secondary : Colors.transparent,
                    side: const BorderSide(color: AppColors.secondary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    _useGps ? '✓ GPS WILL BE USED' : 'USE CURRENT GPS',
                    style: AppTypography.label.copyWith(
                      color: _useGps ? AppColors.onPrimary : AppColors.secondary,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              AppButton(
                title: 'CREATE LOCATION',
                onPressed: _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}