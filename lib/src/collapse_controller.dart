import 'package:flutter/foundation.dart';

/// Desired expanded or collapsed state for [LiquidGlassNavigationBar].
///
/// This object stores the target only. It does not own a ticker, an
/// [AnimationController], or the selected destination. The navigation bar
/// owns the collapse animation and reads [isCollapsed] as the target.
///
/// The caller owns the controller. The bar adds and removes its own listener
/// and never disposes a controller it did not create. Dispose this after the
/// bar has dropped it, or set the bar's controller to null before disposing.
///
/// Repeated requests for the state that is already current do not notify.
class LiquidGlassCollapseController extends ChangeNotifier {
  /// Creates a controller. [collapsed] false is the expanded target.
  LiquidGlassCollapseController({bool collapsed = false})
    : _collapsed = collapsed; // ignore: prefer_initializing_formals

  bool _collapsed;

  /// Whether the bar should be the compact button.
  ///
  /// This is the requested target, not the in-flight animation value.
  bool get isCollapsed => _collapsed;

  /// Requests the compact button.
  void collapse() => _set(true);

  /// Requests the full navigation bar.
  void expand() => _set(false);

  /// Switches between the compact button and the full bar.
  void toggle() => _set(!_collapsed);

  void _set(bool value) {
    if (_collapsed == value) {
      return;
    }
    _collapsed = value;
    notifyListeners();
  }
}
