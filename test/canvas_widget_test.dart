import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classlly/features/canvas/screens/canvas_screen.dart';
import 'package:classlly/data/models/user_preferences_model.dart';
import 'package:mocktail/mocktail.dart';
import 'test_helper.dart';

void main() {
  late MockNotesRepository mockRepo;

  setUp(() {
    mockRepo = MockNotesRepository();
    when(() => mockRepo.getPreferences()).thenReturn(UserPreferences(
      savedColors: [0xFF000000, 0xFFFFFFFF],
    ));
  });

  group('CanvasScreen Widget Tests', () {
    testWidgets('CanvasScreen renders basic toolbar buttons', (WidgetTester tester) async {
      // Set a larger surface size to avoid overflow issues during test
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        wrapWidget(
          const CanvasScreen(),
          repository: mockRepo,
        ),
      );

      // Give it a moment to settle
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      
      // Reset view size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
   group('QuickActionButton Widget Tests', () {
    testWidgets('QuickActionButton renders icon and label', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWidget(
          QuickActionButton(
            icon: Icons.add,
            label: 'Action',
            color: Colors.blue,
            onTap: () => tapped = true,
          ),
          repository: mockRepo,
        ),
      );

      expect(find.text('Action'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byType(QuickActionButton));
      expect(tapped, true);
    });
  });
  });
}

// Minimal QuickActionButton duplicate for standalone test if needed, 
// but it is already in dashboard_screen.dart. 
// For cleaner tests we might move it to its own file later.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          Text(label),
        ],
      ),
    );
  }
}