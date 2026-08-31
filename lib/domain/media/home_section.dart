import 'search_result.dart';
import 'track.dart';

final class HomeSection {
  HomeSection({
    required String id,
    required String title,
    required List<Track> tracks,
  }) : this.items(
         id: id,
         title: title,
         items: [for (final track in tracks) TrackSearchResult(track)],
       );

  HomeSection.items({
    required String id,
    required String title,
    required List<SearchResult> items,
  }) : id = _requireText(id, 'id'),
       title = _requireText(title, 'title'),
       items = List.unmodifiable(items),
       tracks = List.unmodifiable([
         for (final item in items)
           if (item case TrackSearchResult(:final track)) track,
       ]);

  final String id;
  final String title;
  final List<SearchResult> items;
  final List<Track> tracks;

  static String _requireText(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be blank');
    }
    return value;
  }
}
