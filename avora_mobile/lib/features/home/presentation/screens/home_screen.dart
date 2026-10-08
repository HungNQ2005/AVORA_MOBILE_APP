import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/favorite_hotels_section.dart';
import '../widgets/filter_chips.dart';
import '../widgets/hero_search_header.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/interactive_map_banner.dart';
import '../widgets/summer_promo_banner.dart';
import '../widgets/trending_destinations.dart';
import '../widgets/value_guarantees.dart';

/// Màn hình chính (Trang chủ) của Avora Mobile App sau khi đăng nhập.
/// Thiết kế chuyển thể đồng bộ 1:1 từ phiên bản Web OTA Avora.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Lấy thông tin người dùng từ AuthSuccess
    final user = authState is AuthSuccess ? authState.user : null;
    final userName = user?.fullName ?? user?.email ?? 'Quý khách';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: HomeAppBar(userName: userName),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).refresh(),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroSearchHeader(),
              HomeFilterChips(),
              SizedBox(height: 16),
              SummerPromoBanner(),
              SizedBox(height: 24),
              TrendingDestinations(),
              SizedBox(height: 24),
              FavoriteHotelsSection(),
              SizedBox(height: 24),
              InteractiveMapBanner(),
              SizedBox(height: 24),
              ValueGuarantees(),
              SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
