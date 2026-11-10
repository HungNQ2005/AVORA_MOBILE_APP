import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';
import 'package:avora_mobile/features/home/data/repositories/home_repository.dart';
import 'package:avora_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:avora_mobile/features/support/data/support_models.dart';
import 'package:avora_mobile/features/support/data/support_repository.dart';
import 'package:avora_mobile/features/support/presentation/screens/support_screen.dart';

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
        imageUrl:
            'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
      ),
    ];
  }
}

void main() {
  const testUser = UserModel(
    userId: 'user-001',
    email: 'khachhang@avora.vn',
    fullName: 'Nguyễn Văn A',
    role: 'CUS',
  );

  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
        GoRoute(
          path: '/profile',
          builder: (_, _) =>
              Scaffold(appBar: AppBar(), body: const Text('Profile page')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
        supportRepositoryProvider.overrideWithValue(FakeSupportRepository()),
        authNotifierProvider.overrideWith(
          (ref) => _FakeAuthNotifier(const AuthSuccess(testUser)),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets(
    '✅ HomeScreen hiển thị thông tin người dùng đã đăng nhập và các section chính',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Kiểm tra AppBar & User greeting
      expect(find.text('AVORA'), findsOneWidget);
      expect(find.text('Xin chào, Nguyễn Văn A'), findsNothing);
      expect(find.byKey(const Key('profile_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_avatar_fallback')), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_menu_button')));
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // 2. Kiểm tra Hero & Guarantee Badge
      expect(
        find.text('Cam kết giá tốt nhất thị trường Việt Nam'),
        findsOneWidget,
      );
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
      expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);
    },
  );

  testWidgets('✅ Bấm vào bộ lọc nhanh chuyển đổi trạng thái', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final filterChip = find.text('Miễn phí hủy');
    expect(filterChip, findsOneWidget);

    await tester.tap(filterChip);
    await tester.pumpAndSettle();

    expect(find.text('Đã kích hoạt bộ lọc: Miễn phí hủy'), findsOneWidget);
  });

  testWidgets('✅ Menu avatar mở đúng hồ sơ và xác nhận đăng xuất', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Profile page'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_menu_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
  });

  testWidgets('✅ Trung tâm hỗ trợ mở luồng tạo và xem phiếu hỗ trợ', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hỗ trợ 24/7'));
    await tester.pumpAndSettle();
    expect(find.text('Trung tâm hỗ trợ Avora'), findsOneWidget);
    expect(find.text('Chat trực tuyến với Avora'), findsOneWidget);

    await tester.tap(find.text('Phiếu hỗ trợ của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có yêu cầu hỗ trợ nào.'), findsOneWidget);

    await tester.tap(find.text('Tạo yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Yêu cầu hỗ trợ mới'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Không nhận được xác nhận đặt phòng',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Tôi cần kiểm tra trạng thái yêu cầu đặt phòng của mình.',
    );
    final submitButton = find.text('Gửi yêu cầu');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Không nhận được xác nhận đặt phòng'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Tin nhắn gửi thử');
    await tester.tap(find.byTooltip('Gửi phản hồi'));
    await tester.pumpAndSettle();
    expect(find.text('Tin nhắn gửi thử'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa yêu cầu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có yêu cầu hỗ trợ nào.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('✅ AppBar không tràn ngang trên điện thoại nhỏ', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Thêm lựa chọn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FakeSupportRepository implements SupportRepository {
  SupportTicket? _createdTicket;

  @override
  Future<List<SupportCategory>> getCategories() async => const [
    SupportCategory(code: 'GEN', label: 'Khác'),
    SupportCategory(code: 'BKI', label: 'Vấn đề đơn đặt phòng'),
  ];

  @override
  Future<List<SupportTicket>> getTickets() async =>
      _createdTicket == null ? [] : [_createdTicket!];

  @override
  Future<SupportTicket> getTicket(String ticketId) async {
    return _createdTicket ?? _ticket;
  }

  @override
  Future<SupportTicket> createTicket({
    required String categoryCode,
    required String title,
    required String description,
    List<XFile> attachments = const [],
  }) async {
    _createdTicket = SupportTicket(
      id: 'ticket-1',
      title: title,
      description: description,
      categoryCode: categoryCode,
      categoryLabel: 'Vấn đề đơn đặt phòng',
      status: 'OPN',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      resolvedAt: null,
      resolutionNote: null,
      attachments: const [],
      replies: const [],
    );
    return _createdTicket!;
  }

  @override
  Future<SupportTicket> replyToTicket({
    required String ticketId,
    required String message,
    List<XFile> attachments = const [],
  }) async {
    final ticket = _createdTicket ?? _ticket;
    _createdTicket = SupportTicket(
      id: ticket.id,
      title: ticket.title,
      description: ticket.description,
      categoryCode: ticket.categoryCode,
      categoryLabel: ticket.categoryLabel,
      status: ticket.status,
      createdAt: ticket.createdAt,
      updatedAt: DateTime(2026, 1, 2),
      resolvedAt: ticket.resolvedAt,
      resolutionNote: ticket.resolutionNote,
      attachments: ticket.attachments,
      replies: [
        ...ticket.replies,
        SupportReply(
          id: 'reply-1',
          senderId: 'user-001',
          senderName: 'Nguyễn Văn A',
          message: message,
          createdAt: DateTime(2026, 1, 2),
          attachments: const [],
        ),
      ],
    );
    return _createdTicket!;
  }

  @override
  Future<SupportTicket> updateTicketStatus({
    required String ticketId,
    required String action,
  }) async => _createdTicket ?? _ticket;

  @override
  Future<void> deleteTicket(String ticketId) async {
    _createdTicket = null;
  }

  @override
  Future<Uint8List> downloadAttachment({
    required String ticketId,
    required String key,
  }) async => Uint8List(0);

  static const _ticket = SupportTicket(
    id: 'ticket-1',
    title: 'Yêu cầu hỗ trợ mẫu',
    description: 'Mô tả mẫu',
    categoryCode: 'GEN',
    categoryLabel: 'Khác',
    status: 'OPN',
    createdAt: null,
    updatedAt: null,
    resolvedAt: null,
    resolutionNote: null,
    attachments: [],
    replies: [],
  );
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
