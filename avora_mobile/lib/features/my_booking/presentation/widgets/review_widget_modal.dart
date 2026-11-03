import 'package:flutter/material.dart';

import '../../data/models/booking_item_model.dart';
import '../../data/models/booking_review_model.dart';
import '../../data/repositories/my_booking_repository.dart';
import 'review_card.dart';

class ReviewWidgetModal extends StatefulWidget {
  final BookingItemModel booking;
  final MyBookingRepository repository;

  const ReviewWidgetModal({
    super.key,
    required this.booking,
    required this.repository,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BookingItemModel booking,
    required MyBookingRepository repository,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReviewWidgetModal(booking: booking, repository: repository),
    );
  }

  @override
  State<ReviewWidgetModal> createState() => _ReviewWidgetModalState();
}

class _ReviewWidgetModalState extends State<ReviewWidgetModal> {
  static const _primary = Color(0xFF003580);
  final _commentController = TextEditingController();
  BookingReviewModel? _review;
  bool _canCreate = false;
  bool _unavailable = false;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  int _ratingScore = 8;
  String? _errorMessage;
  String? _successMessage;

  bool get _isConfirmedBooking {
    final status =
        (widget.booking.bookingStatusCd ?? widget.booking.statusCodeName)
            .trim()
            .toUpperCase();
    return status == '2' || status == 'CFM';
  }

  bool get _isReadOnly => _review != null && !_review!.canEdit;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReview() async {
    try {
      final result = await widget.repository.fetchBookingReview(
        widget.booking.bookingId,
      );
      if (!mounted) return;
      setState(() {
        _review = result.review;
        _canCreate =
            result.review == null &&
            !result.unavailable &&
            (result.canCreate || _isConfirmedBooking);
        _unavailable = result.unavailable;
        _ratingScore = result.review?.ratingScore ?? 8;
        _commentController.text = result.review?.comment ?? '';
        _isEditing = _canCreate;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _message(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (_ratingScore < 1 || _ratingScore > 10) {
      setState(() => _errorMessage = 'Mức đánh giá phải từ 1 đến 10.');
      return;
    }
    if (comment.length > 2000) {
      setState(
        () => _errorMessage = 'Nhận xét không được vượt quá 2000 ký tự.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = _review == null
          ? await widget.repository.createBookingReview(
              widget.booking.bookingId,
              ratingScore: _ratingScore,
              comment: comment.isEmpty ? null : comment,
            )
          : await widget.repository.updateBookingReview(
              _review!.reviewId,
              ratingScore: _ratingScore,
              comment: comment.isEmpty ? null : comment,
            );
      if (!mounted) return;
      setState(() {
        _review = result;
        _canCreate = false;
        _isEditing = false;
        _ratingScore = result.ratingScore;
        _commentController.text = result.comment;
        _isSaving = false;
        _successMessage = 'Đã lưu đánh giá thành công.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _message(error);
      });
    }
  }

  Future<void> _deleteReview() async {
    final reason = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ReviewDeletionDialog(),
    );
    if (reason == null || _review == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.deleteBookingReview(
        _review!.reviewId,
        reasonCode: reason['reason_code'] as String,
        reasonText: reason['reason_text'] as String?,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _message(error);
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _ratingScore = _review?.ratingScore ?? 8;
      _commentController.text = _review?.comment ?? '';
      _isEditing = false;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Exception|ApiException):?\s*'),
    '',
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐÁNH GIÁ KỲ NGHỈ',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Đánh giá khách sạn',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  '${widget.booking.hotel.name} · Mã đặt chỗ ${widget.booking.bookingCode}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                else if (_unavailable)
                  _notice('Đánh giá chỉ khả dụng khi khách sạn đang hoạt động.')
                else if (_errorMessage != null &&
                    _review == null &&
                    !_canCreate)
                  _errorBox(_errorMessage!)
                else ...[
                  if (_isReadOnly)
                    _notice(
                      'Đã quá 30 ngày kể từ khi đánh giá được tạo. Nội dung này chỉ có thể xem.',
                    ),
                  if (_review != null && !_isReadOnly && !_isEditing)
                    _notice(
                      'Bạn có thể chỉnh sửa hoặc xóa đánh giá trong vòng 30 ngày kể từ ngày tạo.',
                    ),
                  if (_review != null && !_isEditing)
                    ReviewCard(review: _review!),
                  if (_isEditing) _buildReviewForm(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _errorBox(_errorMessage!),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 12),
                    _notice(_successMessage!, success: true),
                  ],
                  const SizedBox(height: 18),
                  _buildActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Mức độ hài lòng',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$_ratingScore/10',
              style: const TextStyle(
                color: _primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _ratingScore.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: _primary,
          label: '$_ratingScore',
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _ratingScore = value.round()),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chưa hài lòng',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              'Rất hài lòng',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Nhận xét về khách sạn',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _commentController,
          readOnly: _isReadOnly || !_isEditing,
          enabled: !_isSaving,
          maxLength: 2000,
          maxLines: 5,
          minLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Chia sẻ trải nghiệm lưu trú của bạn...',
            counterText: '${_commentController.text.length}/2000',
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_isLoading || _unavailable) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_review != null && _review!.canEdit && !_isEditing) ...[
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _deleteReview,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: const Text('Xóa đánh giá'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSaving
                ? null
                : () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Chỉnh sửa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        if (_isEditing) ...[
          if (_review != null)
            OutlinedButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Hủy'),
            ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _submitReview,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(
              _isSaving
                  ? 'Đang lưu...'
                  : _review == null
                  ? 'Gửi đánh giá'
                  : 'Lưu thay đổi',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        if (_review == null && !_canCreate)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chưa thể tạo đánh giá cho đặt phòng này.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
        if (_review == null ||
            _isReadOnly ||
            (_review != null && !_review!.canEdit))
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
      ],
    );
  }

  Widget _notice(String text, {bool success = false}) {
    final foreground = success
        ? const Color(0xFF15803D)
        : const Color(0xFF92400E);
    final background = success
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFFBEB);
    final border = success ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(color: foreground, fontSize: 12, height: 1.4),
      ),
    );
  }

  Widget _errorBox(String text) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
    ),
  );
}

