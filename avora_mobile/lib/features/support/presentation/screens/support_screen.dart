import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/support_models.dart';
import '../../data/support_repository.dart';

const _navy = Color(0xFF003580);
const _pageBackground = Color(0xFFF4F6FA);
const _maxImages = 3;
const _maxImageBytes = 2 * 1024 * 1024;
const _maxTotalImageBytes = 6 * 1024 * 1024;
final _linkPattern = RegExp(
  r'(?:https?://|www\.)\S+|\b[a-z0-9-]+(?:\.[a-z0-9-]+)+(?:/\S*)?',
  caseSensitive: false,
);

String _errorText(Object error) {
  if (error is ApiException) return error.message;
  if (error is FormatException) return error.message;
  return 'Đã xảy ra lỗi: $error';
}

int _wordCount(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? 0 : normalized.split(RegExp(r'\s+')).length;
}

Future<List<XFile>?> _pickSupportImages(List<XFile> existing) async {
  final picked = await ImagePicker().pickMultiImage();
  if (picked.isEmpty) return null;
  final images = [...existing, ...picked];
  if (images.length > _maxImages) {
    throw const FormatException('Chỉ được đính kèm tối đa 3 ảnh.');
  }

  var totalBytes = 0;
  for (final image in images) {
    final extension = image.name.split('.').last.toLowerCase();
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      throw const FormatException('Chỉ chấp nhận ảnh JPEG, PNG hoặc WEBP.');
    }
    final bytes = await image.length();
    if (bytes > _maxImageBytes) {
      throw const FormatException('Mỗi ảnh không được vượt quá 2 MB.');
    }
    totalBytes += bytes;
  }
  if (totalBytes > _maxTotalImageBytes) {
    throw const FormatException(
      'Tổng dung lượng ảnh không được vượt quá 6 MB.',
    );
  }
  return images;
}

String _statusLabel(SupportTicket ticket) {
  if (ticket.status == 'RSV' && ticket.resolvedAt != null) {
    return 'Đã xác nhận giải quyết';
  }
  return switch (ticket.status) {
    'OPN' => 'Mới',
    'INP' => 'Đang xử lý',
    'WAT' => 'Chờ phản hồi',
    'RSV' => 'Chờ xác nhận giải quyết',
    'CLS' => 'Đã đóng',
    _ => ticket.status,
  };
}

String _formatDate(DateTime? date) =>
    date == null ? '—' : DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  late final SupportRepository _repository;
  List<SupportTicket> _tickets = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(supportRepositoryProvider);
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthSuccess && _isCustomer(authState.user.role)) {
      _loadTickets();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tickets = await _repository.getTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(error);
        _loading = false;
      });
    }
  }

  Future<void> _openCreateTicket() async {
    final ticket = await Navigator.of(context).push<SupportTicket>(
      MaterialPageRoute(
        builder: (_) => SupportCreateScreen(repository: _repository),
      ),
    );
    if (!mounted || ticket == null) return;
    await _loadTickets();
    if (!mounted) return;
    await _openTicket(ticket.id);
  }

  Future<void> _openTicket(String ticketId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            SupportTicketScreen(ticketId: ticketId, repository: _repository),
      ),
    );
    if (mounted) await _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthSuccess || !_isCustomer(authState.user.role)) {
      return Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          title: const Text('Phiếu hỗ trợ'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chức năng phiếu hỗ trợ chỉ dành cho tài khoản khách hàng.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Phiếu hỗ trợ của tôi'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _loadTickets,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && _tickets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _tickets.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 110),
                        Icon(
                          _error == null
                              ? Icons.support_agent_rounded
                              : Icons.cloud_off_rounded,
                          size: 56,
                          color: _error == null
                              ? const Color(0xFF94A3B8)
                              : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error ?? 'Bạn chưa có yêu cầu hỗ trợ nào.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 15,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _loadTickets,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ),
                        ],
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _tickets.length + (_error == null ? 0 : 1),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (_error != null && index == 0) {
                          return _ErrorCard(
                            message: _error!,
                            onRetry: _loadTickets,
                          );
                        }
                        final ticket =
                            _tickets[index - (_error == null ? 0 : 1)];
                        return _TicketCard(
                          ticket: ticket,
                          onTap: () => _openTicket(ticket.id),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTicket,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo yêu cầu'),
      ),
    );
  }
}

