import 'package:flutter/foundation.dart';

/// Requested visibility for [LiquidGlassNavigationBar].
///
/// This object stores the target only. It does not own a ticker or the
/// selected destination. The navigation bar owns the slide and reads
/// [isHidden] as the target.
///
/// The caller owns the controller. The bar adds and removes its own listener
/// and never disposes a controller it did not create. Dispose this after the
/// bar has dropped it, or set the bar's controller to null before disposing.
///
/// Repeated requests for the state that is already current do not notify.
class LiquidGlassVisibilityController extends ChangeNotifier {
  /// Creates a controller. [hidden] false keeps the bar on screen.
  LiquidGlassVisibilityController({bool hidden = false})
    : _hidden = hidden; // ignore: prefer_initializing_formals

  bool _hidden;

  /// Whether the bar should sit below the viewport.
  ///
  /// This is the requested target, not the in-flight animation value.
  bool get isHidden => _hidden;

  /// Requests the bar to slide off the bottom of the viewport.
  void hide() => _set(true);

  /// Requests the bar to return to its resting position.
  void show() => _set(false);

  /// Switches between hidden and visible.
  void toggle() => _set(!_hidden);

  void _set(bool value) {
    if (_hidden == value) {
      return;
    }
    _hidden = value;
    notifyListeners();
  }
}
