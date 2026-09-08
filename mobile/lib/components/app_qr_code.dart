import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/theme.dart';

class AppQrCode extends StatelessWidget {
  final String value;
  final double size;

  const AppQrCode({super.key, required this.value, this.size = 200});

  /// Capture the QR code as an image, save to a temp file, and share.
  static Future<void> shareQrCode(GlobalKey qrKey, String itemName) async {
    try {
      final boundary =
          qrKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/stokesdrift_qr_$itemName.png');
      await file.writeAsBytes(buffer);

      await SharePlus.instance.share(
        ShareParams(
          text: 'QR code for $itemName',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      // Silently fail — callers can show their own snackbar if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: QrImageView(
        data: value,
        size: size,
        backgroundColor: AppColors.surface,
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.primary,
        ),
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.primary,
        ),
      ),
    );
  }
}