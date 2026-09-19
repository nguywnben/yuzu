import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/media/track.dart';

final class LocalLibraryDatabase {
  LocalLibraryDatabase._(this._db);

  static LocalLibraryDatabase? _instance;
  final Database _db;

  static Future<LocalLibraryDatabase> getInstance({
    Database? overrideDb,
  }) async {
    if (overrideDb != null) {
      return LocalLibraryDatabase._(overrideDb);
    }
    if (_instance != null) {
      return _instance!;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yuzu_library.db');

    final db = await openDatabase(
      path,
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

        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlist_id TEXT NOT NULL,
            track_id TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            artwork_url TEXT,
            duration_ms INTEGER NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, track_id)
          )
        ''');
      },
    );

    _instance = LocalLibraryDatabase._(db);
    return _instance!;
  }

  // Favorites
  Future<void> addFavorite(Track track) async {
    await _db.insert('favorites', {
      'id': track.id,
      'title': track.title,
      'artist': track.artists.join(', '),
      'artwork_url': track.artworkUri?.toString(),
      'duration_ms': track.duration.inMilliseconds,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(String trackId) async {
    await _db.delete('favorites', where: 'id = ?', whereArgs: [trackId]);
  }

  Future<bool> isFavorite(String trackId) async {
    final res = await _db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<List<Track>> getFavorites() async {
    final res = await _db.query('favorites', orderBy: 'created_at DESC');
    return res.map((row) => _trackFromRow(row)).toList();
  }

  // History
  Future<void> recordHistory(Track track) async {
    await _db.insert('history', {
      'id': '${track.id}_${DateTime.now().millisecondsSinceEpoch}',
      'track_id': track.id,
      'title': track.title,
      'artist': track.artists.join(', '),
      'artwork_url': track.artworkUri?.toString(),
      'duration_ms': track.duration.inMilliseconds,
      'played_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Track>> getHistory({int limit = 50}) async {
    final res = await _db.query(
      'history',
      orderBy: 'played_at DESC',
      limit: limit,
    );
    return res.map((row) => _trackFromRow(row)).toList();
  }

  static Track _trackFromRow(Map<String, Object?> row) {
    final artistStr = row['artist'] as String? ?? '';
    final artists = artistStr.split(', ').where((a) => a.isNotEmpty).toList();
    final artworkStr = row['artwork_url'] as String?;
    final durationMs = (row['duration_ms'] as num?)?.toInt() ?? 0;

    return Track(
      id: (row['track_id'] ?? row['id']) as String,
      title: row['title'] as String? ?? 'Unknown',
      artists: artists.isEmpty ? const ['Unknown Artist'] : artists,
      duration: Duration(milliseconds: durationMs),
      artworkUri: artworkStr != null && artworkStr.isNotEmpty
          ? Uri.tryParse(artworkStr)
          : null,
    );
  }
}
