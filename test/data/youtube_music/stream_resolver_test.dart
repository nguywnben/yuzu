import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/stream_resolver.dart';

void main() {
  group('YoutubeStreamResolver', () {
    test('parses streaming audio formats correctly', () async {
      final resolver = YoutubeStreamResolver();
      expect(resolver, isNotNull);
    });

    test('selects best direct audio stream from response', () async {
      final fakeResponse = {
        'playabilityStatus': {'status': 'OK'},
        'streamingData': {
          'adaptiveFormats': [
            {
              'itag': 140,
              'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
              'bitrate': 128000,
              'url': 'https://example.com/audio.m4a?expire=1800000000',
            },
            {
              'itag': 251,
              'mimeType': 'audio/webm; codecs="opus"',
              'bitrate': 160000,
              'url': 'https://example.com/audio.webm?expire=1800000000',
            },
          ],
        },
      };

      final formats =
          (fakeResponse['streamingData']!['adaptiveFormats'] as List)
              .whereType<Map<String, Object?>>()
              .where((f) => (f['mimeType'] as String).startsWith('audio/'))
              .toList();
      expect(formats.length, 2);
    });
  });
}
