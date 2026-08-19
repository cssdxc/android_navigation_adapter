import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Android system navigation modes exposed by the platform adapter.
enum AndroidNavigationMode { threeButton, twoButton, gesture, unknown }

/// Shared bottom spacing and Android navigation mode adapter.
abstract final class AndroidNavigationAdapter {
  static const double defaultBottomSpacing = 16;
  static const double iosSafeAreaBottomSpacing = 32;

  static const MethodChannel _channel = MethodChannel(
    'android_navigation_adapter',
  );

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static AndroidNavigationMode _navigationMode = AndroidNavigationMode.unknown;
  static double _androidBottomInset = 0;
  static bool _initialized = false;
  static final _metricsObserver = _MetricsObserver();

  /// Initializes Android navigation mode tracking. Safe to call more than once.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(_metricsObserver);
    await refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  /// Releases metric observation when the host application is shutting down.
  static void dispose() {
    if (!_initialized) return;
    WidgetsBinding.instance.removeObserver(_metricsObserver);
    _initialized = false;
  }

  /// Refreshes the cached Android navigation mode and bottom inset.
  static Future<void> refresh() async {
    final previousMode = _navigationMode;
    final previousInset = _androidBottomInset;
    _androidBottomInset = _readAndroidBottomInset();
    _navigationMode = await _readNavigationMode();
    if (previousMode != _navigationMode ||
        previousInset != _androidBottomInset) {
      changes.value++;
    }
  }

  /// Returns the bottom inset used by a fixed bottom action area.
  ///
  /// Android keeps the platform inset and adds the app spacing. iOS uses a
  /// fixed total of 32 logical pixels when a bottom safe area exists, and 16
  /// otherwise.
  static double bottomPadding(
    BuildContext context, {
    double spacing = defaultBottomSpacing,
  }) {
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return safeAreaBottom + spacing;
    }
    return safeAreaBottom > 0 ? iosSafeAreaBottomSpacing : spacing;
  }

  /// Returns the combined height of a fixed bottom action area.
  static double bottomBarHeight(
    BuildContext context, {
    double childHeight = 44,
    double topSpacing = 16,
    double spacing = defaultBottomSpacing,
  }) {
    return topSpacing + childHeight + bottomPadding(context, spacing: spacing);
  }

  static AndroidNavigationMode get navigationMode => _navigationMode;

  static bool get isThreeButtonNavigation =>
      _navigationMode == AndroidNavigationMode.threeButton;

  static double get androidBottomInset => _androidBottomInset;

  static double _readAndroidBottomInset() {
    if (defaultTargetPlatform != TargetPlatform.android) return 0;
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    if (dispatcher.views.isEmpty) return 0;
    final view = dispatcher.implicitView ?? dispatcher.views.first;
    return view.viewPadding.bottom / view.devicePixelRatio;
  }

  static Future<AndroidNavigationMode> _readNavigationMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidNavigationMode.unknown;
    }
    try {
      final value = await _channel.invokeMethod<int>('getNavigationMode');
      return _fromPlatformValue(value);
    } on PlatformException {
      return AndroidNavigationMode.unknown;
    } on MissingPluginException {
      return AndroidNavigationMode.unknown;
    }
  }

  static AndroidNavigationMode _fromPlatformValue(int? value) {
    return switch (value) {
      0 => AndroidNavigationMode.threeButton,
      1 => AndroidNavigationMode.twoButton,
      2 => AndroidNavigationMode.gesture,
      _ => AndroidNavigationMode.unknown,
    };
  }
}

class _MetricsObserver with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    unawaited(AndroidNavigationAdapter.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AndroidNavigationAdapter.refresh());
    }
  }
}
