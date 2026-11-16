{{flutter_js}}
{{flutter_build_config}}

// No offline service worker: it made the installed iPhone app keep showing
// an old version after updates. Remove one left from earlier versions (and
// its file caches), then load the app. Firestore's own data is unaffected.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations()
    .then((registrations) => registrations.forEach((r) => r.unregister()))
    .catch(() => {});
  if (window.caches) {
    caches.keys()
      .then((keys) => keys.forEach((key) => caches.delete(key)))
      .catch(() => {});
  }
}

_flutter.loader.load();
