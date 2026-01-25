import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classlly/features/library/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    testWidgets('renders title and subtitle correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search,
              title: 'No results',
              subtitle: 'Try searching for something else.',
            ),
          ),
        ),
      );

      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Try searching for something else.'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows action button when onAction is provided', (WidgetTester tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Empty',
              subtitle: 'Add something',
              actionLabel: 'Create',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      final buttonFinder = find.text('Create');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      expect(actionTapped, true);
    });
  });
}
