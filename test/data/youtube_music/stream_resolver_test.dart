import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/youtube_music/stream_resolver.dart';

void main() {
  group('YoutubeStreamResolver', () {
    test('instantiates successfully', () {
      final resolver = YoutubeStreamResolver();
      expect(resolver, isNotNull);
    });

    test('resolved stream properties are correct', () {
      final stream = ResolvedStream(
        uri: Uri.parse('https://example.com/audio.webm'),
        bitrate: 160000,
        mimeType: 'audio/webm; codecs="opus"',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(stream.bitrate, 160000);
      expect(stream.isExpired, isFalse);
    });
  });
}
