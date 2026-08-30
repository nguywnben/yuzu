import 'home_section.dart';
import 'track.dart';

abstract interface class MusicProvider {
  Future<List<HomeSection>> fetchHome();

  Future<List<Track>> search(String query);
}

final class MusicProviderException implements Exception {
  const MusicProviderException(this.message);

  final String message;

  @override
  String toString() => 'MusicProviderException: $message';
}
