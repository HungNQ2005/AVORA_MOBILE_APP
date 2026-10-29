import 'package:flutter/material.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/features/travel_journal/data/models/travel_journal_entry_model.dart';

class JournalEntrySheet extends StatefulWidget {
  final TravelJournalEntry entry;
  final Future<bool> Function({
    required String entryId,
    required String note,
    required String mood,
    int? ratingScore,
    List<String> highlights,
  }) onSave;
  final VoidCallback? onDelete;

  const JournalEntrySheet({
    super.key,
    required this.entry,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required TravelJournalEntry entry,
    required Future<bool> Function({
      required String entryId,
      required String note,
      required String mood,
      int? ratingScore,
      List<String> highlights,
    }) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: JournalEntrySheet(
          entry: entry,
          onSave: onSave,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<JournalEntrySheet> {
  late final TextEditingController _noteController;
  late String _selectedMood;
  late int? _ratingScore;
  late List<String> _selectedHighlights;
  bool _isSaving = false;

  final List<Map<String, String>> _moods = [
    {'id': 'relaxing', 'label': 'Thư giãn', 'emoji': '🌴'},
    {'id': 'adventure', 'label': 'Khám phá', 'emoji': '🎒'},
    {'id': 'romantic', 'label': 'Lãng mạn', 'emoji': '💖'},
    {'id': 'family', 'label': 'Gia đình', 'emoji': '👨‍👩‍👧‍👦'},
    {'id': 'business', 'label': 'Công tác', 'emoji': '💼'},
  ];

  final List<String> _commonHighlights = [
    'Phòng sạch sẽ',
    'View cực đẹp',
    'Buffet ngon',
    'Hồ bơi vô cực',
    'Nhân viên chu đáo',
    'Vị trí trung tâm',
    'Yên tĩnh riêng tư',
    'Trang thiết bị mới',
    'Giường êm ái',
    'Gần bãi biển',
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.entry.journalNote);
    _selectedMood = widget.entry.mood.isNotEmpty ? widget.entry.mood : 'relaxing';
    _ratingScore = widget.entry.ratingScore ?? 9;
    _selectedHighlights = List<String>.from(widget.entry.highlights);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await widget.onSave(
      entryId: widget.entry.id,
      note: _noteController.text.trim(),
      mood: _selectedMood,
      ratingScore: _ratingScore,
      highlights: _selectedHighlights,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật nhật ký hành trình thành công! ✨'),
          backgroundColor: Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AvoraTheme.primaryNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nhật ký chuyến đi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                // Mood selector
                const Text(
                  'Cảm xúc chuyến đi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _moods.map((m) {
                      final isSelected = _selectedMood == m['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(m['emoji'] ?? ''),
                          label: Text(m['label'] ?? ''),
                          selected: isSelected,
                          selectedColor: const Color(0xFF003580).withOpacity(0.12),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isSelected
                                ? AvoraTheme.primaryNavy
                                : const Color(0xFFE2E8F0),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AvoraTheme.primaryNavy
                                : const Color(0xFF334155),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedMood = m['id']!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Rating score (1 - 10)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đánh giá trải nghiệm (1 - 10)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AvoraTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_ratingScore ?? 9}/10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: (_ratingScore ?? 9).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${_ratingScore ?? 9}',
                  activeColor: AvoraTheme.primaryNavy,
                  onChanged: (val) => setState(() => _ratingScore = val.round()),
                ),
                const SizedBox(height: 16),

                // Note TextField
                const Text(
                  'Ghi chép kỷ niệm & khoảnh khắc đáng nhớ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhớ lại hoàng hôn trên ban công, quán cafe ngon gần khách sạn, hoặc kỷ niệm cùng gia đình...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Highlight chips
                const Text(
                  'Điểm ấn tượng nhất',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonHighlights.map((tag) {
                    final isChecked = _selectedHighlights.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isChecked,
                      selectedColor: const Color(0xFF003580).withOpacity(0.1),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isChecked ? AvoraTheme.primaryNavy : const Color(0xFFE2E8F0),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isChecked ? AvoraTheme.primaryNavy : const Color(0xFF475569),
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedHighlights.add(tag);
                          } else {
                            _selectedHighlights.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                if (widget.onDelete != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        widget.onDelete?.call();
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AvoraTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Lưu nhật ký',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
