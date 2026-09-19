import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

final class ResolvedStream {
  const ResolvedStream({
    required this.uri,
    required this.bitrate,
    required this.mimeType,
    required this.expiresAt,
    this.headers = const {},
  });

  final Uri uri;
  final int bitrate;
  final String mimeType;
  final DateTime expiresAt;
  final Map<String, String> headers;
}

abstract interface class StreamResolver {
  Future<ResolvedStream> resolve(String mediaId);
}

final class YoutubeStreamResolver implements StreamResolver {
  YoutubeStreamResolver({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static final Uri _playerUri = Uri.https(
    'www.youtube.com',
    '/youtubei/v1/player',
  );
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  @override
  Future<ResolvedStream> resolve(String mediaId) async {
    final payload = {
      'context': {
        'client': {
          'clientName': 'ANDROID_VR',
          'clientVersion': '1.65.10',
          'hl': 'en',
          'gl': 'US',
        },
      },
      'videoId': mediaId,
    };

    final response = await _client
        .post(
          _playerUri,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': _userAgent,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve stream: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, Object?>;
    final playability = data['playabilityStatus'] as Map<String, Object?>?;
    final status = playability?['status'] as String?;
    if (status != 'OK') {
      final reason = playability?['reason'] as String? ?? 'Content unplayable';
      throw Exception('Playback not allowed: $reason');
    }

    final streamingData = data['streamingData'] as Map<String, Object?>?;
    if (streamingData == null) {
      throw Exception('No streaming data found');
    }

    final rawFormats = streamingData['adaptiveFormats'] as List<Object?>?;
    if (rawFormats == null || rawFormats.isEmpty) {
      throw Exception('No adaptive formats available');
    }

    final formats = rawFormats.whereType<Map<String, Object?>>().toList();

    final audioFormats = formats.where((f) {
      final mime = f['mimeType'] as String? ?? '';
      final url = f['url'] as String?;
      return mime.startsWith('audio/') && url != null && url.isNotEmpty;
    }).toList();

    if (audioFormats.isEmpty) {
      throw Exception('No direct audio format found');
    }

    audioFormats.sort((a, b) {
      final aBitrate = (a['bitrate'] as num?)?.toInt() ?? 0;
      final bBitrate = (b['bitrate'] as num?)?.toInt() ?? 0;
      return bBitrate.compareTo(aBitrate);
    });

    final chosen = audioFormats.first;
    final streamUrl = chosen['url'] as String;
    final bitrate = (chosen['bitrate'] as num?)?.toInt() ?? 128000;
    final mimeType = chosen['mimeType'] as String? ?? 'audio/mp4';

    final streamUri = Uri.parse(streamUrl);
    final expireParam = streamUri.queryParameters['expire'];
    final expiresAt = expireParam != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(expireParam) * 1000)
        : DateTime.now().add(const Duration(hours: 4));

    return ResolvedStream(
      uri: streamUri,
      bitrate: bitrate,
      mimeType: mimeType,
      expiresAt: expiresAt,
      headers: const {'User-Agent': _userAgent},
    );
  }
}
