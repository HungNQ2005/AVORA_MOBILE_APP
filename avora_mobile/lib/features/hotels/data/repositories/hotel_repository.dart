import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';

/// Provider cung cấp [HotelRepository].
final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  return HotelRepository(dio: ref.watch(apiClientProvider));
});

/// Repository xử lý Data layer cho chức năng Tìm kiếm, lọc và sắp xếp khách sạn.
/// Giao tiếp trực tiếp với Backend Node.js qua endpoint `/hotels`.
class HotelRepository {
  final Dio dio;

  HotelRepository({required this.dio});

  /// Gọi API tìm kiếm, lọc và sắp xếp khách sạn (`GET /api/hotels`).
  Future<HotelSearchResult> searchHotels(HotelSearchParams params) async {
    try {
      // Match destination locally so search supports partial, case-insensitive,
      // and Vietnamese accent-insensitive queries on the mobile app.
      final queryParams = params.copyWith(destination: '').toQueryParams();

      final response = await dio.get(
        '/hotels',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final Map<String, dynamic> rawJson = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final dynamic data = rawJson['data'];
      if (data is! Map) {
        return const HotelSearchResult();
      }

      final dataMap = Map<String, dynamic>.from(data);

      // Kiểm tra trường hợp vượt quá sức chứa phòng (> 5 khách/phòng)
      if (dataMap['exceededCapacity'] == true) {
        final filterStats = dataMap['filterStats'] is Map
            ? FilterStats.fromJson(
                Map<String, dynamic>.from(dataMap['filterStats'] as Map),
              )
            : const FilterStats();

        return HotelSearchResult(
          hotels: const [],
          total: 0,
          filterStats: filterStats,
          exceededCapacity: true,
          message: dataMap['message']?.toString(),
          minRoomsRequired: (dataMap['minRoomsRequired'] as num?)?.toInt(),
          guestsPerRoom: (dataMap['guestsPerRoom'] as num?)?.toInt(),
        );
      }

      // Parse danh sách khách sạn
      final dynamic rawHotelsList = dataMap['hotels'];
      List<HotelModel> parsedHotels = [];
      if (rawHotelsList is List) {
        parsedHotels = rawHotelsList
            .whereType<Map>()
            .map((item) => HotelModel.fromJson(Map<String, dynamic>.from(item)))
            .where((h) => h.hotelStatus.toUpperCase() == 'ACTIVE')
            .toList();
      }

      final destination = _normalizeSearchText(params.destination);
      if (destination.isNotEmpty) {
        final searchTerms = destination.split(' ');
        parsedHotels = parsedHotels.where((hotel) {
          final searchableText = _normalizeSearchText(
            [
              hotel.name,
              hotel.cityName,
              hotel.address,
              hotel.description,
            ].whereType<String>().join(' '),
          );
          final compactSearchableText = searchableText.replaceAll(
            RegExp(r'\s+'),
            '',
          );
          return searchTerms.every(
            (term) =>
                searchableText.contains(term) ||
                compactSearchableText.contains(term.replaceAll(' ', '')),
          );
        }).toList();
      }

      // Parse thống kê filter
      final filterStats = dataMap['filterStats'] is Map
          ? FilterStats.fromJson(
              Map<String, dynamic>.from(dataMap['filterStats'] as Map),
            )
          : const FilterStats();

      final total = destination.isNotEmpty
          ? parsedHotels.length
          : (dataMap['total'] as num?)?.toInt() ?? parsedHotels.length;

      return HotelSearchResult(
        hotels: parsedHotels,
        total: total,
        filterStats: filterStats,
        exceededCapacity: false,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        message: e.message ?? 'Lỗi khi tải danh sách khách sạn.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu khách sạn: $e');
    }
  }

  String _normalizeSearchText(String value) {
    const accentGroups = <String, String>{
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'd': 'đ',
      'e': 'éèẻẽẹêếềểễệ',
      'i': 'íìỉĩị',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'u': 'úùủũụưứừửữự',
      'y': 'ýỳỷỹỵ',
    };
    final replacements = <String, String>{};
    for (final entry in accentGroups.entries) {
      for (final character in entry.value.split('')) {
        replacements[character] = entry.key;
      }
    }

    return value
        .toLowerCase()
        .split('')
        .map((character) {
          return replacements[character] ?? character;
        })
        .join()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
