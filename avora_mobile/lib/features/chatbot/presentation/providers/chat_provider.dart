import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../data/chat_repository.dart';

const chatGreeting = ChatMessage(
  role: 'assistant',
  local: true,
  content:
      'Xin chào! Tôi là Trợ lý AI hỗ trợ của sàn AVORA. Tôi có thể giúp bạn tìm khách sạn, gợi ý địa điểm du lịch và giải đáp các thắc mắc về đặt phòng.',
);

const chatQuickPrompts = [
  'Khách sạn nào gần tôi?',
  'Gợi ý địa điểm du lịch quanh đây',
  'Có mã giảm giá nào không?',
  'Đơn đặt phòng gần đây của tôi',
];

enum GeoStatus {
  idle,
  asking,
  granted,
  denied,
  unavailable,
}

extension GeoStatusX on GeoStatus {
  String get label => switch (this) {
        GeoStatus.idle => 'Luôn sẵn sàng hỗ trợ',
        GeoStatus.asking => '📍 Đang xin quyền vị trí…',
        GeoStatus.granted => '📍 Đã nhận vị trí của bạn',
        GeoStatus.denied => '📍 Chưa có vị trí (bạn đã từ chối)',
        GeoStatus.unavailable => '📍 Thiết bị không hỗ trợ định vị',
      };
}

class UserLocation {
  final double lat;
  final double lng;
  const UserLocation({required this.lat, required this.lng});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool loading;
  final bool isOpen;
  final GeoStatus geoStatus;
  final UserLocation? userLocation;

  const ChatState({
    this.messages = const [chatGreeting],
    this.loading = false,
    this.isOpen = false,
    this.geoStatus = GeoStatus.idle,
    this.userLocation,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? isOpen,
    GeoStatus? geoStatus,
    UserLocation? userLocation,
    bool clearLocation = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        isOpen: isOpen ?? this.isOpen,
        geoStatus: geoStatus ?? this.geoStatus,
        userLocation: clearLocation ? null : (userLocation ?? this.userLocation),
      );
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  // Đăng xuất → tạo lại notifier → xóa hội thoại (giống web).
  ref.watch(authNotifierProvider.select((s) => s is AuthSuccess));
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  bool _askedGeo = false;

  ChatNotifier(this._ref) : super(const ChatState());

  static final _hotelPathRe = RegExp(
    r'^/(?:hotels?|hotel-detail)/([0-9a-fA-F-]{36})',
  );

  void setOpen(bool open) {
    state = state.copyWith(isOpen: open);
    if (open) {
      requestLocation();
    }
  }

  Future<void> requestLocation({bool force = false}) async {
    if (_askedGeo && !force) return;
    _askedGeo = true;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        geoStatus: GeoStatus.unavailable,
        clearLocation: true,
      );
      return;
    }

    state = state.copyWith(geoStatus: GeoStatus.asking);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          geoStatus: GeoStatus.denied,
          clearLocation: true,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        geoStatus: GeoStatus.denied,
        clearLocation: true,
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
      state = state.copyWith(
        geoStatus: GeoStatus.granted,
        userLocation: UserLocation(
          lat: position.latitude,
          lng: position.longitude,
        ),
      );
    } catch (_) {
      state = state.copyWith(
        geoStatus: GeoStatus.denied,
        clearLocation: true,
      );
    }
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.loading) return;

    final history = state.messages;
    state = state.copyWith(
      messages: [...history, ChatMessage(role: 'user', content: text)],
      loading: true,
    );

    // Ngữ cảnh trang hiện tại (backend dùng để trả lời sát ngữ cảnh)
    final uri = _ref.read(routerProvider).routeInformationProvider.value.uri;
    final hotelId = _hotelPathRe.firstMatch(uri.path)?.group(1) ?? '';

    String reply;
    try {
      reply = await _ref.read(chatRepositoryProvider).send(
            message: text,
            history: history,
            currentPage: uri.path,
            currentHotelId: hotelId,
            lat: state.userLocation?.lat,
            lng: state.userLocation?.lng,
          );
    } catch (e) {
      reply = _errorMessage(e);
    }

    if (!mounted) return;
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: 'assistant', content: reply),
      ],
      loading: false,
    );
  }

  String _errorMessage(Object e) {
    final inner = (e as dynamic).error;
    if (inner is ApiException) {
      if (inner.statusCode == 401) {
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
      return inner.message;
    }
    return 'Trợ lý AI đang gặp sự cố, vui lòng thử lại sau.';
  }
}
