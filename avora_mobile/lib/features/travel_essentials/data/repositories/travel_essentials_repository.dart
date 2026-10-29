import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/packing_item_model.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/destination_weather_model.dart';

const String _kPackingStorageKey = 'avora_travel_packing_list_v1';

final travelEssentialsRepositoryProvider =
    Provider<TravelEssentialsRepository>((ref) {
  return TravelEssentialsRepository(
    storage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});

class TravelEssentialsRepository {
  final FlutterSecureStorage _storage;

  TravelEssentialsRepository({required FlutterSecureStorage storage})
      : _storage = storage;

  /// Lấy danh sách đồ cần chuẩn bị
  Future<List<PackingItem>> getPackingList() async {
    try {
      final raw = await _storage.read(key: _kPackingStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        return decoded
            .map((e) => PackingItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}

    final defaults = _getDefaultPackingItems();
    await savePackingList(defaults);
    return defaults;
  }

  Future<void> savePackingList(List<PackingItem> items) async {
    try {
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await _storage.write(key: _kPackingStorageKey, value: encoded);
    } catch (_) {}
  }

  Future<List<PackingItem>> resetToDefaults() async {
    final defaults = _getDefaultPackingItems();
    await savePackingList(defaults);
    return defaults;
  }

  List<PackingItem> _getDefaultPackingItems() {
    return const [
      PackingItem(id: 'doc_1', title: 'CCCD / Hộ chiếu (Passport)', category: 'documents'),
      PackingItem(id: 'doc_2', title: 'Xác nhận đặt phòng Avora (E-Voucher)', category: 'documents'),
      PackingItem(id: 'doc_3', title: 'Bằng lái xe & Giấy tờ xe', category: 'documents'),
      PackingItem(id: 'doc_4', title: 'Thẻ ATM / Thẻ tín dụng & Tiền mặt', category: 'documents'),

      PackingItem(id: 'clo_1', title: 'Quần áo mặc hàng ngày (3-4 bộ)', category: 'clothes'),
      PackingItem(id: 'clo_2', title: 'Đồ bơi / Đồ dạo biển', category: 'clothes'),
      PackingItem(id: 'clo_3', title: 'Áo khoác gió nhẹ / Áo chống nắng', category: 'clothes'),
      PackingItem(id: 'clo_4', title: 'Kính râm & Mũ rộng vành', category: 'clothes'),
      PackingItem(id: 'clo_5', title: 'Giày thể thao & Dép quai hậu', category: 'clothes'),

      PackingItem(id: 'ele_1', title: 'Điện thoại & Củ cáp sạc nhanh', category: 'electronics'),
      PackingItem(id: 'ele_2', title: 'Pin sạc dự phòng (Powerbank)', category: 'electronics'),
      PackingItem(id: 'ele_3', title: 'Tai nghe Bluetooth', category: 'electronics'),
      PackingItem(id: 'ele_4', title: 'Máy ảnh / Gậy selfie', category: 'electronics'),

      PackingItem(id: 'med_1', title: 'Kem chống nắng & Kem dưỡng ẩm', category: 'toiletries'),
      PackingItem(id: 'med_2', title: 'Thuốc say xe, thuốc hạ sốt, men tiêu hóa', category: 'toiletries'),
      PackingItem(id: 'med_3', title: 'Băng cá nhân & Xịt chống muỗi', category: 'toiletries'),
      PackingItem(id: 'med_4', title: 'Bàn chải, kem đánh răng & Đồ skincare mini', category: 'toiletries'),
    ];
  }

  List<DestinationWeather> getDestinationWeatherList() {
    return const [
      DestinationWeather(
        cityId: 'DAD',
        cityName: 'Đà Nẵng',
        temperature: 28,
        condition: 'Nắng ấm, gió nhẹ',
        weatherCode: 'sunny',
        humidity: 68,
        uvIndex: 7,
        clothingAdvice: 'Trang phục hè nhẹ mát, mang kính râm và mũ khi tắm biển Mỹ Khê.',
        travelTips: [
          'Thích hợp ngắm cầu Rồng phun lửa vào tối thứ 7 & CN.',
          'Nên tắm biển vào sáng sớm hoặc sau 16:00 chiều.',
        ],
      ),
      DestinationWeather(
        cityId: 'PQC',
        cityName: 'Phú Quốc',
        temperature: 30,
        condition: 'Trời trong, biển êm',
        weatherCode: 'sunny',
        humidity: 72,
        uvIndex: 8,
        clothingAdvice: 'Quần áo đi biển sặc sỡ, kem chống nắng SPF 50+, mũ cói rộng vành.',
        travelTips: [
          'Hoàng hôn tại Bãi Sao và Sunset Sanato tuyệt đẹp từ 17:15.',
          'Đi cáp treo Hòn Thơm nhớ chuẩn bị đồ bơi công viên nước.',
        ],
      ),
      DestinationWeather(
        cityId: 'NHA',
        cityName: 'Nha Trang',
        temperature: 29,
        condition: 'Nắng chan hòa, trời xanh',
        weatherCode: 'sunny',
        humidity: 66,
        uvIndex: 8,
        clothingAdvice: 'Trang phục dạo phố thoáng mát, váy maxi và đồ bơi.',
        travelTips: [
          'Thưởng thức nem nướng Ninh Hòa và bánh căn phố Tháp Bà.',
          'Đặt tour đảo cano nên chọn tour VIP xuất phát trước 8:30 sáng.',
        ],
      ),
      DestinationWeather(
        cityId: 'DLI',
        cityName: 'Đà Lạt',
        temperature: 19,
        condition: 'Se lạnh sương sớm, nắng dịu',
        weatherCode: 'cool',
        humidity: 78,
        uvIndex: 5,
        clothingAdvice: 'Áo len mỏng, áo khoác ấm, khăn quàng cổ nhẹ vào buổi tối.',
        travelTips: [
          'Nhiệt độ giảm sâu về đêm (khoảng 14-16°C), nhớ giữ ấm cổ.',
          'Săn mây Cầu Đất nên thức dậy từ 4:30 sáng.',
        ],
      ),
      DestinationWeather(
        cityId: 'HAN',
        cityName: 'Hà Nội',
        temperature: 24,
        condition: 'Mát mẻ, gió thu nhẹ',
        weatherCode: 'cloudy',
        humidity: 62,
        uvIndex: 4,
        clothingAdvice: 'Trang phục thoải mái, mang áo khoác mỏng khi dạo phố đêm.',
        travelTips: [
          'Dạo bộ quanh Hồ Gươm và thưởng thức cafe trứng Giảng.',
          'Phố đi bộ mở cửa từ tối thứ 6 đến hết chủ nhật.',
        ],
      ),
      DestinationWeather(
        cityId: 'SGN',
        cityName: 'TP. Hồ Chí Minh',
        temperature: 32,
        condition: 'Nắng ban ngày, dịu mát về đêm',
        weatherCode: 'sunny',
        humidity: 65,
        uvIndex: 9,
        clothingAdvice: 'Áo phông cotton thoáng mát, mang ô dù nhỏ đề phòng mưa rào nhanh.',
        travelTips: [
          'Ngắm toàn cảnh thành phố từ Waterbus sông Sài Gòn hoàng hôn.',
          'Trải nghiệm ẩm thực đêm tại phố đi bộ Nguyễn Huệ & Bùi Viện.',
        ],
      ),
      DestinationWeather(
        cityId: 'UIH',
        cityName: 'Quy Nhơn',
        temperature: 27,
        condition: 'Nắng gió trong lành',
        weatherCode: 'sunny',
        humidity: 70,
        uvIndex: 7,
        clothingAdvice: 'Trang phục năng động để đi cano và trekking Kỳ Co - Eo Gió.',
        travelTips: [
          'Kỳ Co biển xanh ngọc bích, chụp ảnh đẹp nhất lúc 9:00 - 11:00.',
          'Thưởng thức bánh xèo tôm nhảy rau mầm tươi ngon.',
        ],
      ),
      DestinationWeather(
        cityId: 'HUI',
        cityName: 'Huế',
        temperature: 25,
        condition: 'Dịu mát, nhiều mây',
        weatherCode: 'cloudy',
        humidity: 75,
        uvIndex: 5,
        clothingAdvice: 'Trang phục lịch sự, kín đáo khi tham quan Đại Nội và các lăng tẩm.',
        travelTips: [
          'Nghe ca Huế trên sông Hương và thả hoa đăng cầu may.',
          'Thử bún bò mụ Rơi và chè hẻm 20 món trứ danh.',
        ],
      ),
    ];
  }
}
