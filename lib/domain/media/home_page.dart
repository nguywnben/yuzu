import 'home_section.dart';

final class HomePage {
  HomePage({required List<HomeSection> sections, this.continuationToken})
    : sections = List.unmodifiable(sections) {
    final token = continuationToken;
    if (token != null && token.trim().isEmpty) {
      throw ArgumentError.value(
        token,
        'continuationToken',
        'must not be blank',
      );
    }
  }

  final List<HomeSection> sections;
  final String? continuationToken;

  @override
  String toString() =>
      'HomePage(sections: ${sections.length}, '
      'hasContinuation: ${continuationToken != null})';
}
