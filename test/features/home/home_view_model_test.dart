import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/features/home/home_view_model.dart';

void main() {
  group('HomeViewModel', () {
    test('moves from loading to ready with home sections', () async {
      final viewModel = HomeViewModel(
        FakeMusicProvider(responseDelay: const Duration(milliseconds: 1)),
      );

      final request = viewModel.load();
      expect(viewModel.status, HomeStatus.loading);

      await request;
      expect(viewModel.status, HomeStatus.ready);
      expect(viewModel.sections.first.id, 'quick-picks');
    });

    test('exposes an empty state', () async {
      final viewModel = HomeViewModel(
        FakeMusicProvider(scenario: FakeCatalogScenario.empty),
      );

      await viewModel.load();

      expect(viewModel.status, HomeStatus.empty);
      expect(viewModel.sections, isEmpty);
    });

    test('exposes a retryable error state', () async {
      final viewModel = HomeViewModel(
        FakeMusicProvider(scenario: FakeCatalogScenario.failure),
      );

      await viewModel.load();

      expect(viewModel.status, HomeStatus.failure);
      expect(viewModel.errorMessage, isNotEmpty);
    });
  });
}
