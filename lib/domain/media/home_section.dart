import 'track.dart';

final class HomeSection {
  HomeSection({
    required String id,
    required String title,
    required List<Track> tracks,
  }) : id = _requireText(id, 'id'),
       title = _requireText(title, 'title'),
       tracks = List.unmodifiable(tracks);

  final String id;
  final String title;
  final List<Track> tracks;

  static String _requireText(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be blank');
    }
    return value;
  }
}
