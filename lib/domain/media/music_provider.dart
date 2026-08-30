import 'home_section.dart';
import 'track.dart';

abstract interface class MusicProvider {
  Future<List<HomeSection>> fetchHome();

  Future<List<Track>> search(String query);
}
