import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/features/voucher/presentation/providers/voucher_wallet_provider.dart';
import 'package:avora_mobile/features/voucher/presentation/widgets/voucher_card.dart';

/// Màn hình Ví Mã Khuyến Mãi / Customer Voucher Wallet (Read-Only)
class VoucherWalletScreen extends ConsumerStatefulWidget {
  const VoucherWalletScreen({super.key});

  @override
  ConsumerState<VoucherWalletScreen> createState() =>
      _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends ConsumerState<VoucherWalletScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voucherWalletProvider);
    final notifier = ref.read(voucherWalletProvider.notifier);

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
              context.go('/profile');
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã Khuyến Mãi',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ví ưu đãi và voucher đặt phòng AVORA',
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
            onPressed: () => notifier.loadVouchers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner gợi ý sử dụng
          _buildInfoBanner(),

          // Thanh tìm kiếm voucher
          _buildSearchBar(notifier),

          // Bộ lọc trạng thái (Tabs / Chips)
          _buildFilterTabs(state, notifier),

          // Nội dung chính
          Expanded(
            child: RefreshIndicator(
              color: AvoraTheme.primaryNavy,
              onRefresh: () => notifier.loadVouchers(silent: true),
              child: _buildBodyContent(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEBF5FF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFBFDBFE), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFF0052CC),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sao chép mã voucher và nhập tại bước thanh toán để nhận ưu đãi.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(VoucherWalletNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: notifier.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm mã khuyến mãi (VD: SUMMER)...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    notifier.setSearchQuery('');
                  },
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AvoraTheme.primaryNavy,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(
    VoucherWalletState state,
    VoucherWalletNotifier notifier,
  ) {
    final filters = [
      {'key': 'ACTIVE', 'label': 'Đang hoạt động', 'count': state.activeCount},
      {'key': 'UPCOMING', 'label': 'Sắp diễn ra', 'count': state.upcomingCount},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = state.activeFilter == f['key'];
          final count = f['count'] as int;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: f['key'] == 'ACTIVE' ? 6 : 0,
                left: f['key'] == 'UPCOMING' ? 6 : 0,
              ),
              child: InkWell(
                onTap: () => notifier.setFilter(f['key'] as String),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AvoraTheme.primaryNavy : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AvoraTheme.primaryNavy
                          : const Color(0xFFCBD5E1),
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x1A003580),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          f['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color:
                                isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBodyContent(
    VoucherWalletState state,
    VoucherWalletNotifier notifier,
  ) {
    if (state.isLoading && state.vouchers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(
                color: AvoraTheme.primaryNavy,
              ),
            ),
          ),
        ],
      );
    }

    if (state.errorMessage != null && state.vouchers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AvoraTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => notifier.loadVouchers(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final filtered = state.filteredVouchers;

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 34,
                        color: AvoraTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Không tìm thấy mã khuyến mãi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.searchQuery.isNotEmpty
                          ? 'Không có voucher nào khớp với từ khóa "${state.searchQuery}".'
                          : 'Hiện tại chưa có mã khuyến mãi nào trong danh mục này.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final coupon = filtered[index];
        return VoucherCard(coupon: coupon);
      },
    );
  }
}
