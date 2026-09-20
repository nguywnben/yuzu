import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/media/track.dart';

final class YoutubePlaylistService {
  YoutubePlaylistService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Track>> fetchPlaylistTracks(String playlistId) async {
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    final uri = Uri.https('music.youtube.com', '/youtubei/v1/browse');
    final payload = {
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': '1.20240909.01.00',
          'hl': 'en',
          'gl': 'US',
        },
      },
      'browseId': browseId,
    };

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        'Referer': 'https://music.youtube.com/',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tracks = <Track>[];

    void extractFromSection(Map<String, dynamic>? shelf) {
      if (shelf == null) return;
      final contents = shelf['contents'] as List? ?? [];
      for (final item in contents) {
        if (item is! Map<String, dynamic>) continue;
        final r =
            item['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
        if (r == null) continue;
        final flexCols = r['flexColumns'] as List? ?? [];
        if (flexCols.isEmpty) continue;

        final firstCol = flexCols[0] as Map<String, dynamic>?;
        final firstRenderer =
            firstCol?['musicResponsiveListItemFlexColumnRenderer']
                as Map<String, dynamic>?;
        final firstText = firstRenderer?['text'] as Map<String, dynamic>?;
        final titleRuns = firstText?['runs'] as List? ?? [];
        if (titleRuns.isEmpty) continue;

        final firstRun = titleRuns[0] as Map<String, dynamic>?;
        final title = firstRun?['text'] as String?;
        final navEndpoint =
            firstRun?['navigationEndpoint'] as Map<String, dynamic>?;
        final watchEndpoint =
            navEndpoint?['watchEndpoint'] as Map<String, dynamic>?;
        final videoId = watchEndpoint?['videoId'] as String?;

        if (title == null || videoId == null || videoId.isEmpty) continue;

        var artist = 'Unknown';
        if (flexCols.length > 1) {
          final secondCol = flexCols[1] as Map<String, dynamic>?;
          final secondRenderer =
              secondCol?['musicResponsiveListItemFlexColumnRenderer']
                  as Map<String, dynamic>?;
          final secondText = secondRenderer?['text'] as Map<String, dynamic>?;
          final subtitleRuns = secondText?['runs'] as List? ?? [];
          if (subtitleRuns.isNotEmpty) {
            final firstSubRun = subtitleRuns[0] as Map<String, dynamic>?;
            artist = firstSubRun?['text'] as String? ?? 'Unknown';
          }
        }

        final thumbRenderer = r['thumbnail'] as Map<String, dynamic>?;
        final musicThumb =
            thumbRenderer?['musicThumbnailRenderer'] as Map<String, dynamic>?;
        final thumbObj = musicThumb?['thumbnail'] as Map<String, dynamic>?;
        final thumbs = thumbObj?['thumbnails'] as List? ?? [];
        String? artworkUrl;
        if (thumbs.isNotEmpty) {
          final lastThumb = thumbs.last as Map<String, dynamic>?;
          artworkUrl = lastThumb?['url'] as String?;
        }

        tracks.add(
          Track(
            id: videoId,
            title: title,
            artists: [artist],
            duration: const Duration(minutes: 3),
            artworkUri: artworkUrl != null ? Uri.tryParse(artworkUrl) : null,
          ),
        );
      }
    }

    try {
      final contentsMap = data['contents'] as Map<String, dynamic>?;
      final twoCol =
          contentsMap?['twoColumnBrowseResultsRenderer']
              as Map<String, dynamic>?;
      final secondary = twoCol?['secondaryContents'] as Map<String, dynamic>?;
      final secSectionList =
          secondary?['sectionListRenderer'] as Map<String, dynamic>?;
      final secSections = secSectionList?['contents'] as List? ?? [];
      for (final s in secSections) {
        if (s is Map<String, dynamic>) {
          extractFromSection(
            s['musicPlaylistShelfRenderer'] as Map<String, dynamic>?,
          );
        }
      }

      final tabs = twoCol?['tabs'] as List? ?? [];
      for (final t in tabs) {
        if (t is Map<String, dynamic>) {
          final tabRenderer = t['tabRenderer'] as Map<String, dynamic>?;
          final content = tabRenderer?['content'] as Map<String, dynamic>?;
          final priSectionList =
              content?['sectionListRenderer'] as Map<String, dynamic>?;
          final priSections = priSectionList?['contents'] as List? ?? [];
          for (final s in priSections) {
            if (s is Map<String, dynamic>) {
              extractFromSection(
                s['musicPlaylistShelfRenderer'] as Map<String, dynamic>?,
              );
            }
          }
        }
      }
    } catch (_) {}

    return tracks;
  }
}
