import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';
import 'package:avora_mobile/features/home/data/repositories/home_repository.dart';
import 'package:avora_mobile/features/home/presentation/screens/home_screen.dart';

// Fake HomeRepository để test UI không cần gọi network thật
class FakeHomeRepository implements HomeRepository {
  @override
  Future<List<HotelModel>> fetchHotels({
    String? destination,
    String? checkIn,
    String? checkOut,
    int? adults,
    int? children,
    int? rooms,
  }) async {
    return [
      const HotelModel(
        hotelId: 'hotel-001',
        name: 'Avora Da Nang Resort',
        address: 'Bạch Đằng, Đà Nẵng',
        cityName: 'Đà Nẵng',
        starQuality: 5,
        starRating: 9.5,
        scoreLabel: 'Xuất sắc',
        reviewsCount: 890,
        price: 1500000,
        originalPrice: 2000000,
        isGenius: true,
      ),
    ];
  }

  @override
  List<TrendingDestination> getTrendingDestinations() {
    return const [
      TrendingDestination(
        name: 'Đà Nẵng',
        subtitle: '1.842 chỗ nghỉ',
        imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b',
        tag: '📍 Điểm đến số 1',
        startingPrice: 'Từ 480.000đ/đêm',
      ),
      TrendingDestination(
        name: 'Phú Quốc',
        subtitle: '965 chỗ nghỉ',
        imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
      ),
    ];
  }
}

void main() {
  const testUser = UserModel(
    userId: 'user-001',
    email: 'khachhang@avora.vn',
    fullName: 'Nguyễn Văn A',
  );

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
        authNotifierProvider.overrideWith(
          (ref) => _FakeAuthNotifier(const AuthSuccess(testUser)),
        ),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('✅ HomeScreen hiển thị thông tin người dùng đã đăng nhập và các section chính',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // 1. Kiểm tra AppBar & User greeting
    expect(find.text('AVORA'), findsOneWidget);
    expect(find.text('Xin chào, Nguyễn Văn A'), findsOneWidget);

    // 2. Kiểm tra Hero & Guarantee Badge
    expect(find.text('Cam kết giá tốt nhất thị trường Việt Nam'), findsOneWidget);
    expect(find.text('Tìm chỗ nghỉ tiếp theo tại Việt Nam'), findsOneWidget);

    // 3. Kiểm tra Search Card components
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tìm kiếm khách sạn'), findsOneWidget);

    // 4. Kiểm tra Quick Filter Pills
    expect(find.text('Gần vị trí'), findsOneWidget);
    expect(find.text('Miễn phí hủy'), findsOneWidget);
    expect(find.text('Thanh toán tại chỗ'), findsOneWidget);
    expect(find.text('Ưu đãi Genius'), findsOneWidget);

    // 5. Kiểm tra Promo Banner
    expect(find.text('ƯU ĐÃI MÙA HÈ'), findsOneWidget);
    expect(find.text('Du ngoạn ngắm cảnh Việt Nam'), findsOneWidget);

    // 6. Kiểm tra Trending destinations
    expect(find.text('Điểm đến thịnh hành'), findsOneWidget);
    expect(find.text('Đà Nẵng'), findsWidgets);

    // 7. Kiểm tra Section Khách sạn yêu thích
    expect(find.text('Chỗ nghỉ được khách yêu thích nhất'), findsOneWidget);
    expect(find.text('Avora Da Nang Resort'), findsOneWidget);
  });

  testWidgets('✅ Bấm vào bộ lọc nhanh chuyển đổi trạng thái', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final filterChip = find.text('Miễn phí hủy');
    expect(filterChip, findsOneWidget);

    await tester.tap(filterChip);
    await tester.pumpAndSettle();

    expect(find.text('Đã kích hoạt bộ lọc: Miễn phí hủy'), findsOneWidget);
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
