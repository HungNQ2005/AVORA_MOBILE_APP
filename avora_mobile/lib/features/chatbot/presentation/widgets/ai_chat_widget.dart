import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../providers/chat_provider.dart';

const _navy = Color(0xFF003580);
const _blue = Color(0xFF006CE4);
const _gold = Color(0xFFFFC107);

const _brandGradient = LinearGradient(
  colors: [_navy, _blue],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Nút nổi mở popup Trợ lý AI. Chỉ là UI: toàn bộ xử lý nằm ở backend web (/api/chat).
class AiChatFab extends ConsumerWidget {
  const AiChatFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(
      authNotifierProvider.select((s) => s is AuthSuccess),
    );
    final isOpen = ref.watch(chatProvider.select((s) => s.isOpen));

    // Ẩn nút bong bóng nếu chưa đăng nhập hoặc popup chat đang được mở
    if (!loggedIn || isOpen) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 24 + MediaQuery.of(context).padding.bottom,
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        shape: const CircleBorder(side: BorderSide(color: _gold, width: 2)),
        child: Ink(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: _brandGradient,
          ),
          child: InkWell(
            key: const Key('avora-ai-chat-fab'),
            customBorder: const CircleBorder(),
            onTap: () => _open(ref),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  void _open(WidgetRef ref) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    
    // Đánh dấu popup đã mở để ẩn nút FAB
    ref.read(chatProvider.notifier).setOpen(true);

    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiChatPanel(),
    ).whenComplete(() {
      // Khi đóng bottom sheet (bằng nút X, vuốt xuống, bấm ra ngoài), hiện lại nút FAB
      ref.read(chatProvider.notifier).setOpen(false);
    });
  }
}

/// Nội dung popup chat.
class AiChatPanel extends ConsumerStatefulWidget {
  const AiChatPanel({super.key});

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).send(text);
  }

  void _openLink(String href) {
    var path = href.trim().replaceFirst(
      RegExp(r'^https?://(localhost(:\d+)?|[^/]*avora[^/]*)', caseSensitive: false),
      '',
    );
    if (!path.startsWith('/')) return;
    // Web: /hotels/:id hoặc /hotel-detail/:id → App: /hotel/:id
    final m = RegExp(r'^/(?:hotels?|hotel-detail)/([0-9a-fA-F-]{36})').firstMatch(path);
    if (m != null) path = AppRoutes.hotelDetailPath(m.group(1)!);
    Navigator.of(context).pop();
    ref.read(routerProvider).push(path);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    ref.listen(chatProvider, (_, _) => _scrollToEnd());
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _header(context, chat),
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(14),
                  children: [
                    for (final m in chat.messages) _Bubble(m, onLink: _openLink),
                    if (chat.messages.length == 1)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final q in chatQuickPrompts)
                            ActionChip(
                              label: Text(q, style: const TextStyle(fontSize: 12, color: _navy)),
                              backgroundColor: const Color(0xFFF0F7FF),
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              shape: const StadiumBorder(),
                              onPressed: () => _send(q),
                            ),
                        ],
                      ),
                    if (chat.loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Trợ lý đang soạn câu trả lời…',
                          style: TextStyle(color: _navy, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _footer(chat.loading),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ChatState chat) {
    final isDenied = chat.geoStatus == GeoStatus.denied;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      decoration: const BoxDecoration(
        gradient: _brandGradient,
        border: Border(bottom: BorderSide(color: _gold, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ lý AI AVORA',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (isDenied)
                  GestureDetector(
                    onTap: () => ref.read(chatProvider.notifier).requestLocation(force: true),
                    child: Text(
                      '${chat.geoStatus.label} – chạm để cấp lại',
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    chat.geoStatus.label,
                    style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _footer(bool loading) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('avora-ai-chat-input'),
                  controller: _controller,
                  enabled: !loading,
                  maxLength: 1000,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Nhập câu hỏi của bạn…',
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: _blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('avora-ai-chat-send'),
                style: IconButton.styleFrom(backgroundColor: _navy, foregroundColor: _gold),
                onPressed: loading ? null : _send,
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String href) onLink;
  const _Bubble(this.message, {required this.onLink});

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final color = user ? Colors.white : const Color(0xFF1F2937);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          gradient: user ? _brandGradient : null,
          color: user ? null : Colors.white,
          border: user ? null : Border.all(color: const Color(0xFFDBEAFE)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(user ? 14 : 4),
            bottomRight: Radius.circular(user ? 4 : 14),
          ),
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(color: color, fontSize: 14, height: 1.5),
            children: _parse(_normalize(message.content), user),
          ),
        ),
      ),
    );
  }

  /// Chuẩn hóa markdown giống web: bảng → danh sách, bỏ tiêu đề, gạch đầu dòng → •.
  static String _normalize(String text) {
    final out = <String>[];
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (RegExp(r'^\|?[\s:|-]+\|?$').hasMatch(t) && t.contains('-') && t.contains('|')) {
        continue;
      }
      if (t.startsWith('|')) {
        final cells = t.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
        out.add(cells.length > 1
            ? '• ${cells.first}: ${cells.skip(1).join(' – ')}'
            : '• ${cells.isEmpty ? '' : cells.first}');
        continue;
      }
      out.add(line
          .replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '')
          .replaceFirst(RegExp(r'^\s*[-*]\s+'), '• '));
    }
    return out.join('\n');
  }

  /// [text](/path) → link bấm được, **text** → chữ đậm.
  List<InlineSpan> _parse(String text, bool user) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\[([^\]]+)\]\(([^)]+)\)|\*\*([^*]+)\*\*');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      if (m.group(1) != null) {
        final href = m.group(2)!;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => onLink(href),
            child: Text(
              m.group(1)!,
              style: TextStyle(
                color: user ? Colors.white : _blue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: m.group(3),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }
}
