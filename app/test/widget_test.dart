import 'package:app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the empty device list with an add button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LedctlApp()));

    expect(find.text('Światło'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.textContaining('Brak urządzeń'), findsOneWidget);
  });

  testWidgets('add-device dialog accepts a ws:// URL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LedctlApp()));

    // Loopback + an unlikely-to-be-listening port: the tile immediately
    // starts a real NativeDriver, which will retry forever if nothing ever
    // answers. Deliberately not using pumpAndSettle once that driver exists
    // — its reconnect loop keeps producing new frames, so it would never
    // settle. The bottom sheet itself has nothing running yet, so
    // pumpAndSettle is fine for its open animation.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj po adresie IP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ws://127.0.0.1:9/ws');
    await tester.tap(find.text('Dodaj'));
    // The dialog's own exit transition needs pumpAndSettle (a single pump,
    // even with an explicit duration, leaves it half-closed in the tree).
    // The NativeDriver that starts right after uses a bare Timer for its
    // reconnect backoff, not a ticker/animation, so it doesn't keep
    // scheduling frames and pumpAndSettle still terminates.
    await tester.pumpAndSettle();

    expect(find.textContaining('Brak urządzeń'), findsNothing);
    expect(find.text('ws://127.0.0.1:9/ws'), findsOneWidget);
  });
}
