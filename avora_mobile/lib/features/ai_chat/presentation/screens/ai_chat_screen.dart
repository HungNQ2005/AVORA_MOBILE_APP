import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_chat_panel.dart';
import '../widgets/ai_header_banner.dart';
import '../widgets/ai_results_section.dart';

/// Trang Trợ lý Du lịch AI: chat + 3 lựa chọn chuẩn nhất.
class AiChatScreen extends ConsumerWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSending = ref.watch(aiChatProvider.select((s) => s.isSending));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trợ lý AI Avora',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiHeaderBanner(
              enabled: !isSending,
              onPrompt: (text) => ref.read(aiChatProvider.notifier).send(text),
            ),
            const SizedBox(height: 16),
            const AiChatPanel(),
            const SizedBox(height: 20),
            const AiResultsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
