import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';

void main() {
  testWidgets('uses Material 3 light and dark themes', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('renders with the dark color scheme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Quick picks'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('navigates between the three primary phone destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Quick picks'), findsOneWidget);

    await tester.tap(find.byKey(const Key('destination-search')));
    await tester.pumpAndSettle();
    expect(find.text('Find your next favorite'), findsOneWidget);

    await tester.tap(find.byKey(const Key('destination-library')));
    await tester.pumpAndSettle();
    expect(find.text('Your library is quiet'), findsOneWidget);
  });

  testWidgets('uses a navigation rail on wide layouts', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

Widget _testApp() => YuzuApp(musicProvider: FakeMusicProvider());
