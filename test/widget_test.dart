import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutumbsetu/main.dart';

void main() {
  testWidgets('KutumbSetu Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KutumbSetuApp());

    // Verify that the title and taglines are rendered.
    expect(find.text('KutumbSetu'), findsOneWidget);
    expect(find.text('Welcome to KutumbSetu'), findsOneWidget);
    expect(find.text('Connecting Families, Traditions, and Communities.'), findsOneWidget);

    // Verify that the "Send OTP" button is present.
    expect(find.text('Send OTP'), findsOneWidget);

    // Verify that the phone field is present.
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
