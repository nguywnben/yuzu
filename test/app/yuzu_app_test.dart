import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/app/yuzu_app.dart';

void main() {
  testWidgets('uses Material 3 light and dark themes', (tester) async {
    await tester.pumpWidget(const YuzuApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('renders with the dark color scheme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const YuzuApp());

    final context = tester.element(find.text('Listen again'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('navigates between the three primary phone destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const YuzuApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Listen again'), findsOneWidget);

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

    await tester.pumpWidget(const YuzuApp());

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
