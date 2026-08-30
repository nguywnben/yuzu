import 'package:flutter/material.dart';

import '../data/fake/fake_music_provider.dart';
import '../domain/media/music_provider.dart';
import '../features/player/memory_playback_driver.dart';
import '../features/player/playback_driver.dart';
import 'shell/yuzu_shell.dart';
import 'theme/yuzu_theme.dart';

class YuzuApp extends StatelessWidget {
  const YuzuApp({super.key, this.musicProvider, this.playbackDriver});

  final MusicProvider? musicProvider;
  final PlaybackDriver? playbackDriver;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuzu',
      debugShowCheckedModeBanner: false,
      theme: YuzuTheme.light,
      darkTheme: YuzuTheme.dark,
      themeMode: ThemeMode.system,
      home: YuzuShell(
        musicProvider:
            musicProvider ??
            FakeMusicProvider(responseDelay: const Duration(milliseconds: 250)),
        playbackDriver: playbackDriver ?? MemoryPlaybackDriver(),
      ),
    );
  }
}
