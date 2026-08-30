import 'package:flutter_test/flutter_test.dart';
import 'package:yuzu/data/fake/fake_music_provider.dart';
import 'package:yuzu/features/search/search_view_model.dart';

void main() {
  group('SearchViewModel', () {
    test('keeps a blank query idle', () async {
      final viewModel = SearchViewModel(FakeMusicProvider());

      await viewModel.search('   ');

      expect(viewModel.status, SearchStatus.idle);
      expect(viewModel.results, isEmpty);
    });

    test('moves from loading to results', () async {
      final viewModel = SearchViewModel(
        FakeMusicProvider(responseDelay: const Duration(milliseconds: 1)),
      );

      final request = viewModel.search('sunrise');
      expect(viewModel.status, SearchStatus.loading);

      await request;
      expect(viewModel.status, SearchStatus.ready);
      expect(viewModel.results.single.id, 'sunrise-drive');
    });

    test('distinguishes no matches from provider failure', () async {
      final emptyViewModel = SearchViewModel(FakeMusicProvider());
      final failingViewModel = SearchViewModel(
        FakeMusicProvider(scenario: FakeCatalogScenario.failure),
      );

      await emptyViewModel.search('not-in-catalog');
      await failingViewModel.search('sunrise');

      expect(emptyViewModel.status, SearchStatus.empty);
      expect(failingViewModel.status, SearchStatus.failure);
      expect(failingViewModel.errorMessage, isNotEmpty);
    });
  });
}
