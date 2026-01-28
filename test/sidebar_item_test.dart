import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classlly/features/library/widgets/dashboard_sidebar.dart';
import 'test_helper.dart';

void main() {
  group('SidebarItem Widget Tests', () {
    testWidgets('renders icon and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWidget(
          SidebarItem(
            icon: Icons.home,
            label: 'Home',
            isActive: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('shows active styling when isActive is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(
          SidebarItem(
            icon: Icons.home,
            label: 'Home',
            isActive: true,
            onTap: () {},
          ),
        ),
      );

      // Active item has a different text color (white)
      final text = tester.widget<Text>(find.text('Home'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('triggers onTap when pressed', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          SidebarItem(
            icon: Icons.home,
            label: 'Home',
            isActive: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      expect(tapped, true);
    });
  });
}
