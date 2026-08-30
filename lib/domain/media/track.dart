final class Track {
  Track({
    required String id,
    required String title,
    required List<String> artists,
    required Duration duration,
    this.artworkUri,
  }) : id = _requireText(id, 'id'),
       title = _requireText(title, 'title'),
       artists = List.unmodifiable(_requireArtists(artists)),
       duration = _requireDuration(duration);

  final String id;
  final String title;
  final List<String> artists;
  final Duration duration;
  final Uri? artworkUri;

  String get artistLabel => artists.join(', ');

  static String _requireText(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be blank');
    }
    return value;
  }

  static List<String> _requireArtists(List<String> artists) {
    if (artists.isEmpty) {
      throw ArgumentError.value(artists, 'artists', 'must not be empty');
    }
    for (final artist in artists) {
      _requireText(artist, 'artists');
    }
    return artists;
  }

  static Duration _requireDuration(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'must be positive');
    }
    return duration;
  }
}
