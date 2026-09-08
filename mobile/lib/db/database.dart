import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Models ─────────────────────────────────────────────────────────────────

class Item {
  final String id;
  final String name;
  final String details;
  final Map<String, String> customFields;
  final String qrCodeData;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    this.details = '',
    this.customFields = const {},
    required this.qrCodeData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromRow(Map<String, dynamic> m) {
    final raw = (m['custom_fields'] as String?) ?? '{}';
    Map<String, String> fields = {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          fields[key.toString()] = value.toString();
        });
      }
    } catch (_) {
      // Fallback for legacy colon-separated format
      raw.replaceAll('{', '').replaceAll('}', '').split(',').where((s) => s.trim().isNotEmpty).forEach((pair) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          fields[parts[0].trim()] = parts[1].trim();
        }
      });
    }
    return Item(
      id: m['id'] as String,
      name: m['name'] as String,
      details: (m['details'] as String?) ?? '',
      customFields: fields,
      qrCodeData: m['qr_code_data'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}

class Location {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double radius;
  final String address;
  final DateTime createdAt;

  Location({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.radius = 50,
    this.address = '',
    required this.createdAt,
  });

  factory Location.fromRow(Map<String, dynamic> m) => Location(
        id: m['id'] as String,
        name: m['name'] as String,
        latitude: m['latitude'] as double?,
        longitude: m['longitude'] as double?,
        radius: (m['radius'] as num?)?.toDouble() ?? 50,
        address: (m['address'] as String?) ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class ItemLocation {
  final String id;
  final String itemId;
  final String? locationId;
  final double? latitude;
  final double? longitude;
  final String address;
  final String notes;
  final DateTime timestamp;

  ItemLocation({
    required this.id,
    required this.itemId,
    this.locationId,
    this.latitude,
    this.longitude,
    this.address = '',
    this.notes = '',
    required this.timestamp,
  });

  factory ItemLocation.fromRow(Map<String, dynamic> m) => ItemLocation(
        id: m['id'] as String,
        itemId: m['item_id'] as String,
        locationId: m['location_id'] as String?,
        latitude: m['latitude'] as double?,
        longitude: m['longitude'] as double?,
        address: (m['address'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        timestamp: DateTime.parse(m['timestamp'] as String),
      );
}

class Stats {
  final int totalItems;
  final int totalLocations;
  final int recentScans;
  const Stats(
      {required this.totalItems,
      required this.totalLocations,
      required this.recentScans});
}

// ─── Checkout Session ──────────────────────────────────────────────────────────

class CheckoutSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? notes;

  CheckoutSession({
    required this.id,
    required this.name,
    this.notes,
    required this.createdAt,
  });

  factory CheckoutSession.fromRow(Map<String, dynamic> m) => CheckoutSession(
        id: m['id'] as String,
        name: m['name'] as String,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class CheckoutItem {
  final String id;
  final String sessionId;
  final String itemId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  CheckoutItem({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory CheckoutItem.fromRow(Map<String, dynamic> m) => CheckoutItem(
        id: m['id'] as String,
        sessionId: m['session_id'] as String,
        itemId: m['item_id'] as String,
        timestamp: DateTime.parse(m['timestamp'] as String),
        latitude: m['latitude'] as double?,
        longitude: m['longitude'] as double?,
      );
}

// ─── CRDT Database Service ──────────────────────────────────────────────────
//
// Uses sqlite_crdt for conflict-free replicated data types.
// The CRDT layer automatically adds hlc, modified, and is_deleted columns
// to every table, enabling:
//   • Soft-delete semantics (is_deleted flag)
//   • Causal ordering via Hybrid Logical Clocks (hlc)
//   • Conflict-free merge with remote nodes (getChangeset / merge)
//
// All queries filter out soft-deleted rows with `WHERE is_deleted = 0`.

class DatabaseService {
  static SqliteCrdt? _db;
  static String? _dbPath;

  /// Initialise the database with a filesystem path.
  /// Call this once before any other method, e.g. in main().
  static Future<void> init(String dbPath) async {
    _dbPath = dbPath;
    await database;
  }

  static Future<SqliteCrdt> get database async {
    if (_db != null) return _db!;
    assert(_dbPath != null, 'DatabaseService.init() must be called first');
    _db = await _openDb(_dbPath!);
    return _db!;
  }

  static Future<SqliteCrdt> _openDb(String path) async {
    // Ensure parent directory exists
    final dir = dirname(path);
    if (!await Directory(dir).exists()) {
      await Directory(dir).create(recursive: true);
    }

    return SqliteCrdt.open(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            details TEXT DEFAULT '',
            custom_fields TEXT DEFAULT '{}',
            qr_code_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE locations (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            radius REAL DEFAULT 50,
            address TEXT DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE item_locations (
            id TEXT PRIMARY KEY NOT NULL,
            item_id TEXT NOT NULL,
            location_id TEXT,
            latitude REAL,
            longitude REAL,
            address TEXT DEFAULT '',
            notes TEXT DEFAULT '',
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_item_locations_item ON item_locations(item_id)');
        await db.execute(
            'CREATE INDEX idx_item_locations_location ON item_locations(location_id)');
        await db.execute('''
          CREATE TABLE checkout_sessions (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE checkout_items (
            id TEXT PRIMARY KEY NOT NULL,
            session_id TEXT NOT NULL,
            item_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            latitude REAL,
            longitude REAL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_checkout_items_session ON checkout_items(session_id)');
        await db.execute(
            'CREATE INDEX idx_checkout_items_item ON checkout_items(item_id)');
      },
    );
  }

  // ── Item CRUD ───────────────────────────────────────────────────────────

  static Future<Item> createItem(String name, {String details = '', Map<String, String> customFields = const {}}) async {
    final db = await database;
    final id = _uuid.v4();
    final qrCodeData = 'stokesdrift://item/$id';
    final now = DateTime.now().toIso8601String();

    // Serialize custom fields
    final fieldsJson = jsonEncode(customFields);

    await db.execute(
      'INSERT INTO items (id, name, details, custom_fields, qr_code_data, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
      [id, name, details, fieldsJson, qrCodeData, now, now],
    );

    final rows = await db.query(
        'SELECT * FROM items WHERE id = ?1 AND is_deleted = 0', [id]);
    return Item.fromRow(rows.first);
  }

  static Future<List<Item>> getItems() async {
    final db = await database;
    final rows = await db.query(
        'SELECT * FROM items WHERE is_deleted = 0 ORDER BY updated_at DESC');
    return rows.map(Item.fromRow).toList();
  }

  static Future<Item?> getItemById(String id) async {
    final db = await database;
    final rows = await db.query(
        'SELECT * FROM items WHERE id = ?1 AND is_deleted = 0', [id]);
    if (rows.isEmpty) return null;
    return Item.fromRow(rows.first);
  }

  static Future<Item?> getItemByQrCode(String qrCodeData) async {
    final db = await database;
    final rows = await db.query(
        'SELECT * FROM items WHERE qr_code_data = ?1 AND is_deleted = 0',
        [qrCodeData]);
    if (rows.isEmpty) return null;
    return Item.fromRow(rows.first);
  }

  static Future<void> updateItem(
      String id, String name, String details, {Map<String, String> customFields = const {}}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final fieldsJson = jsonEncode(customFields);
    await db.execute(
      'UPDATE items SET name = ?1, details = ?2, custom_fields = ?3, updated_at = ?4 WHERE id = ?5',
      [name, details, fieldsJson, now, id],
    );
  }

  static Future<void> deleteItem(String id) async {
    // CRDT soft-delete: marks is_deleted = 1 instead of removing the row
    final db = await database;
    await db.execute(
        'UPDATE item_locations SET is_deleted = 1 WHERE item_id = ?1', [id]);
    await db.execute('UPDATE items SET is_deleted = 1 WHERE id = ?1', [id]);
  }

  // ── Location CRUD ───────────────────────────────────────────────────────

  static Future<Location> createLocation(
    String name, {
    double? latitude,
    double? longitude,
    double radius = 50,
    String address = '',
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      'INSERT INTO locations (id, name, latitude, longitude, radius, address, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
      [id, name, latitude, longitude, radius, address, now],
    );

    final rows = await db.query(
        'SELECT * FROM locations WHERE id = ?1 AND is_deleted = 0', [id]);
    return Location.fromRow(rows.first);
  }

  static Future<List<Location>> getLocations() async {
    final db = await database;
    final rows = await db.query(
        'SELECT * FROM locations WHERE is_deleted = 0 ORDER BY name ASC');
    return rows.map(Location.fromRow).toList();
  }

  static Future<void> deleteLocation(String id) async {
    final db = await database;
    await db.execute(
        'UPDATE locations SET is_deleted = 1 WHERE id = ?1', [id]);
  }

  // ── Item Locations ───────────────────────────────────────────────────────

  static Future<ItemLocation> markItemLocation(
    String itemId,
    double latitude,
    double longitude, {
    String? address,
    String notes = '',
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now();

    // Try to match an existing location by proximity
    String? locationId;
    final locations = await getLocations();
    for (final loc in locations) {
      if (loc.latitude != null && loc.longitude != null) {
        final dist = _distanceInMeters(
            latitude, longitude, loc.latitude!, loc.longitude!);
        if (dist <= loc.radius) {
          locationId = loc.id;
          break;
        }
      }
    }

    await db.execute(
      'INSERT INTO item_locations (id, item_id, location_id, latitude, longitude, address, notes, timestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)',
      [id, itemId, locationId, latitude, longitude, address ?? '', notes, now.toIso8601String()],
    );

    return ItemLocation(
      id: id,
      itemId: itemId,
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
      address: address ?? '',
      notes: notes,
      timestamp: now,
    );
  }

  static Future<ItemLocation> setItemAddress(
    String itemId,
    String address, {
    String notes = '',
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.execute(
      'INSERT INTO item_locations (id, item_id, location_id, latitude, longitude, address, notes, timestamp) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)',
      [id, itemId, null, null, null, address, notes, now.toIso8601String()],
    );

    return ItemLocation(
      id: id,
      itemId: itemId,
      locationId: null,
      latitude: null,
      longitude: null,
      address: address,
      notes: notes,
      timestamp: now,
    );
  }

  static Future<List<ItemLocation>> getItemLocations(String itemId) async {
    final db = await database;
    final rows = await db.query(
        'SELECT * FROM item_locations WHERE item_id = ?1 AND is_deleted = 0 ORDER BY timestamp DESC',
        [itemId]);
    return rows.map(ItemLocation.fromRow).toList();
  }

  static Future<List<Item>> getItemsAtLocation(String locationId) async {
    final db = await database;
    final rows = await db.query('''
      SELECT DISTINCT i.* FROM items i
      INNER JOIN item_locations il ON i.id = il.item_id
      WHERE il.location_id = ?1 AND i.is_deleted = 0 AND il.is_deleted = 0
      ORDER BY il.timestamp DESC
    ''', [locationId]);
    return rows.map(Item.fromRow).toList();
  }

  // ── Stats ───────────────────────────────────────────────────────────────

  static Future<Stats> getStats() async {
    final db = await database;
    final itemRows = await db
        .query('SELECT COUNT(*) as count FROM items WHERE is_deleted = 0');
    final locRows = await db
        .query('SELECT COUNT(*) as count FROM locations WHERE is_deleted = 0');
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final scanRows = await db.query(
        'SELECT COUNT(*) as count FROM item_locations WHERE timestamp >= ?1 AND is_deleted = 0',
        [weekAgo.toIso8601String()]);

    return Stats(
      totalItems: itemRows.first['count'] as int,
      totalLocations: locRows.first['count'] as int,
      recentScans: scanRows.first['count'] as int,
    );
  }

  // ── Checkout Sessions ─────────────────────────────────────────────────────

  /// Create a new checkout session (e.g. "Load-out from Main Stage").
  static Future<CheckoutSession> createCheckoutSession({
    String name = 'Checkout',
    String? notes,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'INSERT INTO checkout_sessions (id, name, notes, created_at) VALUES (?1, ?2, ?3, ?4)',
      [id, name, notes, now],
    );
    final rows = await db.query(
        'SELECT * FROM checkout_sessions WHERE id = ?1 AND is_deleted = 0', [id]);
    return CheckoutSession.fromRow(rows.first);
  }

  /// Record an item as scanned out in a checkout session.
  static Future<CheckoutItem> checkoutItem({
    required String sessionId,
    required String itemId,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now();
    await db.execute(
      'INSERT INTO checkout_items (id, session_id, item_id, timestamp, latitude, longitude) VALUES (?1, ?2, ?3, ?4, ?5, ?6)',
      [id, sessionId, itemId, now.toIso8601String(), latitude, longitude],
    );
    return CheckoutItem(
      id: id,
      sessionId: sessionId,
      itemId: itemId,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Get all items checked out in a session.
  static Future<List<CheckoutItem>> getCheckoutItems(String sessionId) async {
    final db = await database;
    final rows = await db.query(
        'SELECT * FROM checkout_items WHERE session_id = ?1 AND is_deleted = 0 ORDER BY timestamp ASC',
        [sessionId]);
    return rows.map(CheckoutItem.fromRow).toList();
  }

  /// Get the set of item IDs checked out in a session.
  static Future<Set<String>> getCheckedOutItemIds(String sessionId) async {
    final items = await getCheckoutItems(sessionId);
    return items.map((ci) => ci.itemId).toSet();
  }

  /// Delete a checkout session and its items.
  static Future<void> deleteCheckoutSession(String sessionId) async {
    final db = await database;
    await db.execute(
        'UPDATE checkout_items SET is_deleted = 1 WHERE session_id = ?1', [sessionId]);
    await db.execute(
        'UPDATE checkout_sessions SET is_deleted = 1 WHERE id = ?1', [sessionId]);
  }

  // ── CRDT Sync ───────────────────────────────────────────────────────────

  /// Returns the canonical HLC timestamp for the entire database.
  /// Useful for determining if a sync is needed.
  static Future<String> getCanonicalTime() async {
    final db = await database;
    return db.canonicalTime.toString();
  }

  /// Returns the changeset for all tables since the given HLC timestamp.
  /// Used for syncing with a remote server or peer.
  static Future<CrdtChangeset> getChangeset({Hlc? modifiedAfter}) async {
    final db = await database;
    return db.getChangeset(modifiedAfter: modifiedAfter);
  }

  /// Merges a changeset from a remote source into the local database.
  /// CRDT conflict resolution is handled automatically via HLC ordering.
  static Future<void> merge(CrdtChangeset changeset) async {
    final db = await database;
    await db.merge(changeset);
  }

  // ── Utility ─────────────────────────────────────────────────────────────

  static double _distanceInMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}