enum CatalogItemKind { track, album, artist, playlist }

final class CatalogItemDto {
  CatalogItemDto({
    required this.kind,
    required this.id,
    required this.title,
    required List<String> artists,
    required this.duration,
    required this.artworkUri,
  }) : artists = List.unmodifiable(artists);

  final CatalogItemKind kind;
  final String id;
  final String title;
  final List<String> artists;
  final Duration? duration;
  final Uri? artworkUri;
}

final class CatalogPageDto {
  CatalogPageDto({
    required List<CatalogItemDto> items,
    required this.continuationToken,
    required this.ignoredItemCount,
  }) : items = List.unmodifiable(items);

  final List<CatalogItemDto> items;
  final String? continuationToken;
  final int ignoredItemCount;

  @override
  String toString() =>
      'CatalogPageDto(items: ${items.length}, '
      'hasContinuation: ${continuationToken != null}, '
      'ignoredItemCount: $ignoredItemCount)';
}
