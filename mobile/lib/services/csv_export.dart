import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database.dart';

/// Exports items and their location history as a CSV file.
///
/// Only available on paying plans (Crew or Enterprise). The caller
/// is responsible for checking plan eligibility before invoking.
class CsvExportService {
  /// Export all items with their most recent location as a CSV string.
  static Future<String> generateCsv() async {
    final items = await DatabaseService.getItems();
    final buffer = StringBuffer();

    // Header row
    buffer.writeln('Name,Details,Custom Fields,Latitude,Longitude,Address,Last Seen,Created At');

    for (final item in items) {
      final locations = await DatabaseService.getItemLocations(item.id);
      final latest = locations.isNotEmpty ? locations.first : null;

      // Escape CSV fields (wrap in quotes if they contain commas or quotes)
      final name = _escapeCsv(item.name);
      final details = _escapeCsv(item.details);

      // Custom fields as "key: value; key: value"
      final fieldsStr = item.customFields.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('; ');
      final fields = _escapeCsv(fieldsStr);

      final lat = latest?.latitude?.toString() ?? '';
      final lon = latest?.longitude?.toString() ?? '';
      final address = _escapeCsv(latest?.address ?? '');
      final lastSeen = latest != null ? latest.timestamp.toIso8601String() : '';
      final createdAt = item.createdAt.toIso8601String();

      buffer.writeln('$name,$details,$fields,$lat,$lon,$address,$lastSeen,$createdAt');
    }

    return buffer.toString();
  }

  /// Generate and share the CSV file using the system share sheet.
  static Future<void> exportAndShare() async {
    final csv = await generateCsv();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${tempDir.path}/stokesdrift_export_$timestamp.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        text: 'stokesdrift inventory export — $timestamp',
        files: [XFile(file.path)],
      ),
    );
  }

  /// Escape a CSV field: wrap in double quotes if it contains
  /// commas, double quotes, or newlines.
  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}