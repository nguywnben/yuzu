import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/default_dependencies.dart';
import 'package:yuzu/data/youtube_music/youtube_music_provider.dart';

void main() {
  test('production composition selects the incremental live provider', () {
    expect(createDefaultMusicProvider(), isA<YoutubeMusicProvider>());
  });
}
