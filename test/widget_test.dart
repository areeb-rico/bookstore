// Basic smoke test for the Book Store app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookstore/main.dart';

void main() {
  testWidgets('App launches on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BookStoreApp());
    await tester.pumpAndSettle();

    // The login screen should be the first thing the user sees.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
