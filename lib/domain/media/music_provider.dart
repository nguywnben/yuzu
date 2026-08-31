import 'home_section.dart';
import 'search_result.dart';

abstract interface class MusicProvider {
  Future<List<HomeSection>> fetchHome();

  Future<List<SearchResult>> search(String query);
}

final class MusicProviderException implements Exception {
  const MusicProviderException(this.message);

  final String message;

  @override
  String toString() => 'MusicProviderException: $message';
}
