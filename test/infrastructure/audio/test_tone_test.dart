import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/infrastructure/audio/test_tone.dart';

void main() {
  test('builds a mono 16-bit PCM WAV with the requested duration', () {
    const sampleRate = 8000;
    const duration = Duration(milliseconds: 250);

    final wav = buildYuzuTestToneWav(
      duration: duration,
      sampleRate: sampleRate,
    );
    final bytes = ByteData.sublistView(wav);

    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
    expect(ascii.decode(wav.sublist(12, 16)), 'fmt ');
    expect(bytes.getUint16(20, Endian.little), 1);
    expect(bytes.getUint16(22, Endian.little), 1);
    expect(bytes.getUint32(24, Endian.little), sampleRate);
    expect(bytes.getUint16(34, Endian.little), 16);
    expect(ascii.decode(wav.sublist(36, 40)), 'data');
    expect(bytes.getUint32(40, Endian.little), sampleRate ~/ 4 * 2);
    expect(wav.length, 44 + sampleRate ~/ 4 * 2);
  });

  test('rejects invalid tone settings', () {
    expect(
      () => buildYuzuTestToneWav(duration: Duration.zero),
      throwsArgumentError,
    );
    expect(() => buildYuzuTestToneWav(sampleRate: 0), throwsArgumentError);
  });

  test('writes and reuses the generated tone in the system cache', () async {
    final firstUri = await ensureYuzuTestToneFile();
    final secondUri = await ensureYuzuTestToneFile();
    final file = File.fromUri(firstUri);

    expect(secondUri, firstUri);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(44));
  });
}
