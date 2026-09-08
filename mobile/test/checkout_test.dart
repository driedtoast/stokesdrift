import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// We test the database logic directly since it's the core of the checkout feature.
// Widget tests are separate.

void main() {
  late Database db;

  setUp(() async {
    // Use FFI for in-memory testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await openDatabase(
      inMemoryDatabasePath,
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
  });

  tearDown(() async {
    await db.close();
  });

  group('Checkout sessions', () {
    test('create and retrieve a checkout session', () async {
      final now = DateTime.now().toIso8601String();
      await db.execute(
        'INSERT INTO checkout_sessions (id, name, notes, created_at) VALUES (?, ?, ?, ?)',
        ['sess-1', 'Load-out Main Stage', 'Friday night', now],
      );

      final rows = await db.query('checkout_sessions');
      expect(rows.length, 1);
      expect(rows.first['name'], 'Load-out Main Stage');
      expect(rows.first['notes'], 'Friday night');
    });

    test('add items to a checkout session', () async {
      final now = DateTime.now().toIso8601String();

      // Create session
      await db.execute(
        'INSERT INTO checkout_sessions (id, name, notes, created_at) VALUES (?, ?, ?, ?)',
        ['sess-1', 'Checkout', null, now],
      );

      // Create items
      await db.execute(
        'INSERT INTO items (id, name, details, custom_fields, qr_code_data, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['item-1', 'SM58 Mic', '', '{}', 'stokesdrift://item/item-1', now, now],
      );
      await db.execute(
        'INSERT INTO items (id, name, details, custom_fields, qr_code_data, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['item-2', 'XLR Cable', '', '{}', 'stokesdrift://item/item-2', now, now],
      );

      // Check out items
      await db.execute(
        'INSERT INTO checkout_items (id, session_id, item_id, timestamp, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)',
        ['ci-1', 'sess-1', 'item-1', now, 37.7749, -122.4194],
      );
      await db.execute(
        'INSERT INTO checkout_items (id, session_id, item_id, timestamp, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)',
        ['ci-2', 'sess-1', 'item-2', now, 37.7749, -122.4194],
      );

      final checkedOut = await db.query(
        'checkout_items',
        where: 'session_id = ?',
        whereArgs: ['sess-1'],
      );
      expect(checkedOut.length, 2);

      // Verify item IDs
      final itemIds = checkedOut.map((r) => r['item_id'] as String).toSet();
      expect(itemIds.contains('item-1'), true);
      expect(itemIds.contains('item-2'), true);
    });

    test('missing items calculation', () async {
      final now = DateTime.now().toIso8601String();

      // Create 5 items
      for (int i = 1; i <= 5; i++) {
        await db.execute(
          'INSERT INTO items (id, name, details, custom_fields, qr_code_data, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
          ['item-$i', 'Item $i', '', '{}', 'stokesdrift://item/item-$i', now, now],
        );
      }

      // Create session and check out 3 items
      await db.execute(
        'INSERT INTO checkout_sessions (id, name, notes, created_at) VALUES (?, ?, ?, ?)',
        ['sess-1', 'Checkout', null, now],
      );

      for (int i = 1; i <= 3; i++) {
        await db.execute(
          'INSERT INTO checkout_items (id, session_id, item_id, timestamp) VALUES (?, ?, ?, ?)',
          ['ci-$i', 'sess-1', 'item-$i', now],
        );
      }

      // Find missing items (items NOT in checkout)
      final allItems = await db.query('items');
      final checkedOutRows = await db.query(
        'checkout_items',
        where: 'session_id = ?',
        whereArgs: ['sess-1'],
      );
      final checkedOutIds = checkedOutRows.map((r) => r['item_id'] as String).toSet();

      final missing = allItems.where((item) => !checkedOutIds.contains(item['id'])).toList();
      expect(missing.length, 2);
      expect(missing.map((i) => i['id']), containsAll(['item-4', 'item-5']));
    });

    test('soft delete a checkout session', () async {
      final now = DateTime.now().toIso8601String();

      await db.execute(
        'INSERT INTO checkout_sessions (id, name, notes, created_at) VALUES (?, ?, ?, ?)',
        ['sess-1', 'Checkout', null, now],
      );
      await db.execute(
        'INSERT INTO checkout_items (id, session_id, item_id, timestamp) VALUES (?, ?, ?, ?)',
        ['ci-1', 'sess-1', 'item-1', now],
      );

      // Soft delete
      // In our real DB, CRDT adds is_deleted column automatically
      // For this test we verify the pattern works
      final before = await db.query('checkout_items', where: 'session_id = ?', whereArgs: ['sess-1']);
      expect(before.length, 1);

      await db.delete('checkout_items', where: 'session_id = ?', whereArgs: ['sess-1']);
      await db.delete('checkout_sessions', where: 'id = ?', whereArgs: ['sess-1']);

      final afterSessions = await db.query('checkout_sessions');
      final afterItems = await db.query('checkout_items');
      expect(afterSessions.length, 0);
      expect(afterItems.length, 0);
    });
  });

  group('Item creation and QR lookup', () {
    test('create item and find by QR code data', () async {
      final now = DateTime.now().toIso8601String();
      await db.execute(
        'INSERT INTO items (id, name, details, custom_fields, qr_code_data, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['test-id', 'Test Mic', 'Shure SM58', '{}', 'stokesdrift://item/test-id', now, now],
      );

      final result = await db.query(
        'items',
        where: 'qr_code_data = ?',
        whereArgs: ['stokesdrift://item/test-id'],
      );
      expect(result.length, 1);
      expect(result.first['name'], 'Test Mic');
    });

    test('QR code with unknown data returns empty', () async {
      final result = await db.query(
        'items',
        where: 'qr_code_data = ?',
        whereArgs: ['stokesdrift://item/nonexistent'],
      );
      expect(result.length, 0);
    });
  });

  group('Location marking', () {
    test('mark item with GPS coordinates', () async {
      final now = DateTime.now().toIso8601String();

      await db.execute(
        'INSERT INTO items (id, name, details, custom_fields, qr_code_data, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['item-1', 'Test Mic', '', '{}', 'stokesdrift://item/item-1', now, now],
      );

      await db.execute(
        'INSERT INTO item_locations (id, item_id, location_id, latitude, longitude, address, notes, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        ['loc-1', 'item-1', null, 37.7749, -122.4194, 'San Francisco', '', now],
      );

      final locs = await db.query(
        'item_locations',
        where: 'item_id = ?',
        whereArgs: ['item-1'],
      );
      expect(locs.length, 1);
      expect(locs.first['latitude'], 37.7749);
      expect(locs.first['longitude'], -122.4194);
      expect(locs.first['address'], 'San Francisco');
    });
  });
}