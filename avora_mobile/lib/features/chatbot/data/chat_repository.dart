import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Một tin nhắn trong hội thoại.
class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  /// true = tin nhắn cục bộ (lời chào/lỗi), không gửi lại trong history.
  final bool local;

  const ChatMessage({
    required this.role,
    required this.content,
    this.local = false,
  });

  bool get isUser => role == 'user';
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(apiClientProvider)),
);

/// Chỉ gọi backend web (POST /api/chat). Prompt, tools và LLM đều xử lý ở server.
class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  Future<String> send({
    required String message,
    required List<ChatMessage> history,
    String currentPage = '',
    String currentHotelId = '',
    double? lat,
    double? lng,
  }) async {
    final res = await _dio.post(
      '/chat',
      data: {
        'message': message,
        'history': history
            .where((m) => !m.local)
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        'context': {
          'userLocation': (lat != null && lng != null)
              ? {'lat': lat, 'lng': lng}
              : null,
          'currentPage': currentPage,
          'currentHotelId': currentHotelId,
        },
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    final data = res.data;
    final reply = (data is Map && data['data'] is Map)
        ? data['data']['reply']?.toString()
        : null;
    return (reply == null || reply.isEmpty)
        ? 'Xin lỗi, tôi chưa thể trả lời lúc này.'
        : reply;
  }
}
