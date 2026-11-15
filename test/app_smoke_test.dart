import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';

import 'helpers.dart';

void main() {
  testWidgets('signed-out user lands on sign-in route', (tester) async {
    await pumpApp(tester, MemoryBackend());
    expect(find.text('בקרוב'), findsOneWidget); // placeholder, Hebrew default
  });
}
