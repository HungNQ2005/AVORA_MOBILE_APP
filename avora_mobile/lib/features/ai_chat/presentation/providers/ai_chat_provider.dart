import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import '../../data/models/ai_chat_models.dart';
import '../../data/repositories/ai_chat_repository.dart';

const _greeting = AiChatMessage(
  isUser: false,
  text:
      'Chào bạn! Mình là Avora AI Concierge. Hãy cho mình biết điểm đến, ngày đi, số người và ngân sách — '
      'mình sẽ chọn ra 3 chỗ nghỉ phù hợp nhất từ dữ liệu Avora.',
  quickReplies: [
    'Đà Nẵng 2 đêm, 2 lớn 1 nhỏ, dưới 5 triệu',
    'Phú Quốc nghỉ dưỡng, ngân sách 3 triệu/đêm',
  ],
);

class AiChatState extends Equatable {
  final List<AiChatMessage> messages;
  final List<AiHotelPick> picks;
  final AiSearchSummary? summary;
  final Map<String, dynamic> criteria;
  final bool isSending;

  const AiChatState({
    this.messages = const [_greeting],
    this.picks = const [],
    this.summary,
    this.criteria = const {},
    this.isSending = false,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    List<AiHotelPick>? picks,
    AiSearchSummary? summary,
    Map<String, dynamic>? criteria,
    bool? isSending,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      picks: picks ?? this.picks,
      summary: summary ?? this.summary,
      criteria: criteria ?? this.criteria,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, picks, summary, criteria, isSending];
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiChatRepository _repo;

  AiChatNotifier(this._repo) : super(const AiChatState()) {
    loadInitialPicks();
  }

  Future<void> loadInitialPicks() async {
    try {
      final res = await _repo.getInitialRecommendations();
      if (mounted) {
        state = state.copyWith(
          picks: res.hotels,
          summary: res.summary,
          criteria: res.criteria,
          messages: [
            ...state.messages,
            AiChatMessage(
              isUser: false,
              text: res.reply,
              quickReplies: res.quickReplies,
            ),
          ],
        );
      }
    } catch (_) {}
  }

  Future<void> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || state.isSending) return;

    final withUser = [...state.messages, AiChatMessage(isUser: true, text: content)];
    state = state.copyWith(messages: withUser, isSending: true);

    final history = withUser
        .where((m) => !m.isError)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    try {
      final res = await _repo.chat(messages: history, criteria: state.criteria);
      state = state.copyWith(
        messages: [
          ...state.messages,
          AiChatMessage(
            isUser: false,
            text: res.reply,
            quickReplies: res.quickReplies,
          ),
        ],
        criteria: res.criteria,
        picks: res.hotels.isNotEmpty ? res.hotels : state.picks,
        summary: res.summary ?? state.summary,
        isSending: false,
      );
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Đã có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  void _fail(String message) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        AiChatMessage(isUser: false, text: message, isError: true),
      ],
      isSending: false,
    );
  }

  void reset() => state = const AiChatState();
}

final aiChatProvider =
    StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref.watch(aiChatRepositoryProvider));
});
