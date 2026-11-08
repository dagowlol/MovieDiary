import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AiClient {
  Future<String> generateContent(String prompt);
}

/// Google Gemini API Client (default, free-tier friendly)
class GeminiAiClient implements AiClient {
  final String apiKey;
  final String model;
  final http.Client _client;

  GeminiAiClient({
    required this.apiKey,
    this.model = 'gemini-1.5-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> generateContent(String prompt) async {
    if (apiKey.trim().isEmpty) {
      throw StateError('Gemini API key is not configured.');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'responseMimeType': 'application/json',
      },
    });

    final response = await _client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HttpException(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const FormatException('Gemini returned an empty candidate list.');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const FormatException('Gemini returned content with no parts.');
    }

    final text = parts[0]['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Gemini returned empty text.');
    }

    return text;
  }
}

/// OpenAI-compatible API Client (e.g. OpenAI, DeepSeek, Groq, local Ollama)
class OpenAiClient implements AiClient {
  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _client;

  OpenAiClient({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> generateContent(String prompt) async {
    if (apiKey.trim().isEmpty) {
      throw StateError('OpenAI API key is not configured.');
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/chat/completions');

    final requestBody = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an expert movie recommendation engine. Output strictly valid JSON.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'response_format': {'type': 'json_object'},
    });

    final response = await _client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw HttpException(
        'OpenAI API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('OpenAI returned no choices.');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('OpenAI returned empty message content.');
    }

    return content;
  }
}

/// Mock AI Client for testing or deterministic responses
class MockAiClient implements AiClient {
  final Future<String> Function(String prompt) onGenerate;

  MockAiClient({required this.onGenerate});

  @override
  Future<String> generateContent(String prompt) => onGenerate(prompt);
}

class HttpException implements Exception {
  final String message;
  const HttpException(this.message);

  @override
  String toString() => message;
}
