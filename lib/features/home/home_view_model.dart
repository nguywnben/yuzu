import 'package:flutter/foundation.dart';

import '../../domain/media/home_section.dart';
import '../../domain/media/music_provider.dart';

enum HomeStatus { idle, loading, ready, empty, failure }

final class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._musicProvider);

  final MusicProvider _musicProvider;

  HomeStatus _status = HomeStatus.idle;
  List<HomeSection> _sections = const [];
  String _errorMessage = '';

  HomeStatus get status => _status;
  List<HomeSection> get sections => _sections;
  String get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = HomeStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final sections = await _musicProvider.fetchHome();
      _sections = List.unmodifiable(sections);
      _status = sections.isEmpty ? HomeStatus.empty : HomeStatus.ready;
    } on MusicProviderException {
      _sections = const [];
      _status = HomeStatus.failure;
      _errorMessage = 'Unable to load music right now.';
    }
    notifyListeners();
  }
}
