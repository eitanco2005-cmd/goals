import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Translates short texts (goal names and units) between Hebrew and
/// English; faked in tests.
abstract interface class Translator {
  /// [text] translated from language [from] to [to] ('he' / 'en'), or null
  /// when that isn't possible right now (offline, quota, error).
  Future<String?> translate(
    String text, {
    required String from,
    required String to,
  });
}

/// The free MyMemory service (no account; a few thousand characters a day
/// per device, far more than goal names need). Only the text is sent.
class MyMemoryTranslator implements Translator {
  MyMemoryTranslator([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<String?> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    if (text.trim().isEmpty || from == to) return null;
    try {
      final uri = Uri.https('api.mymemory.translated.net', '/get', {
        'q': text,
        'langpair': '$from|$to',
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (body['responseStatus'] != 200) return null;
      final out = ((body['responseData'] as Map?)?['translatedText'] as String?)
          ?.trim();
      // The service answers errors in the text itself (e.g. "MYMEMORY
      // WARNING: ..."); treat those, and echoes, as no translation.
      if (out == null ||
          out.isEmpty ||
          out == text ||
          out.toUpperCase().contains('MYMEMORY')) {
        return null;
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}

final translatorProvider = Provider<Translator>((ref) => MyMemoryTranslator());