class _ReviewDeletionDialog extends StatefulWidget {
  const _ReviewDeletionDialog();

  @override
  State<_ReviewDeletionDialog> createState() => _ReviewDeletionDialogState();
}

class _ReviewDeletionDialogState extends State<_ReviewDeletionDialog> {
  String _reasonCode = 'VIOLENCE';
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _reasonCode == 'OTHER';
    final reasonIsEmpty = _reasonController.text.trim().isEmpty;
    return AlertDialog(
      title: const Text('Gỡ đánh giá này?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn lý do gỡ. Lý do này sẽ được lưu trong lịch sử kiểm duyệt.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _reasonCode,
              decoration: const InputDecoration(
                labelText: 'Lý do gỡ',
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                        ('VIOLENCE', 'Nội dung có yếu tố bạo lực'),
                        (
                          'DEFAMATION',
                          'Nội dung phỉ báng hoặc không chính xác',
                        ),
                        (
                          'SEXUAL_CONTENT',
                          'Nội dung không phù hợp hoặc gợi dục',
                        ),
                        (
                          'POLITICAL_CONTENT',
                          'Nội dung chính trị không cần thiết',
                        ),
                        ('OTHER', 'Lý do khác'),
                      ]
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason.$1,
                          child: Text(
                            reason.$2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _reasonCode = value);
              },
            ),
            if (isOther) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lý do cụ thể',
                  errorText: reasonIsEmpty
                      ? 'Vui lòng nhập lý do cụ thể.'
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: isOther && reasonIsEmpty
              ? null
              : () => Navigator.pop(context, {
                  'reason_code': _reasonCode,
                  if (isOther) 'reason_text': _reasonController.text.trim(),
                }),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          child: const Text('Gỡ đánh giá'),
        ),
      ],
    );
  }
}
