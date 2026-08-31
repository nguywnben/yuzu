import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/media/music_provider.dart';
import '../../domain/media/search_result.dart';
import '../../domain/media/track.dart';
import '../shared/track_widgets.dart';
import 'search_view_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.musicProvider,
    this.onTrackSelected,
  });

  final MusicProvider musicProvider;
  final TrackSelectionCallback? onTrackSelected;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _searchDebounceDuration = Duration(milliseconds: 350);

  late SearchViewModel _viewModel;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _bindViewModel();
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.musicProvider, widget.musicProvider)) {
      _unbindViewModel();
      _bindViewModel();
    }
  }

  void _bindViewModel() {
    _viewModel = SearchViewModel(widget.musicProvider)..addListener(_refresh);
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

  void _scheduleSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      unawaited(_viewModel.search(query));
      return;
    }
    _searchDebounce = Timer(
      _searchDebounceDuration,
      () => unawaited(_viewModel.search(query)),
    );
  }

  void _submitSearch(String query) {
    _searchDebounce?.cancel();
    unawaited(_viewModel.search(query));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _unbindViewModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('search-scroll'),
      slivers: [
        const SliverAppBar.large(title: Text('Search')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          sliver: SliverToBoxAdapter(
            child: SearchBar(
              hintText: 'Songs, artists, albums',
              leading: const Icon(Icons.search_rounded),
              onChanged: _scheduleSearch,
              onSubmitted: _submitSearch,
            ),
          ),
        ),
        ..._buildResults(context),
      ],
    );
  }

  List<Widget> _buildResults(BuildContext context) {
    return switch (_viewModel.status) {
      SearchStatus.idle => [
        _SearchMessage(
          icon: Icons.travel_explore_rounded,
          title: 'Find your next favorite',
          message: 'Search the Yuzu catalog by song or artist.',
        ),
      ],
      SearchStatus.loading => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      SearchStatus.ready => [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 32),
          sliver: SliverList.builder(
            itemCount: _viewModel.results.length,
            itemBuilder: (context, index) {
              final result = _viewModel.results[index];
              return _SearchResultTile(
                result: result,
                onTrackSelected: widget.onTrackSelected == null
                    ? null
                    : (track) => widget.onTrackSelected!(
                        track,
                        _viewModel.trackResults,
                      ),
              );
            },
          ),
        ),
      ],
      SearchStatus.empty => [
        _SearchMessage(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try another song title or artist name.',
        ),
      ],
      SearchStatus.failure => [
        _SearchMessage(
          icon: Icons.cloud_off_outlined,
          title: "Search couldn't finish",
          message: _viewModel.errorMessage,
          actionLabel: 'Try again',
          onAction: () => _viewModel.search(_viewModel.query),
        ),
      ],
    };
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, this.onTrackSelected});

  final SearchResult result;
  final ValueChanged<Track>? onTrackSelected;

  @override
  Widget build(BuildContext context) {
    final (icon, subtitle, onTap) = switch (result) {
      TrackSearchResult(:final track) => (
        Icons.music_note_rounded,
        _ResultSubtitle(category: 'Track', detail: track.artistLabel),
        onTrackSelected == null ? null : () => onTrackSelected!(track),
      ),
      AlbumSearchResult(:final artistLabel) => (
        Icons.album_rounded,
        _ResultSubtitle(category: 'Album', detail: artistLabel),
        null,
      ),
      ArtistSearchResult() => (
        Icons.person_rounded,
        const _ResultSubtitle(category: 'Artist'),
        null,
      ),
    };
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        child: Icon(icon),
      ),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _ResultSubtitle extends StatelessWidget {
  const _ResultSubtitle({required this.category, this.detail});

  final String category;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(category),
        if (detail case final detail?) ...[
          const Text(' • '),
          Expanded(
            child: Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
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
            if (actionLabel case final actionLabel?) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => unawaited(onAction!()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
