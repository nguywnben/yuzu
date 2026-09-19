import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:yuzu/data/local/local_library_database.dart';
import 'package:yuzu/domain/media/track.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('LocalLibraryDatabase', () {
    late Database memoryDb;
    late LocalLibraryDatabase libraryDb;

    setUp(() async {
      memoryDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE favorites (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              artwork_url TEXT,
              duration_ms INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE history (
              id TEXT PRIMARY KEY,
              track_id TEXT NOT NULL,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              artwork_url TEXT,
              duration_ms INTEGER NOT NULL,
              played_at INTEGER NOT NULL
            )
          ''');
        },
      );
      libraryDb = await LocalLibraryDatabase.getInstance(overrideDb: memoryDb);
    });

    tearDown(() async {
      await memoryDb.close();
    });

    final testTrack = Track(
      id: 'track-123',
      title: 'Smells Like Teen Spirit',
      artists: const ['Nirvana'],
      duration: const Duration(minutes: 5, seconds: 1),
    );

    test('can add and query favorites', () async {
      expect(await libraryDb.isFavorite(testTrack.id), isFalse);

      await libraryDb.addFavorite(testTrack);
      expect(await libraryDb.isFavorite(testTrack.id), isTrue);

      final favorites = await libraryDb.getFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.title, testTrack.title);
      expect(favorites.first.artists, testTrack.artists);

      await libraryDb.removeFavorite(testTrack.id);
      expect(await libraryDb.isFavorite(testTrack.id), isFalse);
    });

    test('can record and query playback history', () async {
      await libraryDb.recordHistory(testTrack);

      final history = await libraryDb.getHistory();
      expect(history.length, 1);
      expect(history.first.id, testTrack.id);
      expect(history.first.title, testTrack.title);
    });
  });
}
