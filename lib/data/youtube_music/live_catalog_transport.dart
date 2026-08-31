import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'catalog_error.dart';
import 'transport.dart';

typedef CatalogHttpClientFactory = http.Client Function();

/// Sends the deliberately small, guest-only subset of YouTube Music requests
/// approved by Yuzu's catalog policy.
final class YoutubeMusicCatalogTransport implements CatalogTransport {
  YoutubeMusicCatalogTransport({CatalogHttpClientFactory? clientFactory})
    : _clientFactory = clientFactory ?? http.Client.new;

  static final Uri _bootstrapUri = Uri.https('music.youtube.com', '/');
  static const _searchPath = '/youtubei/v1/search';
  static const _browsePath = '/youtubei/v1/browse';
  static const _homeBrowseId = 'FEmusic_home';
  static const _bootstrapMaxBytes = 512 * 1024;
  static const _maxContinuationBytes = 2048;
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  static final RegExp _apiKeyPattern = RegExp(
    r'"INNERTUBE_API_KEY"\s*:\s*"([A-Za-z0-9_-]{8,128})"',
  );
  static final RegExp _clientVersionPattern = RegExp(
    r'"INNERTUBE_CLIENT_VERSION"\s*:\s*"([0-9.]{5,40})"',
  );
  static final RegExp _clientNamePattern = RegExp(
    r'"INNERTUBE_CONTEXT_CLIENT_NAME"\s*:\s*"?([0-9]{1,4})"?',
  );

  final CatalogHttpClientFactory _clientFactory;
  _GuestClientConfig? _config;

  @override
  Future<CatalogTransportResponse> send(CatalogTransportRequest request) async {
    _throwIfCancelled(request.cancellationToken);
    final payload = _readOperationPayload(request);

    var attempt = 1;
    while (true) {
      _throwIfCancelled(request.cancellationToken);
      try {
        return await _sendCatalogRequest(request, payload);
      } on CatalogFailure catch (failure) {
        if (!failure.canRetry || attempt == request.maxAttempts) {
          rethrow;
        }
        attempt++;
      }
    }
  }

