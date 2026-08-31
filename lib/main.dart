import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'app/default_dependencies.dart';
import 'app/yuzu_app.dart';
import 'platform/audio/yuzu_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await AudioService.init<YuzuAudioHandler>(
    builder: YuzuAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'dev.yuzu.yuzu.audio',
      androidNotificationChannelName: 'Yuzu playback',
      androidNotificationOngoing: false,
    ),
  );
  runApp(
    YuzuApp(
      musicProvider: createDefaultMusicProvider(),
      playbackDriver: audioHandler,
    ),
  );
}
