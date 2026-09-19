import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/features/lyrics/lyrics_provider.dart';

void main() {
  group('LrcLibLyricsProvider', () {
    test('parseLrc correctly parses timestamps and text', () {
      const sampleLrc = '''
[00:12.34]First line of lyrics
[01:05.678]Second line after one minute
[02:15.00]Third line ending
''';

      final lines = LrcLibLyricsProvider.parseLrc(sampleLrc);
      expect(lines.length, 3);
      expect(lines[0].text, 'First line of lyrics');
      expect(lines[0].time, const Duration(seconds: 12, milliseconds: 340));
      expect(lines[1].text, 'Second line after one minute');
      expect(
        lines[1].time,
        const Duration(minutes: 1, seconds: 5, milliseconds: 678),
      );
      expect(lines[2].text, 'Third line ending');
      expect(lines[2].time, const Duration(minutes: 2, seconds: 15));
    });
  });
}