bool _isCustomer(String? role) {
  final normalized = role?.trim().toUpperCase();
  return normalized == 'CUS' || normalized == 'CUSTOMER';
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(ticket: ticket),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.categoryLabel,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(ticket.updatedAt ?? ticket.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    ticket.replies.isNotEmpty
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.replies.length}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final SupportTicket ticket;

  const _StatusChip({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final color = switch (ticket.status) {
      'OPN' => const Color(0xFF2563EB),
      'INP' => const Color(0xFF7C3AED),
      'WAT' => const Color(0xFFB45309),
      'RSV' when ticket.resolvedAt != null => const Color(0xFF15803D),
      'RSV' => const Color(0xFFB45309),
      'CLS' => const Color(0xFF64748B),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(ticket),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF1F2),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(message),
        trailing: IconButton(
          tooltip: 'Thử lại',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class SupportCreateScreen extends ConsumerStatefulWidget {
  final SupportRepository repository;

  const SupportCreateScreen({super.key, required this.repository});

  @override
  ConsumerState<SupportCreateScreen> createState() =>
      _SupportCreateScreenState();
}

class _SupportCreateScreenState extends ConsumerState<SupportCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<SupportCategory> _categories = const [];
  List<XFile> _images = const [];
  String? _categoryCode;
  String? _error;
  bool _loadingCategories = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.repository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryCode = categories.isEmpty ? null : categories.first.code;
        _loadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(error);
        _loadingCategories = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final next = await _pickSupportImages(_images);
      if (next == null || !mounted) return;
      setState(() {
        _images = next;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorText(error));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (_wordCount(title) > 50 || _wordCount(description) > 500) {
      setState(() => _error = 'Tiêu đề tối đa 50 từ, mô tả tối đa 500 từ.');
      return;
    }
    if (_linkPattern.hasMatch(title) || _linkPattern.hasMatch(description)) {
      setState(() => _error = 'Tiêu đề và mô tả không được chứa đường dẫn.');
      return;
    }
    final categoryCode = _categoryCode;
    if (categoryCode == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final ticket = await widget.repository.createTicket(
        categoryCode: categoryCode,
        title: title,
        description: description,
        attachments: _images,
      );
      if (!mounted) return;
      Navigator.of(context).pop(ticket);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorText(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Yêu cầu hỗ trợ mới'),
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'Hiện chưa có danh mục hỗ trợ.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadCategories,
                      child: const Text('Thử tải lại'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    _ErrorCard(
                      message: _error!,
                      onRetry: () => setState(() => _error = null),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danh mục',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category.code,
                                  child: Text(
                                    category.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (value) =>
                                    setState(() => _categoryCode = value),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _titleController,
                          maxLength: 255,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tiêu đề',
                            hintText: 'Tóm tắt vấn đề cần hỗ trợ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.short_text_rounded),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập tiêu đề.'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: 8,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Mô tả chi tiết',
                            hintText: 'Mô tả vấn đề để đội ngũ hỗ trợ xử lý nhanh hơn',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập nội dung mô tả.'
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tiêu đề ${_wordCount(_titleController.text)}/50 từ · Mô tả ${_wordCount(_descriptionController.text)}/500 từ',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Ảnh đính kèm (không bắt buộc)',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _submitting || _images.length >= _maxImages
                                  ? null
                                  : _pickImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Chọn ảnh'),
                            ),
                          ],
                        ),
                        const Text(
                          'JPEG, PNG hoặc WEBP · tối đa 3 ảnh · 2 MB mỗi ảnh',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        for (final image in _images)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.image_outlined,
                              color: _navy,
                            ),
                            title: Text(
                              image.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: 'Xóa ảnh',
                              onPressed: _submitting
                                  ? null
                                  : () => setState(() {
                                      _images = _images
                                          .where((item) => item != image)
                                          .toList();
                                    }),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Đang gửi yêu cầu...' : 'Gửi yêu cầu',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class SupportTicketScreen extends ConsumerStatefulWidget {
  final String ticketId;
  final SupportRepository repository;

  const SupportTicketScreen({
    super.key,
    required this.ticketId,
    required this.repository,
  });

  @override
  ConsumerState<SupportTicketScreen> createState() =>
      _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<XFile> _replyImages = const [];
  SupportTicket? _ticket;
  Timer? _refreshTimer;
  bool _loading = true;
  bool _sending = false;
  bool _updatingStatus = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicket();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadTicket(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    try {
      final ticket = await widget.repository.getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  Future<void> _sendReply() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _replyImages.isEmpty) return;
    if (message.isNotEmpty &&
        (_wordCount(message) > 500 || _linkPattern.hasMatch(message))) {
      setState(() {
        _error = _wordCount(message) > 500
            ? 'Mỗi tin nhắn tối đa 500 từ.'
            : 'Tin nhắn không được chứa đường dẫn.';
      });
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final ticket = await widget.repository.replyToTicket(
        ticketId: widget.ticketId,
        message: message,
        attachments: _replyImages,
      );
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _ticket = ticket;
        _replyImages = const [];
        _sending = false;
      });
      await _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = _errorText(error);
      });
    }
  }

  Future<void> _pickReplyImages() async {
    try {
      final images = await _pickSupportImages(_replyImages);
      if (images == null || !mounted) return;
      setState(() {
        _replyImages = images;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorText(error));
    }
  }

  Future<void> _updateStatus(String action) async {
    setState(() {
      _updatingStatus = true;
      _error = null;
    });
    try {
      final ticket = await widget.repository.updateTicketStatus(
        ticketId: widget.ticketId,
        action: action,
      );
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _updatingStatus = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updatingStatus = false;
        _error = _errorText(error);
      });
    }
  }

  Future<void> _deleteTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa yêu cầu hỗ trợ?'),
        content: const Text('Yêu cầu này sẽ được xóa khỏi danh sách của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa yêu cầu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteTicket(widget.ticketId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorText(error));
    }
  }

  Future<void> _scrollToBottom() async {
    await WidgetsBinding.instance.endOfFrame;
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final authState = ref.watch(authNotifierProvider);
    final userId = authState is AuthSuccess ? authState.user.userId : '';
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(
          ticket?.title ?? 'Chi tiết yêu cầu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (ticket != null && !{'RSV', 'CLS'}.contains(ticket.status))
            IconButton(
              tooltip: 'Xóa yêu cầu',
              onPressed: _deleteTicket,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadTicket,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading && ticket == null
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Không thể tải phiếu hỗ trợ.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadTicket,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _loadTicket),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadTicket,
                    child: ListView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _TicketSummary(ticket: ticket),
                        const SizedBox(height: 12),
                        _MessageCard(
                          sender: 'Bạn · Yêu cầu ban đầu',
                          message: ticket.description,
                          date: ticket.createdAt,
                          isOwn: true,
                          attachments: ticket.attachments,
                          ticketId: ticket.id,
                          repository: widget.repository,
                        ),
                        if (ticket.resolutionNote != null &&
                            ticket.resolutionNote!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            color: const Color(0xFFFFFBEB),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Đề xuất giải quyết từ Avora',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(ticket.resolutionNote!),
                                ],
                              ),
                            ),
                          ),
                        ],
                        for (final reply in ticket.replies) ...[
                          const SizedBox(height: 12),
                          _MessageCard(
                            sender: reply.senderId == userId
                                ? 'Bạn'
                                : reply.senderName,
                            message: reply.message,
                            date: reply.createdAt,
                            isOwn: reply.senderId == userId,
                            attachments: reply.attachments,
                            ticketId: ticket.id,
                            repository: widget.repository,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: ticket == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CustomerStatusActions(
                      ticket: ticket,
                      enabled: !_updatingStatus,
                      onAction: _updateStatus,
                    ),
                    if (ticket.status != 'CLS') ...[
                      const SizedBox(height: 8),
                      if (_replyImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final image in _replyImages)
                                InputChip(
                                  label: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 140,
                                    ),
                                    child: Text(
                                      image.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onDeleted: _sending
                                      ? null
                                      : () => setState(() {
                                          _replyImages = _replyImages
                                              .where((item) => item != image)
                                              .toList();
                                        }),
                                ),
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Đính kèm ảnh',
                            onPressed:
                                _sending || _replyImages.length >= _maxImages
                                ? null
                                : _pickReplyImages,
                            icon: const Icon(Icons.attach_file_rounded),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 100000,
                              enabled: !_sending,
                              decoration: InputDecoration(
                                hintText: 'Nhập phản hồi cho đội ngũ hỗ trợ',
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendReply(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Gửi phản hồi',
                            onPressed: _sending ? null : _sendReply,
                            style: IconButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                            ),
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Phiếu đã đóng, không thể gửi phản hồi.'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TicketSummary extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketSummary({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.categoryLabel,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(ticket: ticket),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo lúc ${_formatDate(ticket.createdAt)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerStatusActions extends StatelessWidget {
  final SupportTicket ticket;
  final bool enabled;
  final ValueChanged<String> onAction;

  const _CustomerStatusActions({
    required this.ticket,
    required this.enabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (ticket.status != 'RSV' || ticket.resolvedAt != null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton(
          onPressed: enabled ? () => onAction('reject_resolution') : null,
          child: const Text('Chưa giải quyết'),
        ),
        FilledButton(
          onPressed: enabled ? () => onAction('confirm_resolution') : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
          ),
          child: const Text('Đã giải quyết'),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String sender;
  final String message;
  final DateTime? date;
  final bool isOwn;
  final List<SupportAttachment> attachments;
  final String ticketId;
  final SupportRepository repository;

  const _MessageCard({
    required this.sender,
    required this.message,
    required this.date,
    required this.isOwn,
    required this.attachments,
    required this.ticketId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: isOwn ? const Color(0xFFEFF6FF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (message.isNotEmpty)
                  SelectableText(message, style: const TextStyle(height: 1.4)),
                for (final attachment in attachments)
                  _AttachmentButton(
                    ticketId: ticketId,
                    attachment: attachment,
                    repository: repository,
                  ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final String ticketId;
  final SupportAttachment attachment;
  final SupportRepository repository;

  const _AttachmentButton({
    required this.ticketId,
    required this.attachment,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: FutureBuilder<Uint8List>(
            future: repository.downloadAttachment(
              ticketId: ticketId,
              key: attachment.key,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_errorText(snapshot.error!)),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return InteractiveViewer(
                child: Image.memory(snapshot.data!, fit: BoxFit.contain),
              );
            },
          ),
        ),
      ),
      icon: const Icon(Icons.image_outlined, size: 18),
      label: Text(
        attachment.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
