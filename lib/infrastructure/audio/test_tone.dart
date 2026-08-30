import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const yuzuTestToneDuration = Duration(seconds: 30);

Future<Uri> ensureYuzuTestToneFile() async {
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}'
    'yuzu_test_tone_v1.wav',
  );
  if (!await file.exists()) {
    await file.writeAsBytes(
      buildYuzuTestToneWav(duration: yuzuTestToneDuration),
      flush: true,
    );
  }
  return file.uri;
}

Uint8List buildYuzuTestToneWav({
  Duration duration = yuzuTestToneDuration,
  int sampleRate = 22050,
}) {
  if (duration <= Duration.zero) {
    throw ArgumentError.value(duration, 'duration', 'must be positive');
  }
  if (sampleRate <= 0) {
    throw ArgumentError.value(sampleRate, 'sampleRate', 'must be positive');
  }

  final sampleCount = duration.inMicroseconds * sampleRate ~/ 1000000;
  const bytesPerSample = 2;
  const headerLength = 44;
  final dataLength = sampleCount * bytesPerSample;
  final bytes = ByteData(headerLength + dataLength);

  _writeAscii(bytes, 0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  _writeAscii(bytes, 8, 'WAVE');
  _writeAscii(bytes, 12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * bytesPerSample, Endian.little);
  bytes.setUint16(32, bytesPerSample, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  _writeAscii(bytes, 36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);

  const melody = [261.63, 329.63, 392.00, 523.25];
  for (var index = 0; index < sampleCount; index++) {
    final seconds = index / sampleRate;
    final note = melody[(seconds ~/ 2) % melody.length];
    final fade = _fade(seconds, duration.inMicroseconds / 1000000);
    final sample = math.sin(2 * math.pi * note * seconds) * 0.18 * fade * 32767;
    bytes.setInt16(
      headerLength + index * bytesPerSample,
      sample.round(),
      Endian.little,
    );
  }

  return bytes.buffer.asUint8List();
}

double _fade(double seconds, double totalSeconds) {
  const fadeSeconds = 0.08;
  final fadeIn = math.min(1.0, seconds / fadeSeconds);
  final fadeOut = math.min(1.0, (totalSeconds - seconds) / fadeSeconds);
  return math.max(0.0, math.min(fadeIn, fadeOut));
}

void _writeAscii(ByteData bytes, int offset, String value) {
  for (var index = 0; index < value.length; index++) {
    bytes.setUint8(offset + index, value.codeUnitAt(index));
  }
}
