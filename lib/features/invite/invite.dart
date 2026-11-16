import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';

/// The link that invites someone to a group: opens the download/join page,
/// which offers the Android app or the iPhone web app and shows the code.
String inviteLink(String code) => '$siteUrl/join/${Uri.encodeComponent(code)}';

/// The invite code in a link, or null. Understands
/// `https://…/join/CODE`, `goals://join/CODE` and `…?join=CODE`.
String? parseInviteCode(Uri uri) {
  String? raw;
  if (uri.scheme == 'goals' && uri.host == 'join') {
    raw = uri.pathSegments.firstOrNull;
  } else {
    final segments = uri.pathSegments;
    final i = segments.indexOf('join');
    if (i >= 0 && i + 1 < segments.length) raw = segments[i + 1];
    raw ??= uri.queryParameters['join'] ?? uri.queryParameters['code'];
  }
  final code = raw?.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  return code == null || code.isEmpty ? null : code;
}

/// Shares text through the system share sheet; faked in tests.
abstract interface class Sharer {
  /// Returns false when sharing isn't possible (the caller then copies).
  Future<bool> share(String text);
}

class _PlatformSharer implements Sharer {
  @override
  Future<bool> share(String text) async {
    try {
      final result = await SharePlus.instance.share(ShareParams(text: text));
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}

final sharerProvider = Provider<Sharer>((ref) => _PlatformSharer());

/// Shares [text]; if the share sheet isn't available (e.g. a desktop
/// browser), copies it and says so.
Future<void> shareOrCopy(
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  String text, {
  required String copiedMessage,
}) async {
  if (await ref.read(sharerProvider).share(text)) return;
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(SnackBar(content: Text(copiedMessage)));
}

/// An invite code that arrived through a link and wasn't used yet. The
/// join form fills it in.
final pendingInviteCodeProvider = NotifierProvider<PendingInviteCode, String?>(
  PendingInviteCode.new,
);

class PendingInviteCode extends Notifier<String?> {
  @override
  String? build() => kIsWeb ? parseInviteCode(Uri.base) : null;

  void set(String? code) => state = code;
}

/// Source of incoming links on Android (`goals://join/CODE`); faked in
/// tests. Null where links arrive otherwise (the web reads its address).
abstract interface class IncomingLinks {
  Future<Uri?> initial();
  Stream<Uri> get stream;
}

class _AppLinks implements IncomingLinks {
  final _links = AppLinks();

  @override
  Future<Uri?> initial() => _links.getInitialLink();

  @override
  Stream<Uri> get stream => _links.uriLinkStream;
}

final incomingLinksProvider = Provider<IncomingLinks?>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? _AppLinks()
      : null,
);

/// Listens for invite links while the app runs and stores their code.
class InviteLinkBinding extends ConsumerStatefulWidget {
  const InviteLinkBinding({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<InviteLinkBinding> createState() => _InviteLinkBindingState();
}

class _InviteLinkBindingState extends ConsumerState<InviteLinkBinding> {
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    final links = ref.read(incomingLinksProvider);
    if (links == null) return;
    void take(Uri? uri) {
      final code = uri == null ? null : parseInviteCode(uri);
      if (code != null && mounted) {
        ref.read(pendingInviteCodeProvider.notifier).set(code);
      }
    }

    links.initial().then(take, onError: (_) {});
    _sub = links.stream.listen(take, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
