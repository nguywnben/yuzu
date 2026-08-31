import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/domain/media/track.dart';
import 'package:yuzu/features/shared/track_widgets.dart';

void main() {
  testWidgets('TrackArtwork renders validated remote artwork when available', (
    tester,
  ) async {
    final track = Track(
      id: 'remote-artwork-track',
      title: 'Citrus Morning',
      artists: const ['Yuzu Studio'],
      duration: const Duration(minutes: 3),
      artworkUri: Uri.https('images.example.invalid', '/citrus.jpg'),
    );

    await tester.pumpWidget(
      MaterialApp(home: TrackArtwork(track: track, size: 100)),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect(
      (image.image as NetworkImage).url,
      'https://images.example.invalid/citrus.jpg',
    );
  });

  testWidgets('TrackArtwork keeps the Material fallback without artwork', (
    tester,
  ) async {
    final track = Track(
      id: 'fallback-artwork-track',
      title: 'Paper Horizon',
      artists: const ['North Window'],
      duration: const Duration(minutes: 4),
    );

    await tester.pumpWidget(
      MaterialApp(home: TrackArtwork(track: track, size: 100)),
    );

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
