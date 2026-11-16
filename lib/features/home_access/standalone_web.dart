import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('navigator.standalone')
external JSBoolean? get _iosStandalone;

/// True when opened from the home screen (display-mode standalone), or the
/// iOS-only `navigator.standalone` flag.
bool get runningStandalone {
  try {
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
    return _iosStandalone?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Safari or another browser on an iPhone/iPad, where installing means
/// Share → "Add to Home Screen".
bool get isIosBrowser {
  final ua = web.window.navigator.userAgent;
  return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      // iPadOS reports itself as a Mac with touch.
      (ua.contains('Macintosh') && web.window.navigator.maxTouchPoints > 1);
}
