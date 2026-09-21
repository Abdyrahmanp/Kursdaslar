import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'byethost_aes_solver.dart';

/// A specialized [http.Client] that transparently bypasses Byethost's
/// anti-bot JavaScript challenge (`aes.js` / `__test` cookie) and handles
/// SSL certificate validation issues on free hosting.
class ByethostHttpClient extends http.BaseClient {
  static const String _prefCookieKey = 'byethost_test_cookie_v1';
  static const String _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  final http.Client _inner;
  static String? _cachedCookie;
  static bool _hasLoadedFromPrefs = false;
  static Completer<void>? _solvingCompleter;

  ByethostHttpClient({http.Client? inner})
      : _inner = inner ??
            IOClient(
              HttpClient()
                ..badCertificateCallback = (X509Certificate cert, String host, int port) {
                  // Allow Byethost / ZeroSSL free certificates on Android/iOS
                  return true;
                },
            );

  /// Load cached cookie from SharedPreferences once on startup
  static Future<void> _ensureCookieLoaded() async {
    if (_hasLoadedFromPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCookie = prefs.getString(_prefCookieKey);
      _hasLoadedFromPrefs = true;
    } catch (_) {
      _hasLoadedFromPrefs = true;
    }
  }

  /// Save newly solved cookie
  static Future<void> _saveCookie(String cookie) async {
    _cachedCookie = cookie;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCookieKey, cookie);
    } catch (_) {}
  }

  /// Injects required User-Agent and __test cookie into headers
  void _applyHeaders(Map<String, String> headers) {
    headers.putIfAbsent('User-Agent', () => _defaultUserAgent);
    if (_cachedCookie != null && _cachedCookie!.isNotEmpty) {
      final currentCookie = headers['Cookie'] ?? headers['cookie'];
      if (currentCookie == null || currentCookie.isEmpty) {
        headers['Cookie'] = '__test=$_cachedCookie';
      } else if (!currentCookie.contains('__test=')) {
        headers['Cookie'] = '$currentCookie; __test=$_cachedCookie';
      }
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await _ensureCookieLoaded();

    // If another request is actively solving the challenge, wait for it
    if (_solvingCompleter != null && !_solvingCompleter!.isCompleted) {
      await _solvingCompleter!.future;
    }

    _applyHeaders(request.headers);

    // Cache request body in case we need to retry after solving challenge
    Uint8List? bodyBytes;
    if (request is http.Request) {
      bodyBytes = request.bodyBytes;
    }

    final response = await _inner.send(request);

    // If response is not 200, or not text/html, pass it through directly
    final contentType = response.headers['content-type'] ?? '';
    final isHtml = contentType.contains('text/html') ||
        contentType.isEmpty ||
        !contentType.contains('application/json');

    if (response.statusCode != 200 || !isHtml) {
      return response;
    }

    // Read response body to inspect if it's Byethost's AES challenge
    final responseBytes = await response.stream.toBytes();
    final bodyString = utf8.decode(responseBytes, allowMalformed: true);

    // Check for Byethost AES challenge
    final solvedCookie = ByethostAesSolver.extractAndSolve(bodyString);
    if (solvedCookie == null) {
      // Normal HTML response (not challenge), recreate StreamedResponse
      return http.StreamedResponse(
        Stream.value(responseBytes),
        response.statusCode,
        contentLength: responseBytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    }

    // Challenge detected! Solve and acquire lock
    debugPrint('[ByethostHttpClient] Anti-bot challenge detected. Solved cookie: __test=$solvedCookie');
    _solvingCompleter ??= Completer<void>();
    await _saveCookie(solvedCookie);
    if (!_solvingCompleter!.isCompleted) {
      _solvingCompleter!.complete();
    }
    _solvingCompleter = null;

    // Retry original request with the new cookie
    final retryRequest = _rebuildRequest(request, bodyBytes);
    _applyHeaders(retryRequest.headers);

    return _inner.send(retryRequest);
  }

  http.BaseRequest _rebuildRequest(http.BaseRequest original, Uint8List? bodyBytes) {
    if (original is http.Request) {
      final copy = http.Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..persistentConnection = original.persistentConnection;
      if (bodyBytes != null && bodyBytes.isNotEmpty) {
        copy.bodyBytes = bodyBytes;
      }
      return copy;
    }
    // Fallback for generic requests
    return original;
  }

  @override
  void close() {
    _inner.close();
  }
}
