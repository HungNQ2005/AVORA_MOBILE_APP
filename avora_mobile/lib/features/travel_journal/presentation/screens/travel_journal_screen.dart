import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/features/travel_journal/data/models/travel_journal_entry_model.dart';
import 'package:avora_mobile/features/travel_journal/presentation/providers/travel_journal_provider.dart';
import 'package:avora_mobile/features/travel_journal/presentation/widgets/journal_entry_sheet.dart';
import 'package:avora_mobile/features/travel_journal/presentation/widgets/create_trip_sheet.dart';

class TravelJournalScreen extends ConsumerWidget {
  const TravelJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travelJournalProvider);
    final notifier = ref.read(travelJournalProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhật ký hành trình',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Dấu ấn & Kỷ niệm du lịch cá nhân',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF93C5FD),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AvoraTheme.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm chuyến đi mới',
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
            onPressed: () => _openCreateTrip(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AvoraTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Thêm chuyến đi', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openCreateTrip(context, ref),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadJournal(),
        color: AvoraTheme.primaryNavy,
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AvoraTheme.primaryNavy),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Passport Card
                  _buildPassportCard(context, state.stats),
                  const SizedBox(height: 18),

                  // Quick Action Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_calendar_rounded, color: AvoraTheme.primaryNavy, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tự do ghi lại chuyến đi của bạn',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Thêm hành trình mới hoặc đồng bộ từ đơn Avora',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AvoraTheme.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _openCreateTrip(context, ref),
                          child: const Text('Tạo mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  _buildFilterBar(state, notifier),
                  const SizedBox(height: 16),

                  // Journeys List or Empty
                  if (state.filteredEntries.isEmpty)
                    _buildEmptyState(context, ref)
                  else
                    ...state.filteredEntries.map(
                      (entry) => _buildJourneyCard(context, ref, entry),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _openCreateTrip(BuildContext context, WidgetRef ref) async {
    final bookings = await ref.read(travelJournalProvider.notifier).getAvailableBookings();
    if (!context.mounted) return;
    CreateTripSheet.show(
      context,
      availableBookings: bookings,
      onSave: ref.read(travelJournalProvider.notifier).createCustomTrip,
    );
  }

  Widget _buildPassportCard(BuildContext context, TravelStats stats) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00224F), Color(0xFF003580), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003580).withOpacity(0.25),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: Color(0xFFFFC107),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'HỘ CHIẾU HÀNH TRÌNH AVORA',
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'EXPLORER',
                  style: TextStyle(
                    color: Color(0xFF00224F),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stats counters
          Row(
            children: [
              _buildStatItem('Chuyến đi', '${stats.totalTrips}', Icons.luggage_outlined),
              _buildDivider(),
              _buildStatItem('Điểm đến', '${stats.visitedCities.length}', Icons.location_on_outlined),
              _buildDivider(),
              _buildStatItem('Đêm nghỉ', '${stats.totalNights}', Icons.nightlight_round),
            ],
          ),

          if (stats.visitedCities.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.explore_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Tỉnh thành đã qua:',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: stats.visitedCities.take(6).map((city) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildFilterBar(TravelJournalState state, TravelJournalNotifier notifier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tất cả (${state.allEntries.length})',
            isSelected: state.activeFilter == 'all',
            onTap: () => notifier.setFilter('all'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Đã hoàn thành (${state.stats.completedTrips})',
            isSelected: state.activeFilter == 'completed',
            onTap: () => notifier.setFilter('completed'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Sắp diễn ra (${state.stats.upcomingTrips})',
            isSelected: state.activeFilter == 'upcoming',
            onTap: () => notifier.setFilter('upcoming'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AvoraTheme.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AvoraTheme.primaryNavy : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, WidgetRef ref, TravelJournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail or Icon Box
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFFF1F5F9),
                    child: entry.thumbnailUrl != null && entry.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            entry.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.hotel_rounded,
                              color: Color(0xFF94A3B8),
                              size: 32,
                            ),
                          )
                        : Icon(
                            entry.isCustomTrip ? Icons.landscape_rounded : Icons.hotel_rounded,
                            color: const Color(0xFF0284C7),
                            size: 36,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.cityName,
                              style: const TextStyle(
                                color: AvoraTheme.primaryNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildTypeBadge(entry),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (entry.placeName != entry.title && entry.placeName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.startDate} → ${entry.endDate}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${entry.nights} đêm',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF003580),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Journal Note Box (if written)
          if (entry.hasNote)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(_getMoodEmoji(entry.mood), style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            _getMoodLabel(entry.mood),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      if (entry.ratingScore != null && entry.ratingScore! > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 2),
                            Text(
                              '${entry.ratingScore}/10',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (entry.journalNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"${entry.journalNote}"',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (entry.highlights.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: entry.highlights.map((h) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            '✨ $h',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AvoraTheme.primaryNavy,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      entry.hasNote ? Icons.edit_note_rounded : Icons.add_comment_outlined,
                      size: 18,
                    ),
                    label: Text(
                      entry.hasNote ? 'Sửa nhật ký' : 'Ghi kỷ niệm',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      JournalEntrySheet.show(
                        context,
                        entry: entry,
                        onSave: ref.read(travelJournalProvider.notifier).updateEntry,
                        onDelete: () => ref.read(travelJournalProvider.notifier).deleteEntry(entry.id),
                      );
                    },
                  ),
                ),
                if (entry.bookingId != null && entry.bookingId!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Xem đơn đặt phòng',
                    icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF64748B)),
                    onPressed: () => context.push(AppRoutes.bookingDetailPath(entry.bookingId!)),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Xóa chuyến đi',
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () => _confirmDelete(context, ref, entry),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TravelJournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa chuyến đi?'),
        content: Text('Bạn có chắc muốn xóa chuyến đi "${entry.title}" khỏi nhật ký không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            onPressed: () {
              ref.read(travelJournalProvider.notifier).deleteEntry(entry.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(TravelJournalEntry entry) {
    if (entry.isCustomTrip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Tự tạo',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Đơn Avora',
        style: TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: AvoraTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có hành trình nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có thể tự do thêm bất kỳ chuyến đi nào hoặc đồng bộ tự động từ các đơn đặt phòng của Avora!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AvoraTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('Thêm chuyến đi đầu tiên'),
            onPressed: () => _openCreateTrip(context, ref),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'adventure':
        return '🎒';
      case 'romantic':
        return '💖';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'business':
        return '💼';
      case 'relaxing':
      default:
        return '🌴';
    }
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'adventure':
        return 'Khám phá';
      case 'romantic':
        return 'Lãng mạn';
      case 'family':
        return 'Gia đình';
      case 'business':
        return 'Công tác';
      case 'relaxing':
      default:
        return 'Nghỉ dưỡng';
    }
  }
}
