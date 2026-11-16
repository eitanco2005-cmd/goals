import 'dart:convert';
import 'dart:io';

/// Reads `{"build": N}` from [url]; null on any failure (offline, etc.).
Future<int?> fetchLatestBuild(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(url);
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final body = await response.transform(utf8.decoder).join();
    final build = (jsonDecode(body) as Map<String, dynamic>)['build'];
    return build is num ? build.toInt() : null;
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}
