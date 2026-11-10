import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import 'support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return DioSupportRepository(ref.watch(apiClientProvider));
});

abstract interface class SupportRepository {
  Future<List<SupportCategory>> getCategories();
  Future<List<SupportTicket>> getTickets();
  Future<SupportTicket> getTicket(String ticketId);
  Future<SupportTicket> createTicket({
    required String categoryCode,
    required String title,
    required String description,
    List<XFile> attachments = const [],
  });
  Future<SupportTicket> replyToTicket({
    required String ticketId,
    required String message,
    List<XFile> attachments = const [],
  });
  Future<SupportTicket> updateTicketStatus({
    required String ticketId,
    required String action,
  });
  Future<void> deleteTicket(String ticketId);
  Future<Uint8List> downloadAttachment({
    required String ticketId,
    required String key,
  });
}

class DioSupportRepository implements SupportRepository {
  final Dio _dio;

  const DioSupportRepository(this._dio);

  Future<dynamic> _request(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is! Map) {
        throw const ApiException(
          message: 'Dữ liệu phản hồi từ máy chủ không hợp lệ.',
        );
      }
      if (body['status'] == 'error' || body['success'] == false) {
        throw ApiException(
          message: body['message']?.toString() ?? 'Yêu cầu không thành công.',
          statusCode: response.statusCode,
        );
      }
      if (!body.containsKey('data')) {
        throw const ApiException(message: 'Phản hồi từ máy chủ thiếu dữ liệu.');
      }
      return body['data'];
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException(
        message: error.message ?? 'Không thể kết nối đến máy chủ hỗ trợ.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException(message: 'Dữ liệu phiếu hỗ trợ không hợp lệ.');
  }

  @override
  Future<List<SupportCategory>> getCategories() async {
    final data = await _request(
      () => _dio.get(
        '/support/categories',
        queryParameters: const {'group': 'customer'},
      ),
    );
    if (data is! List) {
      throw const ApiException(message: 'Danh mục hỗ trợ không hợp lệ.');
    }
    return data
        .whereType<Map>()
        .map(
          (item) => SupportCategory.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<List<SupportTicket>> getTickets() async {
    final data = _asMap(
      await _request(
        () => _dio.get(
          '/support/tickets',
          queryParameters: const {'group': 'customer', 'page': 1, 'limit': 50},
        ),
      ),
    );
    final items = data['items'];
    if (items is! List) {
      throw const ApiException(message: 'Danh sách phiếu hỗ trợ không hợp lệ.');
    }
    return items
        .whereType<Map>()
        .map((item) => SupportTicket.fromJson(Map<String, dynamic>.from(item)))
        .where((ticket) => ticket.id.isNotEmpty)
        .toList();
  }

  @override
  Future<SupportTicket> getTicket(String ticketId) async {
    final data = _asMap(
      await _request(
        () => _dio.get(
          '/support/tickets/$ticketId',
          queryParameters: const {'group': 'customer'},
        ),
      ),
    );
    return SupportTicket.fromJson(data);
  }

  @override
  Future<SupportTicket> createTicket({
    required String categoryCode,
    required String title,
    required String description,
    List<XFile> attachments = const [],
  }) async {
    final form = FormData()
      ..fields.addAll([
        const MapEntry('support_group', 'customer'),
        MapEntry('ticket_type_cd', categoryCode),
        MapEntry('title', title),
        MapEntry('description', description),
      ]);
    for (final file in attachments) {
      form.files.add(
        MapEntry(
          'attachments',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }
    final data = _asMap(
      await _request(() => _dio.post('/support/tickets', data: form)),
    );
    return SupportTicket.fromJson(data);
  }

  @override
  Future<SupportTicket> replyToTicket({
    required String ticketId,
    required String message,
    List<XFile> attachments = const [],
  }) async {
    final form = FormData()..fields.add(MapEntry('message', message));
    for (final file in attachments) {
      form.files.add(
        MapEntry(
          'attachments',
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }
    final data = _asMap(
      await _request(
        () => _dio.post('/support/tickets/$ticketId/replies', data: form),
      ),
    );
    return SupportTicket.fromJson(data);
  }

  @override
  Future<SupportTicket> updateTicketStatus({
    required String ticketId,
    required String action,
  }) async {
    final data = _asMap(
      await _request(
        () => _dio.patch(
          '/support/tickets/$ticketId/status',
          data: {'action': action},
        ),
      ),
    );
    return SupportTicket.fromJson(data);
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    await _request(() => _dio.delete('/support/tickets/$ticketId'));
  }

  @override
  Future<Uint8List> downloadAttachment({
    required String ticketId,
    required String key,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '/support/tickets/$ticketId/attachments/$key',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ApiException(message: 'Ảnh đính kèm không có dữ liệu.');
      }
      return Uint8List.fromList(bytes);
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException(
        message: error.message ?? 'Không thể tải ảnh đính kèm.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
