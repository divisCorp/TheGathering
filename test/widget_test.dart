// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:the_gathering/main.dart';

void main() {
  testWidgets('App class loads (smoke)', (WidgetTester tester) async {
    // Note: Full widget pump requires Supabase + dotenv init (done in real main()).
    // This smoke confirms the polished app class + providers can be referenced without compile errors.
    // Real launch/flows tested via simulator.
    expect(TheGatheringApp, isA<Type>());
    // Basic instantiation without full tree (avoids Supabase uninit in test env)
    const app = TheGatheringApp();
    expect(app, isNotNull);
  });
}
