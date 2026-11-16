import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories.dart';

/// Translates any error coming out of the Firebase SDKs into an
/// [AppException] with one of the stable codes documented on
/// [AppException.code]. This is the ONLY place where Firebase error codes are
/// interpreted.
///
/// Errors that map to 'unknown' (e.g. `permission-denied` from the security
/// rules) are logged with their original code and message first, since the
/// UI only shows a generic message for them.
AppException toAppException(Object error) {
  final mapped = switch (error) {
    AppException() => error,
    FirebaseAuthException() => AppException(
      _authCode(error.code),
      error.message,
    ),
    FirebaseException() => AppException(
      _firestoreCode(error.code),
      error.message,
    ),
    TimeoutException() => AppException('network', error),
    _ => AppException('unknown', error),
  };
  if (mapped.code == 'unknown' && error is! AppException) {
    final detail = error is FirebaseException
        ? '[${error.plugin}/${error.code}] ${error.message}'
        : '$error';
    debugPrint('Unmapped error -> unknown: $detail');
  }
  return mapped;
}

String _authCode(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'INVALID_LOGIN_CREDENTIALS' => 'invalid-credentials',
  'email-already-in-use' => 'email-in-use',
  'weak-password' => 'weak-password',
  'invalid-email' => 'invalid-email',
  'network-request-failed' => 'network',
  _ => 'unknown',
};

String _firestoreCode(String code) => switch (code) {
  'unavailable' || 'deadline-exceeded' => 'network',
  _ => 'unknown',
};

/// Whether [error] means the backend could not be reached (offline or
/// timed out), i.e. maps to AppException('network').
bool isNetworkError(Object error) => switch (error) {
  FirebaseException() => _firestoreCode(error.code) == 'network',
  TimeoutException() => true,
  _ => false,
};

/// Runs [action] and rethrows any failure as an [AppException].
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    Error.throwWithStackTrace(toAppException(e), st);
  }
}

extension FirebaseStreamOps<T> on Stream<T> {
  /// Re-emits errors of this stream as [AppException]s.
  Stream<T> guarded() => transform(
    StreamTransformer.fromHandlers(
      handleError: (e, st, sink) => sink.addError(toAppException(e), st),
    ),
  );

  /// Like rxdart's `switchMap`: for every event, subscribes to the stream
  /// returned by [mapper] and forwards its events, cancelling the previous
  /// inner subscription. Used to follow a pointer document (e.g. the pair's
  /// `activeChallengeId`) to the document it points at.
  Stream<R> switchMap<R>(Stream<R> Function(T value) mapper) {
    late StreamController<R> controller;
    StreamSubscription<T>? outer;
    StreamSubscription<R>? inner;
    var outerDone = false;

    void maybeClose() {
      if (outerDone && inner == null) controller.close();
    }

    controller = StreamController<R>(
      onListen: () {
        outer = listen(
          (value) {
            inner?.cancel();
            inner = mapper(value).listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                inner = null;
                maybeClose();
              },
            );
          },
          onError: controller.addError,
          onDone: () {
            outerDone = true;
            maybeClose();
          },
        );
      },
      onPause: () {
        outer?.pause();
        inner?.pause();
      },
      onResume: () {
        outer?.resume();
        inner?.resume();
      },
      onCancel: () async {
        await inner?.cancel();
        await outer?.cancel();
      },
    );
    return controller.stream;
  }
}
