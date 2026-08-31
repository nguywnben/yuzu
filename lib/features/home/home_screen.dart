import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/media/home_section.dart';
import '../../domain/media/music_provider.dart';
import '../../domain/media/search_result.dart';
import '../../domain/media/track.dart';
import '../shared/track_widgets.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.musicProvider,
    this.onTrackSelected,
  });

  final MusicProvider musicProvider;
  final TrackSelectionCallback? onTrackSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _bindViewModel();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.musicProvider, widget.musicProvider)) {
      _unbindViewModel();
      _bindViewModel();
    }
  }

  void _bindViewModel() {
    _viewModel = HomeViewModel(widget.musicProvider)..addListener(_refresh);
    unawaited(_viewModel.load());
  }

  void _unbindViewModel() {
    _viewModel
      ..removeListener(_refresh)
      ..dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _unbindViewModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        const SliverAppBar.large(title: Text('Yuzu')),
        ..._buildContent(context),
      ],
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    return switch (_viewModel.status) {
      HomeStatus.idle || HomeStatus.loading => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      HomeStatus.ready => [
        for (final section in _viewModel.sections)
          _HomeSectionView(
            section: section,
            onTrackSelected: widget.onTrackSelected,
          ),
        if (_viewModel.hasMore ||
            _viewModel.isLoadingMore ||
            _viewModel.loadMoreErrorMessage.isNotEmpty)
          SliverToBoxAdapter(
            child: _HomePaginationFooter(
              hasMore: _viewModel.hasMore,
              isLoading: _viewModel.isLoadingMore,
              errorMessage: _viewModel.loadMoreErrorMessage,
              onLoadMore: _viewModel.loadMore,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
      HomeStatus.empty => [
        _MessageState(
          icon: Icons.music_off_outlined,
          title: 'Nothing to play yet',
          message: 'New recommendations will appear here when they are ready.',
          actionLabel: 'Refresh',
          onAction: _viewModel.load,
        ),
      ],
      HomeStatus.failure => [
        _MessageState(
          icon: Icons.cloud_off_outlined,
          title: "Home couldn't load",
          message: _viewModel.errorMessage,
          actionLabel: 'Try again',
          onAction: _viewModel.load,
        ),
      ],
    };
  }
}

class _HomePaginationFooter extends StatelessWidget {
  const _HomePaginationFooter({
    required this.hasMore,
    required this.isLoading,
    required this.errorMessage,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoading;
  final String errorMessage;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Center(
          child: switch ((isLoading, errorMessage.isNotEmpty, hasMore)) {
            (true, _, _) => const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            (false, true, true) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => unawaited(onLoadMore()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try loading more'),
                ),
              ],
            ),
            (false, true, false) => Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            (false, false, true) => OutlinedButton.icon(
              onPressed: () => unawaited(onLoadMore()),
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('Load more'),
            ),
            (false, false, false) => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

class _HomeSectionView extends StatelessWidget {
  const _HomeSectionView({required this.section, this.onTrackSelected});

  final HomeSection section;
  final TrackSelectionCallback? onTrackSelected;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 224,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: section.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = section.items[index];
                return _CatalogCard(
                  item: item,
                  onTrackSelected: onTrackSelected == null
                      ? null
                      : (track) => onTrackSelected!(track, section.tracks),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item, this.onTrackSelected});

  final SearchResult item;
  final ValueChanged<Track>? onTrackSelected;

  @override
  Widget build(BuildContext context) {
    final (subtitle, fallbackIcon, onTap) = switch (item) {
      TrackSearchResult(:final track) => (
        track.artistLabel,
        Icons.music_note_rounded,
        onTrackSelected == null ? null : () => onTrackSelected!(track),
      ),
      AlbumSearchResult(:final artistLabel) => (
        artistLabel,
        Icons.album_rounded,
        null,
      ),
      ArtistSearchResult() => ('Artist', Icons.person_rounded, null),
      PlaylistSearchResult(:final subtitle) => (
        subtitle,
        Icons.queue_music_rounded,
        null,
      ),
    };
    return SizedBox(
      width: 156,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CatalogArtwork(
              id: item.id,
              artworkUri: item.artworkUri,
              size: 156,
              fallbackIcon: fallbackIcon,
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => unawaited(onAction()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
