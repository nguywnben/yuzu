import 'dart:async';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

abstract interface class StreamResolver {
  Future<ResolvedStream> resolve(String mediaId);
}

final class YoutubeStreamResolver implements StreamResolver {
  YoutubeStreamResolver({YoutubeExplode? client})
    : _client = client ?? YoutubeExplode();

  final YoutubeExplode _client;
  final Map<String, ResolvedStream> _cache = {};

  static const _androidUserAgent =
      'com.google.android.youtube/19.43.38 (Linux; U; Android 14; en_US; Pixel 7 Pro; Build/UQ1A.240105.004; Cronet/129.0.6668.70)';

  @override
  Future<ResolvedStream> resolve(String mediaId) async {
    final cached = _cache[mediaId];
    if (cached != null && !cached.isExpired) {
      return cached;
    }

    try {
      final manifest = await _client.videos.streams.getManifest(mediaId);
      final audioStream = manifest.audioOnly.withHighestBitrate();

      final resolved = ResolvedStream(
        uri: audioStream.url,
        bitrate: audioStream.bitrate.bitsPerSecond,
        mimeType:
            '${audioStream.container.name}; codecs="${audioStream.audioCodec}"',
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
        headers: const {
          'User-Agent': _androidUserAgent,
        },
      );

      _cache[mediaId] = resolved;
      return resolved;
    } catch (error) {
      throw Exception('Failed to resolve audio stream for $mediaId: $error');
    }
  }

  void dispose() {
    _client.close();
  }
}
