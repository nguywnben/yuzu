import 'dart:convert';

import 'package:http/http.dart' as http;

final class LyricsLine {
  const LyricsLine({required this.time, required this.text});

  final Duration time;
  final String text;
}

final class SyncedLyrics {
  const SyncedLyrics({required this.lines, required this.isSynced});

  final List<LyricsLine> lines;
  final bool isSynced;
}

abstract interface class LyricsProvider {
  Future<SyncedLyrics?> fetchLyrics({
    required String trackName,
    required String artistName,
    Duration? duration,
  });
}

final class LrcLibLyricsProvider implements LyricsProvider {
  LrcLibLyricsProvider({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<SyncedLyrics?> fetchLyrics({
    required String trackName,
    required String artistName,
    Duration? duration,
  }) async {
    final queryParams = {
      'track_name': trackName,
      'artist_name': artistName,
      if (duration != null) 'duration': duration.inSeconds.toString(),
    };

    final uri = Uri.https('lrclib.net', '/api/get', queryParams);
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final syncedText = data['syncedLyrics'] as String?;
      final plainText = data['plainLyrics'] as String?;

      if (syncedText != null && syncedText.isNotEmpty) {
        final lines = parseLrc(syncedText);
        if (lines.isNotEmpty) {
          return SyncedLyrics(lines: lines, isSynced: true);
        }
      }

      if (plainText != null && plainText.isNotEmpty) {
        final lines = plainText
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .map((l) => LyricsLine(time: Duration.zero, text: l.trim()))
            .toList();
        return SyncedLyrics(lines: lines, isSynced: false);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static List<LyricsLine> parseLrc(String lrc) {
    final lines = <LyricsLine>[];
    final regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final rawLine in lrc.split('\n')) {
      final match = regExp.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisPart = match.group(3)!;
        final millis = millisPart.length == 2
            ? int.parse(millisPart) * 10
            : int.parse(millisPart);
        final text = match.group(4)!.trim();

        lines.add(
          LyricsLine(
            time: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: millis,
            ),
            text: text,
          ),
        );
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
