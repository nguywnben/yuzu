enum CatalogFailureKind {
  networkUnavailable,
  timeout,
  rateLimited,
  upstreamRejected,
  malformedResponse,
  unsupportedSchema,
  notFound,
  unavailable,
  cancelled,
  policyDisabled,
}

final class CatalogFailure implements Exception {
  const CatalogFailure(this.kind);

  final CatalogFailureKind kind;

  bool get canRetry => switch (kind) {
    CatalogFailureKind.networkUnavailable ||
    CatalogFailureKind.timeout ||
    CatalogFailureKind.rateLimited => true,
    CatalogFailureKind.upstreamRejected ||
    CatalogFailureKind.malformedResponse ||
    CatalogFailureKind.unsupportedSchema ||
    CatalogFailureKind.notFound ||
    CatalogFailureKind.unavailable ||
    CatalogFailureKind.cancelled ||
    CatalogFailureKind.policyDisabled => false,
  };

  @override
  String toString() => 'CatalogFailure(${kind.name})';
}
