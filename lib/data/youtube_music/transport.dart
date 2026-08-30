import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

enum CatalogOperation { home, search, album, artist, playlist, continuation }

abstract interface class CatalogTransport {
  Future<CatalogTransportResponse> send(CatalogTransportRequest request);
}

final class CatalogTransportRequest {
  CatalogTransportRequest._({
    required this.operation,
    required this._bodyBytes,
    required this.timeout,
    required this.maxResponseBytes,
    required this.maxAttempts,
    this.cancellationToken,
  });

  factory CatalogTransportRequest.json({
    required CatalogOperation operation,
    required Map<String, Object?> payload,
    Duration timeout = defaultTimeout,
    int maxResponseBytes = defaultMaxResponseBytes,
    int maxAttempts = defaultMaxAttempts,
    CatalogCancellationToken? cancellationToken,
  }) {
    if (timeout <= Duration.zero || timeout > maxTimeout) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'must be greater than zero and at most $maxTimeout',
      );
    }
    if (maxResponseBytes <= 0 || maxResponseBytes > maxResponseByteLimit) {
      throw ArgumentError.value(
        maxResponseBytes,
        'maxResponseBytes',
        'must be between 1 and $maxResponseByteLimit',
      );
    }
    if (maxAttempts <= 0 || maxAttempts > maxAttemptLimit) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'must be between 1 and $maxAttemptLimit',
      );
    }

    late final String encodedPayload;
    try {
      encodedPayload = jsonEncode(payload);
    } on JsonUnsupportedObjectError catch (error) {
      throw ArgumentError.value(payload, 'payload', error.toString());
    }
    final bodyBytes = Uint8List.fromList(utf8.encode(encodedPayload));
    if (bodyBytes.length > maxRequestBytes) {
      throw ArgumentError.value(
        bodyBytes.length,
        'payload',
        'encoded body exceeds $maxRequestBytes bytes',
      );
    }

    return CatalogTransportRequest._(
      operation: operation,
      bodyBytes: bodyBytes,
      timeout: timeout,
      maxResponseBytes: maxResponseBytes,
      maxAttempts: maxAttempts,
      cancellationToken: cancellationToken,
    );
  }

  static const defaultTimeout = Duration(seconds: 12);
  static const maxTimeout = Duration(seconds: 30);
  static const maxRequestBytes = 64 * 1024;
  static const defaultMaxResponseBytes = 1024 * 1024;
  static const maxResponseByteLimit = 4 * 1024 * 1024;
  static const defaultMaxAttempts = 2;
  static const maxAttemptLimit = 3;

  final CatalogOperation operation;
  final Uint8List _bodyBytes;
  final Duration timeout;
  final int maxResponseBytes;
  final int maxAttempts;
  final CatalogCancellationToken? cancellationToken;

  Uint8List get bodyBytes => Uint8List.fromList(_bodyBytes);

  @override
  String toString() =>
      'CatalogTransportRequest(operation: ${operation.name}, '
      'timeout: $timeout, maxResponseBytes: $maxResponseBytes, '
      'maxAttempts: $maxAttempts)';
}

final class CatalogTransportResponse {
  CatalogTransportResponse({
    required this.statusCode,
    required String contentType,
    required List<int> bodyBytes,
  }) : contentType = _requireContentType(contentType),
       _bodyBytes = Uint8List.fromList(bodyBytes) {
    if (statusCode < 100 || statusCode > 599) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'must be a valid HTTP status code',
      );
    }
  }

  final int statusCode;
  final String contentType;
  final Uint8List _bodyBytes;

  Uint8List get bodyBytes => Uint8List.fromList(_bodyBytes);

  static String _requireContentType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'contentType', 'must not be blank');
    }
    return normalized;
  }
}

final class CatalogCancellationToken {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;

  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }
}
