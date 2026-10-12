import 'package:dio/dio.dart';
import 'package:avora_mobile/core/config/ai_config.dart';
import 'package:avora_mobile/core/network/api_client.dart';

/// Client gọi Groq (API tương thích OpenAI). Dùng Dio riêng, KHÔNG dùng
/// Dio của backend để tránh gắn nhầm JWT/baseUrl.
class GroqClient {
  final Dio _dio;

  GroqClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: groqBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 40),
            ));

  bool get isConfigured => groqApiKey.trim().isNotEmpty;

  /// Gửi hội thoại và trả về nội dung text của model.
  Future<String> complete(
    List<Map<String, String>> messages, {
    bool json = false,
    double temperature = 0.3,
    int maxTokens = 700,
  }) async {
    if (!isConfigured) {
      throw const ApiException(
        message:
            'Chưa có API key Groq. Hãy dán key vào lib/core/config/ai_config.dart.',
      );
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${groqApiKey.trim()}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': groqModel,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          if (json) 'response_format': {'type': 'json_object'},
        },
      );

      final data = response.data;
      if (data is Map) {
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final first = choices.first;
          if (first is Map) {
            final msg = first['message'];
            if (msg is Map) {
              return msg['content']?.toString() ?? '';
            }
          }
        }
      }
      return '';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const ApiException(
            message: 'API key Groq không hợp lệ. Vui lòng kiểm tra lại.',
            statusCode: 401);
      }
      if (status == 429) {
        throw const ApiException(
            message: 'Groq đang giới hạn tần suất, hãy thử lại sau ít giây.',
            statusCode: 429);
      }
      throw ApiException(
        message: 'Không gọi được trợ lý AI (${status ?? e.type.name}).',
        statusCode: status,
      );
    }
  }
}
