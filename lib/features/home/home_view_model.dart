import 'package:flutter/foundation.dart';

import '../../domain/media/home_section.dart';
import '../../domain/media/music_provider.dart';
import '../../domain/media/search_result.dart';

enum HomeStatus { idle, loading, ready, empty, failure }

final class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._musicProvider);

  final MusicProvider _musicProvider;

  HomeStatus _status = HomeStatus.idle;
  List<HomeSection> _sections = const [];
  String _errorMessage = '';
  String _loadMoreErrorMessage = '';
  String? _continuationToken;
  bool _isLoadingMore = false;
  final Set<String> _requestedContinuationTokens = {};

  HomeStatus get status => _status;
  List<HomeSection> get sections => _sections;
  String get errorMessage => _errorMessage;
  String get loadMoreErrorMessage => _loadMoreErrorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _continuationToken != null;

  Future<void> load() async {
    _status = HomeStatus.loading;
    _sections = const [];
    _errorMessage = '';
    _loadMoreErrorMessage = '';
    _continuationToken = null;
    _isLoadingMore = false;
    _requestedContinuationTokens.clear();
    notifyListeners();

    try {
      final page = await _musicProvider.fetchHome();
      _sections = List.unmodifiable(page.sections);
      _continuationToken = page.continuationToken;
      _status = page.sections.isEmpty ? HomeStatus.empty : HomeStatus.ready;
    } on MusicProviderException {
      _sections = const [];
      _status = HomeStatus.failure;
      _errorMessage = 'Unable to load music right now.';
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final token = _continuationToken;
    if (token == null || _isLoadingMore || _status != HomeStatus.ready) {
      return;
    }
    if (_requestedContinuationTokens.contains(token)) {
      _continuationToken = null;
      _loadMoreErrorMessage = 'Unable to load more music right now.';
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    _loadMoreErrorMessage = '';
    notifyListeners();

    try {
      final page = await _musicProvider.fetchHome(continuationToken: token);
      _requestedContinuationTokens.add(token);
      _sections = _mergeSections(_sections, page.sections);
      final nextToken = page.continuationToken;
      if (nextToken != null &&
          _requestedContinuationTokens.contains(nextToken)) {
        _continuationToken = null;
        _loadMoreErrorMessage = 'Unable to load more music right now.';
      } else {
        _continuationToken = nextToken;
      }
    } on MusicProviderException {
      _loadMoreErrorMessage = 'Unable to load more music right now.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  List<HomeSection> _mergeSections(
    List<HomeSection> current,
    List<HomeSection> incoming,
  ) {
    final merged = current.toList(growable: true);
    for (final nextSection in incoming) {
      final matchingIndex = merged.indexWhere(
        (section) =>
            section.id == nextSection.id ||
            section.title.trim().toLowerCase() ==
                nextSection.title.trim().toLowerCase(),
      );
      if (matchingIndex == -1) {
        merged.add(nextSection);
        continue;
      }

      final existing = merged[matchingIndex];
      final itemsById = {
        for (final item in existing.items) _itemKey(item): item,
      };
      for (final item in nextSection.items) {
        itemsById.putIfAbsent(_itemKey(item), () => item);
      }
      merged[matchingIndex] = HomeSection.items(
        id: existing.id,
        title: existing.title,
        items: itemsById.values.toList(growable: false),
      );
    }
    return List.unmodifiable(merged);
  }

  String _itemKey(SearchResult item) => '${item.runtimeType}:${item.id}';
}
