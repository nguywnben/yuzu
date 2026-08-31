import '../data/youtube_music/live_catalog_transport.dart';
import '../data/youtube_music/youtube_music_provider.dart';
import '../domain/media/music_provider.dart';

/// Builds the production catalog graph while keeping feature widgets unaware
/// of which provider implementation they receive.
MusicProvider createDefaultMusicProvider() {
  return YoutubeMusicProvider(transport: YoutubeMusicCatalogTransport());
}
