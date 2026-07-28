import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_url_web.dart' if (dart.library.io) 'base_url_io.dart' as platform_url;

/// Single place that knows how to talk to the Flask backend.
///
/// Why centralize this? Every screen needs the same base URL, the same
/// JSON encode/decode boilerplate, and (once auth exists) the same
/// "attach the JWT token" step. Putting it here means screens just call
/// ApiService.get('/destinations') and don't repeat that plumbing.
class ApiService {
  // Resolved per-platform: 10.0.2.2 on the Android emulator, 127.0.0.1
  // everywhere else (web, iOS simulator, desktop). See base_url_io.dart /
  // base_url_web.dart. If you're testing on a REAL physical device
  // instead of an emulator/simulator, neither of these will work --
  // replace with your computer's LAN IP (e.g. 'http://192.168.1.42:5000/api').
  static final String baseUrl = platform_url.resolveBaseUrl();

  // Same host as baseUrl, but without the '/api' suffix -- used for
  // static files (e.g. user-provided destination photos served from
  // Flask's /static route) rather than JSON API calls.
  static final String mediaBaseUrl = baseUrl.replaceAll(RegExp(r'/api$'), '');

  String? _authToken;

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map && decoded['error'] != null)
        ? decoded['error']
        : 'Request failed (${res.statusCode})';
    throw ApiException(message.toString());
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// One shared instance used across the app.
final apiService = ApiService();
