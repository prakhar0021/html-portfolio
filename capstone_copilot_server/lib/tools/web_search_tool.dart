import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class WebSearchTool {
  final String apiKey = Platform.environment['SERPAPI_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (apiKey.isEmpty) {
      return [];
    }
    final uri = Uri.https('serpapi.com', '/search', {
      'engine': 'google',
      'q': query,
      'api_key': apiKey,
    });

    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final results = <Map<String, dynamic>>[];
      final organic = json['organic_results'] as List<dynamic>?;
      if (organic != null) {
        for (final item in organic.take(5)) {
          final map = item as Map<String, dynamic>;
          results.add({
            'title': map['title'],
            'link': map['link'],
            'snippet': map['snippet'],
          });
        }
      }
      return results;
    }
    throw HttpException('SerpAPI error ${res.statusCode}: ${res.body}');
  }

  Future<String> fetchUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final text = res.body;
        // Trim to avoid massive payloads
        return text.length > 5000 ? text.substring(0, 5000) : text;
      }
      return 'Failed to fetch ($url): ${res.statusCode}';
    } catch (e) {
      return 'Fetch error for $url: $e';
    }
  }
}