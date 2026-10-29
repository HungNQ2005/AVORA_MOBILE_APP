import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/packing_item_model.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/destination_weather_model.dart';
import 'package:avora_mobile/features/travel_essentials/data/repositories/travel_essentials_repository.dart';

// ─── Packing Checklist State ─────────────────────────────────────────────────
class PackingState {
  final List<PackingItem> items;
  final String activeCategory;
  final bool isLoading;

  const PackingState({
    this.items = const [],
    this.activeCategory = 'all',
    this.isLoading = false,
  });

  List<PackingItem> get filteredItems {
    if (activeCategory == 'all') return items;
    return items.where((e) => e.category == activeCategory).toList();
  }

  int get totalCount => items.length;
  int get checkedCount => items.where((e) => e.isChecked).length;
  double get progress => totalCount == 0 ? 0 : checkedCount / totalCount;
  int get progressPercent => (progress * 100).round();

  PackingState copyWith({
    List<PackingItem>? items,
    String? activeCategory,
    bool? isLoading,
  }) {
    return PackingState(
      items: items ?? this.items,
      activeCategory: activeCategory ?? this.activeCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PackingNotifier extends StateNotifier<PackingState> {
  final TravelEssentialsRepository _repository;

  PackingNotifier(this._repository) : super(const PackingState()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true);
    final list = await _repository.getPackingList();
    state = state.copyWith(items: list, isLoading: false);
  }

  void setCategory(String category) {
    state = state.copyWith(activeCategory: category);
  }

  Future<void> toggleItem(String id) async {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isChecked: !item.isChecked);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
    await _repository.savePackingList(updated);
  }

  Future<void> addItem(String title, String category) async {
    if (title.trim().isEmpty) return;
    final newItem = PackingItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      category: category,
      isChecked: false,
      isCustom: true,
    );
    final updated = [...state.items, newItem];
    state = state.copyWith(items: updated);
    await _repository.savePackingList(updated);
  }

  Future<void> deleteItem(String id) async {
    final updated = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: updated);
    await _repository.savePackingList(updated);
  }

  Future<void> resetToDefaults() async {
    state = state.copyWith(isLoading: true);
    final defaults = await _repository.resetToDefaults();
    state = state.copyWith(items: defaults, isLoading: false);
  }
}

final packingProvider =
    StateNotifierProvider<PackingNotifier, PackingState>((ref) {
  final repo = ref.watch(travelEssentialsRepositoryProvider);
  return PackingNotifier(repo);
});

// ─── Currency Converter State ────────────────────────────────────────────────
class CurrencyState {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  final Map<String, double> ratesToVnd;

  const CurrencyState({
    this.fromCurrency = 'USD',
    this.toCurrency = 'VND',
    this.amount = 100,
    this.ratesToVnd = const {
      'VND': 1.0,
      'USD': 25450.0,
      'EUR': 27500.0,
      'JPY': 168.0,
      'KRW': 18.5,
      'THB': 720.0,
      'SGD': 19300.0,
      'CNY': 3520.0,
      'AUD': 16600.0,
    },
  });

  double get convertedAmount {
    final fromRate = ratesToVnd[fromCurrency] ?? 1.0;
    final toRate = ratesToVnd[toCurrency] ?? 1.0;
    if (toRate == 0) return 0;
    final inVnd = amount * fromRate;
    return inVnd / toRate;
  }

  CurrencyState copyWith({
    String? fromCurrency,
    String? toCurrency,
    double? amount,
  }) {
    return CurrencyState(
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      amount: amount ?? this.amount,
      ratesToVnd: ratesToVnd,
    );
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier() : super(const CurrencyState());

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setFromCurrency(String curr) {
    state = state.copyWith(fromCurrency: curr);
  }

  void setToCurrency(String curr) {
    state = state.copyWith(toCurrency: curr);
  }

  void swapCurrencies() {
    final temp = state.fromCurrency;
    state = state.copyWith(
      fromCurrency: state.toCurrency,
      toCurrency: temp,
    );
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  return CurrencyNotifier();
});

// ─── Destination Weather Provider ────────────────────────────────────────────
final destinationWeatherProvider = Provider<List<DestinationWeather>>((ref) {
  final repo = ref.watch(travelEssentialsRepositoryProvider);
  return repo.getDestinationWeatherList();
});

final selectedWeatherCityIndexProvider = StateProvider<int>((ref) => 0);
