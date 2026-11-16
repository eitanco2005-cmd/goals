import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/goals/goal_texts.dart';
import 'package:goals_challenge/features/goals/translator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  Future<String?> tr(String text, String to) async =>
      {'לימוד': 'Study', 'Study hard': 'ללמוד קשה', 'עמודים': 'pages'}[text];
  Future<String?> offline(String text, String to) async => null;

  group('resolveGoalTexts', () {
    test('a new name is translated into the other language', () async {
      final r = await resolveGoalTexts(
        old: null,
        typed: 'לימוד',
        lang: 'he',
        translate: tr,
      );
      expect(r, (he: 'לימוד', en: 'Study', machine: 'en'));
    });

    test('offline: both languages get what was typed', () async {
      final r = await resolveGoalTexts(
        old: null,
        typed: 'לימוד',
        lang: 'he',
        translate: offline,
      );
      expect(r, (he: 'לימוד', en: 'לימוד', machine: ''));
    });

    test('editing the translated side is a correction', () async {
      final r = await resolveGoalTexts(
        old: (he: 'לימוד', en: 'Study', machine: 'en'),
        typed: 'Studying',
        lang: 'en',
        translate: tr,
      );
      expect(r, (he: 'לימוד', en: 'Studying', machine: ''));
    });

    test('renaming the original translates again', () async {
      final r = await resolveGoalTexts(
        old: (he: 'לימוד', en: 'Study', machine: 'en'),
        typed: 'עמודים',
        lang: 'he',
        translate: tr,
      );
      expect(r, (he: 'עמודים', en: 'pages', machine: 'en'));
    });

    test('unchanged text keeps everything (no request)', () async {
      var asked = false;
      final old = (he: 'לימוד', en: 'Studying', machine: '');
      final r = await resolveGoalTexts(
        old: old,
        typed: 'לימוד',
        lang: 'he',
        translate: (t, to) async {
          asked = true;
          return null;
        },
      );
      expect(r, old);
      expect(asked, isFalse);
    });

    test('offline rename keeps a different other-language name', () async {
      final r = await resolveGoalTexts(
        old: (he: 'לימוד', en: 'Studying', machine: ''),
        typed: 'קריאה',
        lang: 'he',
        translate: offline,
      );
      expect(r, (he: 'קריאה', en: 'Studying', machine: ''));
    });

    test('clearing a unit clears both', () async {
      final r = await resolveGoalTexts(
        old: (he: 'עמודים', en: 'pages', machine: 'en'),
        typed: '',
        lang: 'he',
        translate: tr,
      );
      expect(r, (he: '', en: '', machine: ''));
    });
  });

  group('MyMemoryTranslator', () {
    MyMemoryTranslator answering(Object body, {int status = 200}) =>
        MyMemoryTranslator(
          MockClient((req) async {
            expect(req.url.host, 'api.mymemory.translated.net');
            expect(req.url.queryParameters['langpair'], 'he|en');
            return http.Response.bytes(
              utf8.encode(jsonEncode(body)),
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );

    test('reads the translation', () async {
      final t = answering({
        'responseStatus': 200,
        'responseData': {'translatedText': 'Study for the test'},
      });
      expect(
        await t.translate('לימוד לטסט', from: 'he', to: 'en'),
        'Study for the test',
      );
    });

    test('quota warnings, echoes and errors mean no translation', () async {
      expect(
        await answering({
          'responseStatus': 429,
          'responseData': {'translatedText': 'MYMEMORY WARNING: ...'},
        }).translate('לימוד', from: 'he', to: 'en'),
        isNull,
      );
      expect(
        await answering({
          'responseStatus': 200,
          'responseData': {'translatedText': 'לימוד'},
        }).translate('לימוד', from: 'he', to: 'en'),
        isNull,
      );
      expect(
        await answering(
          {},
          status: 500,
        ).translate('לימוד', from: 'he', to: 'en'),
        isNull,
      );
    });
  });

  testWidgets('a new goal gets a translated name for the other language', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final translator = FakeTranslator({'Meditate': 'מדיטציה'});
    await pumpApp(tester, b, translator: translator);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await scrollToCenter(tester, find.text('Edit goals'));
    await tester.tap(find.text('Edit goals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('goal-name')), 'Meditate');
    final save = find.widgetWithText(FilledButton, 'Save').last;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    final challenge = (await b.watchActiveChallenge('demo-pair').first)!;
    final added = challenge.goals.last;
    expect(added.titleEn, 'Meditate');
    expect(added.titleHe, 'מדיטציה');
    expect(added.machineLang, 'he');
    expect(translator.asked, ['en>he:Meditate']);
    expect(GoalDef.fromMap(added.toMap()).machineLang, 'he');
  });
}
