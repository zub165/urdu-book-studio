import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { gemini, openai }

extension AiProviderLabel on AiProvider {
  String get label => switch (this) {
        AiProvider.gemini => 'Google Gemini',
        AiProvider.openai => 'OpenAI',
      };

  String get defaultModel => switch (this) {
        AiProvider.gemini => 'gemini-2.5-flash',
        AiProvider.openai => 'gpt-4o-mini',
      };
}

class AiSettings {
  final AiProvider provider;
  final String apiKey;
  final String model;

  const AiSettings({
    this.provider = AiProvider.gemini,
    this.apiKey = '',
    this.model = 'gemini-2.5-flash',
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  AiSettings copyWith({
    AiProvider? provider,
    String? apiKey,
    String? model,
  }) =>
      AiSettings(
        provider: provider ?? this.provider,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'model': model,
      };

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    final provider = AiProvider.values.firstWhere(
      (p) => p.name == json['provider'],
      orElse: () => AiProvider.gemini,
    );
    return AiSettings(
      provider: provider,
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? provider.defaultModel,
    );
  }
}

class AiSettingsStore {
  static const _key = 'urdu_book_studio.ai.v1';

  Future<AiSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const AiSettings();
    return AiSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => message;
}

String translationPrompt({
  required String text,
  required String sourceLanguage,
  required String targetLanguage,
  required bool urduDigits,
}) =>
    'Translate the text below from $sourceLanguage to $targetLanguage. '
    'Return only the translation, keep paragraph breaks, and do not add '
    'explanations or quotation marks.${urduDigits ? ' Use Urdu digits ۰-۹.' : ''}'
    '\n\n$text';

String outlinePrompt({
  required String topic,
  required String language,
}) =>
    'Write a short book chapter outline in $language about: $topic. '
    'Return 5-10 lines only. Start chapter-level headings with "H1: ", '
    'section headings with "H2: ", and paragraph ideas with "P: ". '
    'Do not add numbering or explanations.';

class AiService {
  final http.Client _client;

  AiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    required AiSettings settings,
    bool urduDigits = false,
  }) =>
      generate(
        translationPrompt(
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
          urduDigits: urduDigits,
        ),
        settings,
      );

  Future<String> outline({
    required String topic,
    required String language,
    required AiSettings settings,
  }) =>
      generate(outlinePrompt(topic: topic, language: language), settings);

  Future<String> generate(String prompt, AiSettings settings) async {
    if (!settings.isConfigured) {
      throw const AiException('Add an API key in AI settings first.');
    }
    final response = switch (settings.provider) {
      AiProvider.gemini => await _gemini(prompt, settings),
      AiProvider.openai => await _openai(prompt, settings),
    };
    if (response.statusCode != 200) {
      throw AiException(_errorFrom(response.body) ??
          'AI request failed (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = switch (settings.provider) {
      AiProvider.gemini => _geminiText(decoded),
      AiProvider.openai => _openaiText(decoded),
    };
    if (text.trim().isEmpty) throw const AiException('AI returned no text.');
    return text.trim();
  }

  Future<http.Response> _gemini(String prompt, AiSettings settings) {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/${settings.model}:generateContent',
      {'key': settings.apiKey.trim()},
    );
    return _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'parts': [
            {'text': prompt}
          ]}
        ],
        'generationConfig': {'temperature': 0.2},
      }),
    );
  }

  Future<http.Response> _openai(String prompt, AiSettings settings) =>
      _client.post(
        Uri.https('api.openai.com', '/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.apiKey.trim()}',
        },
        body: jsonEncode({
          'model': settings.model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
        }),
      );

  String _geminiText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) throw const AiException('AI returned no result.');
    final content = (candidates.first as Map<String, dynamic>)['content']
        as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    return parts
        .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
        .join();
  }

  String _openaiText(Map<String, dynamic> decoded) {
    final choices = decoded['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) throw const AiException('AI returned no result.');
    final message = (choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>?;
    return message?['content'] as String? ?? '';
  }

  String? _errorFrom(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) return error['message'] as String?;
      if (error is String) return error;
    } catch (_) {
      return null;
    }
    return null;
  }

  void dispose() => _client.close();
}
