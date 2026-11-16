import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/features/auth/sign_in_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  testWidgets('signed-out user lands on the Hebrew (RTL) sign-in screen', (
    tester,
  ) async {
    await pumpApp(tester, MemoryBackend());
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget); // app title hero
    expect(find.widgetWithText(FilledButton, 'התחברות'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(SignInScreen))),
      TextDirection.rtl,
    );
  });
}
