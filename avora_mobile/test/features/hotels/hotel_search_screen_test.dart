import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';
import 'package:avora_mobile/features/hotels/data/repositories/hotel_repository.dart';
import 'package:avora_mobile/features/hotels/presentation/screens/hotel_search_screen.dart';
import 'package:avora_mobile/features/hotels/presentation/widgets/hotel_search_card.dart';

// Fake HotelRepository cho UI widget test
class FakeHotelRepository implements HotelRepository {
  final bool returnEmpty;
  final bool returnExceeded;
  final bool returnError;

  FakeHotelRepository({
    this.returnEmpty = false,
    this.returnExceeded = false,
    this.returnError = false,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<HotelSearchResult> searchHotels(HotelSearchParams params) async {
    if (returnError) {
      throw Exception('Không thể kết nối đến máy chủ.');
    }

    if (returnExceeded || params.guestsPerRoom > 5) {
      return const HotelSearchResult(
        hotels: [],
        total: 0,
        exceededCapacity: true,
        message: 'Vượt quá sức chứa tối đa của 1 phòng là 5 người.',
        minRoomsRequired: 2,
        guestsPerRoom: 6,
      );
    }

    if (returnEmpty) {
      return const HotelSearchResult(
        hotels: [],
        total: 0,
        filterStats: FilterStats(),
      );
    }

    return const HotelSearchResult(
      hotels: [
        HotelModel(
          hotelId: 'hotel-001',
          name: 'Avora Da Nang Resort & Spa',
          address: 'Bạch Đằng, Đà Nẵng',
          cityName: 'Đà Nẵng',
          starQuality: 5,
          starRating: 9.5,
          scoreLabel: 'Tuyệt hảo',
          reviewsCount: 1250,
          price: 1800000,
          originalPrice: 2400000,
          isGenius: true,
          availableRooms: 3,
          facilities: [
            HotelFacility(id: 'fac-1', name: 'Bãi biển riêng'),
            HotelFacility(id: 'fac-2', name: 'Hồ bơi vô cực'),
          ],
          roomHighlight: RoomHighlight(
            roomTypeId: 'rt-1',
            name: 'Phòng Deluxe Hướng Biển',
            bedType: '1 giường đôi lớn',
            roomSize: '40 m²',
          ),
          cancellationPolicy: CancellationPolicy(
            freeBeforeHours: 48,
            description: 'Miễn phí hủy phòng trước 48h',
          ),
        ),
      ],
      total: 1,
      filterStats: FilterStats(
        totalCount: 1,
        star5Count: 1,
        rating9Count: 1,
      ),
    );
  }
}

Widget createTestWidget({required HotelRepository repository}) {
  return ProviderScope(
    overrides: [
      hotelRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: HotelSearchScreen(
        initialDestination: 'Đà Nẵng',
      ),
    ),
  );
}

void main() {
  group('HotelSearchScreen Widget Tests (Chức năng 1)', () {
    testWidgets('✅ Hiển thị đầy đủ thanh tìm kiếm, bộ lọc, sắp xếp và thẻ khách sạn',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(repository: FakeHotelRepository()),
      );
      await tester.pumpAndSettle();

      // Kiểm tra thanh tìm kiếm
      expect(find.text('Đà Nẵng'), findsOneWidget);

      // Kiểm tra nút Sắp xếp & Bộ lọc
      expect(find.text('Phổ biến nhất'), findsOneWidget);
      expect(find.text('Bộ lọc'), findsOneWidget);
      expect(find.text('Tìm thấy 1 chỗ nghỉ'), findsOneWidget);

      // Kiểm tra thẻ khách sạn
      expect(find.byType(HotelSearchCard), findsOneWidget);
      expect(find.text('Avora Da Nang Resort & Spa'), findsOneWidget);
      expect(find.text('Genius VIP'), findsOneWidget);
      expect(find.text('9.5'), findsOneWidget);
      expect(find.text('Tuyệt hảo'), findsOneWidget);
      expect(find.text('Xem phòng trống'), findsOneWidget);
    });

    testWidgets('✅ Mở Modal Sắp xếp và chọn tùy chọn Giá thấp nhất',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(repository: FakeHotelRepository()),
      );
      await tester.pumpAndSettle();

      // Bấm vào nút Sắp xếp
      await tester.tap(find.text('Phổ biến nhất'));
      await tester.pumpAndSettle();

      // Modal hiển thị các tùy chọn
      expect(find.text('Sắp xếp theo'), findsOneWidget);
      expect(find.text('Giá (thấp đến cao)'), findsOneWidget);
      expect(find.text('Điểm đánh giá & Giá tốt'), findsOneWidget);

      // Chọn Giá (thấp đến cao)
      await tester.tap(find.text('Giá (thấp đến cao)'));
      await tester.pumpAndSettle();

      // Nút hiển thị nhãn mới
      expect(find.text('Giá thấp nhất'), findsOneWidget);
    });

    testWidgets('✅ Mở Modal Bộ lọc tìm kiếm và kiểm tra các tiêu chí',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(repository: FakeHotelRepository()),
      );
      await tester.pumpAndSettle();

      // Bấm nút Bộ lọc
      await tester.tap(find.text('Bộ lọc'));
      await tester.pumpAndSettle();

      // Kiểm tra các phần trong Modal Bộ lọc
      expect(find.text('Bộ lọc tìm kiếm'), findsOneWidget);
      expect(find.text('Chỉ hiển thị chỗ nghỉ còn phòng'), findsOneWidget);
      expect(find.text('SỨC CHỨA & LOẠI GIƯỜNG'), findsOneWidget);
      expect(find.text('NGÂN SÁCH MỖI ĐÊM'), findsOneWidget);
      expect(find.text('XẾP HẠNG SAO'), findsOneWidget);
      expect(find.text('Áp dụng bộ lọc'), findsOneWidget);

      // Đóng modal
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
    });

    testWidgets('⚠️ Hiển thị cảnh báo khi vượt quá sức chứa phòng (> 5 người/phòng)',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          repository: FakeHotelRepository(returnExceeded: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vượt quá sức chứa phòng'), findsOneWidget);
      expect(find.textContaining('Vượt quá sức chứa tối đa của 1 phòng'),
          findsOneWidget);
    });

    testWidgets('🔍 Hiển thị giao diện dữ liệu rỗng khi không tìm thấy khách sạn',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          repository: FakeHotelRepository(returnEmpty: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tìm thấy khách sạn phù hợp'), findsOneWidget);
      expect(find.text('Tìm thấy 0 chỗ nghỉ'), findsOneWidget);
    });

    testWidgets('❌ Hiển thị giao diện lỗi và nút Thử lại khi có lỗi mạng',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          repository: FakeHotelRepository(returnError: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
