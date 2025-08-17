import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OpenAIClient {
  final String apiKey;
  final String apiBase;
  final String model;

  OpenAIClient({
    String? apiKey,
    String? apiBase,
    String? model,
  })  : apiKey = apiKey ?? Platform.environment['OPENAI_API_KEY'] ?? '',
        apiBase = apiBase ?? Platform.environment['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1',
        model = model ?? Platform.environment['OPENAI_MODEL'] ?? 'gpt-4o-mini';

  Future<String> chat({required List<Map<String, String>> messages, String? system}) async {
    if (apiKey.isEmpty) {
      throw StateError('Missing OPENAI_API_KEY');
    }

    final body = {
      'model': model,
      'messages': [
        if (system != null && system.trim().isNotEmpty) {'role': 'system', 'content': system},
        ...messages,
      ],
      'temperature': 0.4,
    };

    final response = await http.post(
      Uri.parse('$apiBase/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['choices']?[0]?['message']?['content'];
      if (content is String) return content;
      return jsonEncode(content);
    }

    throw HttpException('OpenAI error ${response.statusCode}: ${response.body}');
  }
}