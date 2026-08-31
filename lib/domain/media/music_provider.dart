import 'home_page.dart';
import 'search_result.dart';

abstract interface class MusicProvider {
  Future<HomePage> fetchHome({String? continuationToken});

  Future<List<SearchResult>> search(String query);
}

final class MusicProviderException implements Exception {
  const MusicProviderException(this.message);

  final String message;

  @override
  String toString() => 'MusicProviderException: $message';
}
