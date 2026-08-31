import 'track.dart';

sealed class SearchResult {
  const SearchResult();

  String get id;
  String get title;
  Uri? get artworkUri;
}

final class TrackSearchResult extends SearchResult {
  const TrackSearchResult(this.track);

  final Track track;

  @override
  String get id => track.id;

  @override
  String get title => track.title;

  @override
  Uri? get artworkUri => track.artworkUri;
}

final class AlbumSearchResult extends SearchResult {
  AlbumSearchResult({
    required String id,
    required String title,
    required List<String> artists,
    this.artworkUri,
  }) : id = _requireText(id, 'id'),
       title = _requireText(title, 'title'),
       artists = List.unmodifiable(_requireArtists(artists));

  @override
  final String id;

  @override
  final String title;

  final List<String> artists;

  @override
  final Uri? artworkUri;

  String get artistLabel => artists.join(', ');
}

final class ArtistSearchResult extends SearchResult {
  ArtistSearchResult({
    required String id,
    required String name,
    this.artworkUri,
  }) : id = _requireText(id, 'id'),
       name = _requireText(name, 'name');

  @override
  final String id;

  final String name;

  @override
  final Uri? artworkUri;

  @override
  String get title => name;
}

final class PlaylistSearchResult extends SearchResult {
  PlaylistSearchResult({
    required String id,
    required String title,
    required String subtitle,
    this.artworkUri,
  }) : id = _requireText(id, 'id'),
       title = _requireText(title, 'title'),
       subtitle = _requireText(subtitle, 'subtitle');

  @override
  final String id;

  @override
  final String title;

  final String subtitle;

  @override
  final Uri? artworkUri;
}

String _requireText(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return value;
}

List<String> _requireArtists(List<String> artists) {
  if (artists.isEmpty) {
    throw ArgumentError.value(artists, 'artists', 'must not be empty');
  }
  for (final artist in artists) {
    _requireText(artist, 'artists');
  }
  return artists;
}
