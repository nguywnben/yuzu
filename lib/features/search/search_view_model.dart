import 'package:flutter/foundation.dart';

import '../../domain/media/music_provider.dart';
import '../../domain/media/search_result.dart';
import '../../domain/media/track.dart';

enum SearchStatus { idle, loading, ready, empty, failure }

final class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._musicProvider);

  final MusicProvider _musicProvider;

  SearchStatus _status = SearchStatus.idle;
  List<SearchResult> _results = const [];
  String _query = '';
  String _errorMessage = '';
  int _requestGeneration = 0;

  SearchStatus get status => _status;
  List<SearchResult> get results => _results;
  List<Track> get trackResults => [
    for (final result in _results)
      if (result case TrackSearchResult(:final track)) track,
  ];
  String get query => _query;
  String get errorMessage => _errorMessage;

  Future<void> search(String rawQuery) async {
    final requestGeneration = ++_requestGeneration;
    _query = rawQuery.trim();
    _errorMessage = '';

    if (_query.isEmpty) {
      _results = const [];
      _status = SearchStatus.idle;
      notifyListeners();
      return;
    }

    _status = SearchStatus.loading;
    notifyListeners();

    try {
      final results = await _musicProvider.search(_query);
      if (requestGeneration != _requestGeneration) {
        return;
      }
      _results = List.unmodifiable(results);
      _status = results.isEmpty ? SearchStatus.empty : SearchStatus.ready;
    } on MusicProviderException {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      _results = const [];
      _status = SearchStatus.failure;
      _errorMessage = 'Search is unavailable right now.';
    }
    notifyListeners();
  }
}
