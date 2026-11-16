/// Whether the app is running as an installed home-screen app (the web
/// version opened from the iPhone/Android home screen, not a browser tab).
library;

export 'standalone_stub.dart'
    if (dart.library.js_interop) 'standalone_web.dart';
