import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice_card.dart';

/// Màn hình Danh sách Hóa đơn thanh toán & Giao dịch VAT (Invoice List)
class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceListNotifierProvider);
    final notifier = ref.read(invoiceListNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AvoraTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AvoraTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hóa đơn thanh toán',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Lịch sử biên nhận VAT & Giao dịch điện tử',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFBFDBFE),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'Làm mới',
            onPressed: () => notifier.loadInvoices(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Thanh tìm kiếm & bộ lọc ─────────────────────────────────
          _buildFilterBar(state, notifier),

          // ─── Nội dung danh sách ──────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AvoraTheme.primaryNavy,
              onRefresh: () => notifier.loadInvoices(silent: true),
              child: _buildBody(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    InvoiceListState state,
    InvoiceListNotifier notifier,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Ô tìm kiếm
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã hóa đơn, mã GD, khách sạn...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Các tab bộ lọc trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả',
                  count: state.totalCount,
                  isActive: state.activeFilter == 'ALL',
                  onTap: () => notifier.setActiveFilter('ALL'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Đã thanh toán',
                  count: state.paidCount,
                  isActive: state.activeFilter == 'PAID',
                  badgeColor: const Color(0xFFDCFCE7),
                  badgeTextColor: const Color(0xFF15803D),
                  onTap: () => notifier.setActiveFilter('PAID'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Chờ xác nhận',
                  count: state.pendingCount,
                  isActive: state.activeFilter == 'PENDING',
                  badgeColor: const Color(0xFFFEF3C7),
                  badgeTextColor: const Color(0xFFB45309),
                  onTap: () => notifier.setActiveFilter('PENDING'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AvoraTheme.primaryNavy : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AvoraTheme.primaryNavy : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : (badgeColor ?? const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? Colors.white
                      : (badgeTextColor ?? const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InvoiceListState state, InvoiceListNotifier notifier) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AvoraTheme.primaryNavy),
      );
    }

    if (state.errorMessage != null && state.invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải danh sách hóa đơn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => notifier.loadInvoices(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvoraTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredList = state.filteredInvoices;

    if (filteredList.isEmpty) {
      return _buildEmptyView(state, notifier);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final invoice = filteredList[index];
        return InvoiceCard(
          invoice: invoice,
          onTap: () {
            context.push(AppRoutes.invoiceDetailPath(invoice.bookingId));
          },
        );
      },
    );
  }

  Widget _buildEmptyView(
    InvoiceListState state,
    InvoiceListNotifier notifier,
  ) {
    final isFiltered =
        state.searchQuery.isNotEmpty || state.activeFilter != 'ALL';

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AvoraTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Không tìm thấy hóa đơn phù hợp'
                  : 'Chưa có hóa đơn thanh toán nào',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Hãy thử thay đổi từ khóa tìm kiếm hoặc chọn bộ lọc trạng thái khác.'
                  : 'Hóa đơn điện tử VAT sẽ tự động được ghi nhận tại đây sau khi bạn hoàn tất đặt phòng & thanh toán.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isFiltered)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  notifier.setSearchQuery('');
                  notifier.setActiveFilter('ALL');
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Xóa bộ lọc tìm kiếm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AvoraTheme.primaryNavy,
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.hotelSearch),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Khám phá khách sạn ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvoraTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

