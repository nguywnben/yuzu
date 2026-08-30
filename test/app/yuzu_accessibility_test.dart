import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';

void main() {
  testWidgets('Home meets Android minimum tap target sizes', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Home labels every tappable semantics node', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Home text meets minimum contrast', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(YuzuApp(musicProvider: FakeMusicProvider()));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
}
