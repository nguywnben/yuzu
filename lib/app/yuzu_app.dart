import 'package:flutter/material.dart';

import 'shell/yuzu_shell.dart';
import 'theme/yuzu_theme.dart';

class YuzuApp extends StatelessWidget {
  const YuzuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuzu',
      debugShowCheckedModeBanner: false,
      theme: YuzuTheme.light,
      darkTheme: YuzuTheme.dark,
      themeMode: ThemeMode.system,
      home: const YuzuShell(),
    );
  }
}
