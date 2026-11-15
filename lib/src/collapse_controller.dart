import 'package:flutter/foundation.dart';

/// Requested expanded or compact target for [LiquidGlassNavigationBar].
///
/// This object stores the target only. It does not own a ticker or the
/// selected destination. The navigation bar owns the morph and reads
/// [isCollapsed] as the target.
///
/// The caller owns the controller. The bar adds and removes its own listener
/// and never disposes a controller it did not create. Dispose this after the
/// bar has dropped it, or set the bar's controller to null before disposing.
///
/// Repeated requests for the state that is already current do not notify.
class LiquidGlassCollapseController extends ChangeNotifier {
  /// Creates a controller. [collapsed] false keeps the full bar.
  LiquidGlassCollapseController({bool collapsed = false})
    : _collapsed = collapsed; // ignore: prefer_initializing_formals

  bool _collapsed;

  /// Whether the bar should show the compact selected-icon button.
  ///
  /// This is the requested target, not the in-flight animation value.
  bool get isCollapsed => _collapsed;

  /// Requests the compact selected-icon button.
  void collapse() => _set(true);

  /// Requests the full navigation bar.
  void expand() => _set(false);

  /// Switches between compact and expanded.
  void toggle() => _set(!_collapsed);

  void _set(bool value) {
    if (_collapsed == value) {
      return;
    }
    _collapsed = value;
    notifyListeners();
  }
}