  Future<CatalogTransportResponse> _sendCatalogRequest(
    CatalogTransportRequest request,
    Map<String, Object?> operationPayload,
  ) async {
    final config = _config ??= await _bootstrap(
      timeout: request.timeout,
      cancellationToken: request.cancellationToken,
    );
    final path = request.operation == CatalogOperation.search
        ? _searchPath
        : _browsePath;
    final uri = Uri.https('music.youtube.com', path, {
      'prettyPrint': 'false',
      'key': config.apiKey,
    });
    final message = http.AbortableRequest(
      'POST',
      uri,
      abortTrigger: request.cancellationToken?.whenCancelled,
    );
    message
      ..followRedirects = false
      ..headers.addAll({
        'accept': 'application/json',
        'accept-language': 'en-US,en;q=0.9',
        'content-type': 'application/json',
        'origin': 'https://music.youtube.com',
        'referer': 'https://music.youtube.com/',
        'user-agent': _userAgent,
        'x-goog-api-format-version': '1',
        'x-origin': 'https://music.youtube.com',
        'x-youtube-client-name': config.clientName,
        'x-youtube-client-version': config.clientVersion,
      })
      ..bodyBytes = utf8.encode(
        jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': config.clientVersion,
              'hl': 'en',
              'gl': 'US',
              'platform': 'DESKTOP',
              'clientFormFactor': 'UNKNOWN_FORM_FACTOR',
              'userAgent': _userAgent,
              'timeZone': 'UTC',
            },
            'request': {'useSsl': true},
            'user': <String, Object?>{},
          },
          ...operationPayload,
        }),
      );

    final response = await _send(
      message,
      timeout: request.timeout,
      maxResponseBytes: request.maxResponseBytes,
    );
    _validateStatus(response.statusCode);
    return response;
  }

  Future<_GuestClientConfig> _bootstrap({
    required Duration timeout,
    required CatalogCancellationToken? cancellationToken,
  }) async {
    _throwIfCancelled(cancellationToken);
    final request =
        http.AbortableRequest(
            'GET',
            _bootstrapUri,
            abortTrigger: cancellationToken?.whenCancelled,
          )
          ..followRedirects = false
          ..headers.addAll({
            'accept': 'text/html,application/xhtml+xml',
            'accept-language': 'en-US,en;q=0.9',
            'user-agent': _userAgent,
          });
    final response = await _send(
      request,
      timeout: timeout,
      maxResponseBytes: _bootstrapMaxBytes,
    );
    _validateStatus(response.statusCode);
    if (response.contentType.split(';').first.trim() != 'text/html') {
      throw const CatalogFailure(CatalogFailureKind.unsupportedSchema);
    }

    late final String html;
    try {
      html = utf8.decode(response.bodyBytes);
    } on FormatException {
      throw const CatalogFailure(CatalogFailureKind.malformedResponse);
    }
    final apiKey = _apiKeyPattern.firstMatch(html)?.group(1);
    final clientVersion = _clientVersionPattern.firstMatch(html)?.group(1);
    final clientName = _clientNamePattern.firstMatch(html)?.group(1);
    if (apiKey == null || clientVersion == null || clientName == null) {
      throw const CatalogFailure(CatalogFailureKind.unsupportedSchema);
    }
    return _GuestClientConfig(
      apiKey: apiKey,
      clientVersion: clientVersion,
      clientName: clientName,
    );
  }

  Future<CatalogTransportResponse> _send(
    http.BaseRequest request, {
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    final client = _clientFactory();
    try {
      final streamed = await client.send(request).timeout(timeout);
      final bytes = await _readBounded(
        streamed.stream,
        maxResponseBytes: maxResponseBytes,
        timeout: timeout,
      );
      return CatalogTransportResponse(
        statusCode: streamed.statusCode,
        contentType:
            streamed.headers['content-type'] ?? 'application/octet-stream',
        bodyBytes: bytes,
      );
    } on CatalogFailure {
      rethrow;
    } on TimeoutException {
      throw const CatalogFailure(CatalogFailureKind.timeout);
    } on http.RequestAbortedException {
      throw const CatalogFailure(CatalogFailureKind.cancelled);
    } on http.ClientException {
      throw const CatalogFailure(CatalogFailureKind.networkUnavailable);
    } finally {
      client.close();
    }
  }

  Future<Uint8List> _readBounded(
    Stream<List<int>> stream, {
    required int maxResponseBytes,
    required Duration timeout,
  }) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream.timeout(timeout)) {
      if (builder.length + chunk.length > maxResponseBytes) {
        throw const CatalogFailure(CatalogFailureKind.malformedResponse);
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Map<String, Object?> _readOperationPayload(CatalogTransportRequest request) {
    final payload = _readJsonObject(request.bodyBytes);
    return switch (request.operation) {
      CatalogOperation.search => {'query': _readQuery(payload)},
      CatalogOperation.home => _readHome(payload),
      CatalogOperation.continuation => {
        'continuation': _readContinuation(payload),
      },
      CatalogOperation.album ||
      CatalogOperation.artist ||
      CatalogOperation.playlist => throw const CatalogFailure(
        CatalogFailureKind.policyDisabled,
      ),
    };
  }

  Map<String, Object?> _readJsonObject(Uint8List bodyBytes) {
    try {
      final payload = jsonDecode(utf8.decode(bodyBytes));
      if (payload is Map<String, Object?>) {
        return payload;
      }
    } on FormatException {
      // Converted to the transport's stable failure taxonomy below.
    }
    throw const CatalogFailure(CatalogFailureKind.malformedResponse);
  }

  String _readQuery(Map<String, Object?> payload) {
    if (payload case {'query': final String query}) {
      final normalized = query.trim();
      if (payload.length == 1 &&
          normalized.isNotEmpty &&
          normalized.length <= 200) {
        return normalized;
      }
    }
    throw const CatalogFailure(CatalogFailureKind.malformedResponse);
  }

  Map<String, Object?> _readHome(Map<String, Object?> payload) {
    if (payload.isNotEmpty) {
      throw const CatalogFailure(CatalogFailureKind.malformedResponse);
    }
    return const {'browseId': _homeBrowseId};
  }

  String _readContinuation(Map<String, Object?> payload) {
    if (payload case {'continuation': final String token}) {
      final normalized = token.trim();
      if (payload.length == 1 &&
          normalized.isNotEmpty &&
          utf8.encode(normalized).length <= _maxContinuationBytes) {
        return normalized;
      }
    }
    throw const CatalogFailure(CatalogFailureKind.malformedResponse);
  }

  void _validateStatus(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw CatalogFailure(switch (statusCode) {
      404 => CatalogFailureKind.notFound,
      408 || 504 => CatalogFailureKind.timeout,
      429 => CatalogFailureKind.rateLimited,
      >= 500 && <= 599 => CatalogFailureKind.unavailable,
      _ => CatalogFailureKind.upstreamRejected,
    });
  }

  void _throwIfCancelled(CatalogCancellationToken? token) {
    if (token?.isCancelled ?? false) {
      throw const CatalogFailure(CatalogFailureKind.cancelled);
    }
  }
}

final class _GuestClientConfig {
  const _GuestClientConfig({
    required this.apiKey,
    required this.clientVersion,
    required this.clientName,
  });

  final String apiKey;
  final String clientVersion;
  final String clientName;
}
