import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/packing_item_model.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/destination_weather_model.dart';
import 'package:avora_mobile/features/travel_essentials/presentation/providers/travel_essentials_provider.dart';

class TravelEssentialsScreen extends ConsumerStatefulWidget {
  const TravelEssentialsScreen({super.key});

  @override
  ConsumerState<TravelEssentialsScreen> createState() => _TravelEssentialsScreenState();
}

class _TravelEssentialsScreenState extends ConsumerState<TravelEssentialsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _currencyInputController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currencyInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiện ích du lịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Bộ công cụ & Cẩm nang hỗ trợ chuyến đi',
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF93C5FD),
          indicatorColor: const Color(0xFFFFC107),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.checklist_rtl_rounded, size: 20), text: 'Hành lý'),
            Tab(icon: Icon(Icons.currency_exchange_rounded, size: 20), text: 'Đổi tiền'),
            Tab(icon: Icon(Icons.wb_sunny_outlined, size: 20), text: 'Thời tiết'),
            Tab(icon: Icon(Icons.emergency_outlined, size: 20), text: 'Hotline SOS'),
            Tab(icon: Icon(Icons.tips_and_updates_outlined, size: 20), text: 'Mẹo lưu trú'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPackingTab(),
          _buildCurrencyTab(),
          _buildWeatherTab(),
          _buildEmergencyTab(),
          _buildStayTipsTab(),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: CHECKLIST HÀNH LÝ
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildPackingTab() {
    final packingState = ref.watch(packingProvider);
    final notifier = ref.read(packingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF003580), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A003580),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiến độ chuẩn bị đồ đạc',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${packingState.progressPercent}%',
                      style: const TextStyle(
                        color: Color(0xFF00224F),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: packingState.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã xếp: ${packingState.checkedCount}/${packingState.totalCount} món',
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                  ),
                  InkWell(
                    onTap: () => _showResetPackingDialog(context, notifier),
                    child: const Text(
                      'Khôi phục mẫu mặc định',
                      style: TextStyle(
                        color: Color(0xFFFFC107),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('all', 'Tất cả (${packingState.totalCount})', packingState.activeCategory, notifier),
              _buildCategoryChip('documents', '📄 Giấy tờ', packingState.activeCategory, notifier),
              _buildCategoryChip('clothes', '👕 Trang phục', packingState.activeCategory, notifier),
              _buildCategoryChip('electronics', '🔌 Công nghệ', packingState.activeCategory, notifier),
              _buildCategoryChip('toiletries', '🧴 Y tế & Vệ sinh', packingState.activeCategory, notifier),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              ...packingState.filteredItems.map((item) {
                return Column(
                  children: [
                    ListTile(
                      onTap: () => notifier.toggleItem(item.id),
                      leading: Checkbox(
                        value: item.isChecked,
                        activeColor: AvoraTheme.primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (_) => notifier.toggleItem(item.id),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: item.isChecked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      trailing: item.isCustom
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                              onPressed: () => notifier.deleteItem(item.id),
                            )
                          : null,
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  ],
                );
              }),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () => _showAddItemDialog(context, notifier),
                  icon: const Icon(Icons.add_circle_outline, color: AvoraTheme.primaryNavy, size: 20),
                  label: const Text(
                    'Thêm món đồ cá nhân khác',
                    style: TextStyle(color: AvoraTheme.primaryNavy, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String id, String label, String active, PackingNotifier notifier) {
    final isSelected = active == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AvoraTheme.primaryNavy,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AvoraTheme.primaryNavy : const Color(0xFFCBD5E1)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        onSelected: (val) {
          if (val) notifier.setCategory(id);
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, PackingNotifier notifier) {
    final controller = TextEditingController();
    String category = 'clothes';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm đồ cần chuẩn bị', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên món đồ',
                  hintText: 'Vd: Ô dù che mưa, áo phao trẻ em...',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: const [
                  DropdownMenuItem(value: 'documents', child: Text('Giấy tờ')),
                  DropdownMenuItem(value: 'clothes', child: Text('Trang phục')),
                  DropdownMenuItem(value: 'electronics', child: Text('Công nghệ')),
                  DropdownMenuItem(value: 'toiletries', child: Text('Y tế & Vệ sinh')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                notifier.addItem(controller.text, category);
                Navigator.of(ctx).pop();
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPackingDialog(BuildContext context, PackingNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục danh sách?'),
        content: const Text('Hành động này sẽ đặt lại toàn bộ checklist về danh sách gợi ý chuẩn ban đầu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Bỏ qua')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AvoraTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.of(ctx).pop();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: ĐỔI NGOẠI TỆ & TÍNH TOÁN CHI TIÊU
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildCurrencyTab() {
    final currencyState = ref.watch(currencyProvider);
    final notifier = ref.read(currencyProvider.notifier);

    final formatter = NumberFormat('#,###.##');
    final supportedCurrencies = currencyState.ratesToVnd.keys.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quy đổi tỷ giá nhanh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _currencyInputController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Số tiền quy đổi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0;
                        notifier.setAmount(parsed);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currencyState.fromCurrency,
                          isExpanded: true,
                          items: supportedCurrencies.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) notifier.setFromCurrency(val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Center(
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF2F6),
                    foregroundColor: AvoraTheme.primaryNavy,
                  ),
                  icon: const Icon(Icons.swap_vert_rounded),
                  onPressed: notifier.swapCurrencies,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số tiền nhận được ước tính',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(currencyState.convertedAmount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AvoraTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currencyState.toCurrency,
                          items: supportedCurrencies.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) notifier.setToCurrency(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const Text('Cộng nhanh số tiền:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [50, 100, 200, 500, 1000].map((val) {
                  return ActionChip(
                    label: Text('+$val'),
                    labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onPressed: () {
                      final newAmt = currencyState.amount + val;
                      _currencyInputController.text = newAmt.toString();
                      notifier.setAmount(newAmt);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_chart_outlined, color: AvoraTheme.primaryNavy, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Bảng tỷ giá tham khảo (so với VND)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...currencyState.ratesToVnd.entries.where((e) => e.key != 'VND').map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 ${entry.key}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        '≈ ${formatter.format(entry.value)} VND',
                        style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 3: THỜI TIẾT ĐIỂM ĐẾN
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildWeatherTab() {
    final weatherList = ref.watch(destinationWeatherProvider);
    final selectedIndex = ref.watch(selectedWeatherCityIndexProvider);
    final current = weatherList[selectedIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: weatherList.asMap().entries.map((entry) {
              final isSelected = entry.key == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value.cityName),
                  selected: isSelected,
                  selectedColor: AvoraTheme.primaryNavy,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSelected ? AvoraTheme.primaryNavy : const Color(0xFFCBD5E1)),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (val) {
                    if (val) ref.read(selectedWeatherCityIndexProvider.notifier).state = entry.key;
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF003580)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x200284C7),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFC107), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        current.cityName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      current.condition,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${current.temperature}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Icon(
                    _getWeatherIcon(current.weatherCode),
                    color: const Color(0xFFFFC107),
                    size: 64,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherSubItem('Độ ẩm', '${current.humidity}%', Icons.water_drop_outlined),
                  _buildWeatherSubItem('Chỉ số UV', '${current.uvIndex}/11', Icons.wb_sunny_outlined),
                  _buildWeatherSubItem('Trạng thái', 'Lý tưởng', Icons.thumb_up_alt_outlined),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.checkroom_outlined, color: AvoraTheme.primaryNavy, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Gợi ý trang phục phù hợp',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                current.clothingAdvice,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mẹo du lịch tại điểm đến',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...current.travelTips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AvoraTheme.primaryNavy, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherSubItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  IconData _getWeatherIcon(String code) {
    switch (code) {
      case 'rain':
        return Icons.water_drop_rounded;
      case 'cloudy':
        return Icons.cloud_outlined;
      case 'cool':
        return Icons.ac_unit_rounded;
      case 'sunny':
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 4: HOTLINE KHẨN CẤP & SOS
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildEmergencyTab() {
    final hotlines = [
      {'name': 'Tổng đài Avora Chăm sóc Khách hàng 24/7', 'number': '1900 8888', 'desc': 'Hỗ trợ đặt phòng, giải quyết sự cố lưu trú khẩn cấp', 'color': 0xFF003580, 'icon': Icons.support_agent_rounded},
      {'name': 'Cấp cứu Y tế Toàn quốc', 'number': '115', 'desc': 'Cấp cứu bệnh viện, xe cứu thương khẩn cấp', 'color': 0xFFDC2626, 'icon': Icons.medical_services_outlined},
      {'name': 'Cảnh sát Phản ứng nhanh', 'number': '113', 'desc': 'An ninh trật tự, mất cắp hoặc sự cố an toàn du khách', 'color': 0xFF2563EB, 'icon': Icons.local_police_outlined},
      {'name': 'Cứu hỏa & Cứu nạn Cứu hộ', 'number': '114', 'desc': 'Hỏa hoạn, tai nạn kẹt thang máy hoặc sự cố kỹ thuật', 'color': 0xFFEA580C, 'icon': Icons.fire_truck_outlined},
      {'name': 'Tổng đài Quốc gia Tìm kiếm Cứu nạn', 'number': '112', 'desc': 'Cứu hộ thiên tai bão lũ, sự cố trên biển hoặc leo núi', 'color': 0xFF059669, 'icon': Icons.sos_rounded},
      {'name': 'Hỗ trợ Thông tin Du khách Việt Nam', 'number': '1800 6868', 'desc': 'Cục Du lịch Quốc gia Việt Nam', 'color': 0xFF7C3AED, 'icon': Icons.travel_explore_rounded},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lưu lại các số liên lạc khẩn cấp khi đi xa. Chạm để xem số và gọi nhanh.',
                  style: TextStyle(color: Color(0xFF991B1B), fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...hotlines.map((h) {
          final color = Color(h['color'] as int);
          final icon = h['icon'] as IconData;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['name'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        h['desc'] as String,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        h['number'] as String,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: color),
                  icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Số liên lạc khẩn cấp: ${h['number']}'),
                        backgroundColor: color,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 5: CẨM NANG & MẸO LƯU TRÚ AVORA
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildStayTipsTab() {
    final tips = [
      {
        'title': 'Thời gian nhận phòng & trả phòng chuẩn',
        'icon': Icons.schedule_rounded,
        'content':
            '• Giờ nhận phòng (Check-in) thông thường: từ 14:00 chiều.\n• Giờ trả phòng (Check-out): trước 12:00 trưa.\n• Nếu muốn nhận phòng sớm (Early check-in) hoặc trả phòng muộn (Late check-out), bạn hãy ghi chú vào mục Yêu cầu đặc biệt khi đặt phòng trên Avora hoặc liên hệ khách sạn trước 24h.'
      },
      {
        'title': 'Giấy tờ cần xuất trình khi nhận phòng',
        'icon': Icons.badge_outlined,
        'content':
            '• CCCD hoặc Hộ chiếu gốc của tất cả khách lưu trú trưởng thành.\n• Mã đơn đặt phòng Avora hoặc E-Voucher trong mục "Đặt chỗ" trên ứng dụng.\n• Một số khách sạn có thể yêu cầu đặt cọc giữ phòng (bằng tiền mặt hoặc thẻ tín dụng) và sẽ hoàn trả đầy đủ khi trả phòng.'
      },
      {
        'title': 'Chính sách hủy phòng & Hoàn tiền minh bạch',
        'icon': Icons.verified_user_outlined,
        'content':
            '• Khách sạn có gắn nhãn "Hủy miễn phí": Bạn được hủy không mất phí nếu thực hiện trước số giờ quy định theo m_cancellation_policy (thường trước 24h - 48h check-in).\n• Tỷ lệ phạt hủy và tiền hoàn dự kiến được Avora tính toán tự động chuẩn xác theo chính sách phòng.'
      },
      {
        'title': 'Kiểm tra phòng ngay khi nhận khóa',
        'icon': Icons.meeting_room_outlined,
        'content':
            '• Kiểm tra hệ thống khóa thẻ từ, điều hòa không khí, nước nóng lạnh.\n• Kiểm tra danh mục minibar để tránh nhầm lẫn phí phụ thu khi thanh toán.\n• Báo ngay cho lễ tân nếu phát hiện thiết bị hư hỏng hoặc phòng chưa vệ sinh đạt chuẩn.'
      },
      {
        'title': 'Quyền lợi hội viên & Tích điểm Avora',
        'icon': Icons.stars_rounded,
        'content':
            '• Tích lũy số đêm lưu trú để thăng hạng thành viên và nhận các mã ưu đãi độc quyền (m_coupon).\n• Đánh giá khách sạn sau kỳ nghỉ để nhận thêm mã giảm giá cho chuyến đi tiếp theo!'
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tip['icon'] as IconData, color: AvoraTheme.primaryNavy, size: 20),
              ),
              title: Text(
                tip['title'] as String,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    tip['content'] as String,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
