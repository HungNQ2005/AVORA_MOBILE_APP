import 'package:avora_mobile/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('apiClientProvider base URL', () {
    test('uses localhost on Windows desktop', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(apiClientProvider).options.baseUrl,
        'http://localhost:5000/api',
      );
    });

    test('uses the host gateway on Android emulator', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(apiClientProvider).options.baseUrl,
        'http://10.0.2.2:5000/api',
      );
    });
  });
}
