import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_chat_models.dart';
import '../providers/ai_chat_provider.dart';

/// Khung chat với Avora AI Concierge.
class AiChatPanel extends ConsumerStatefulWidget {
  final double height;

  const AiChatPanel({super.key, this.height = 440});

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _submit([String? text]) {
    final value = (text ?? _inputController.text).trim();
    if (value.isEmpty) return;
    _inputController.clear();
    ref.read(aiChatProvider.notifier).send(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isSending != next.isSending) {
        _scrollToBottom();
      }
    });

    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const _Avatar(),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avora AI Concierge',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 7, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Đang phân tích hành trình · Có mặt',
                            style: TextStyle(
                                fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cuộc trò chuyện mới',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                  onPressed: state.isSending
                      ? null
                      : () => ref.read(aiChatProvider.notifier).reset(),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length + (state.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.messages.length) {
                  return const _TypingBubble();
                }
                final msg = state.messages[index];
                final isLast = index == state.messages.length - 1;
                return _MessageBubble(
                  message: msg,
                  showQuickReplies: isLast && !state.isSending,
                  onQuickReply: _submit,
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !state.isSending,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 500,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      hintText: 'Nhập yêu cầu của bạn tại đây...',
                      hintStyle: const TextStyle(fontSize: 12.5),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                  ),
                  onPressed: state.isSending ? null : _submit,
                  icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF003580), Color(0xFF0284C7)],
        ),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiChatMessage message;
  final bool showQuickReplies;
  final ValueChanged<String> onQuickReply;

  const _MessageBubble({
    required this.message,
    required this.showQuickReplies,
    required this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = isUser
        ? const Color(0xFF003580)
        : (message.isError ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9));
    final fg = isUser
        ? Colors.white
        : (message.isError ? const Color(0xFFB91C1C) : const Color(0xFF1E293B));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[const _Avatar(), const SizedBox(width: 8)],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isUser ? 14 : 3),
                      bottomRight: Radius.circular(isUser ? 3 : 14),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: fg, fontSize: 13, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          if (showQuickReplies && message.quickReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 42),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.quickReplies
                    .map(
                      (q) => ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        labelStyle: const TextStyle(color: Color(0xFF003580)),
                        onPressed: () => onQuickReply(q),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _Avatar(),
          SizedBox(width: 8),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Avora đang phân tích...',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
