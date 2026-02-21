import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classlly/features/auth/screens/auth_screen.dart';
import 'package:classlly/core/services/cloud_storage_service.dart';
import 'package:classlly/features/library/providers/profile_provider.dart';
import 'package:classlly/features/library/providers/library_provider.dart';
import 'package:classlly/data/repositories/notes_repository.dart';
import 'package:classlly/data/models/user_preferences_model.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';

// Mocks
class MockCloudStorageService extends Mock implements CloudStorageService {}
class MockProfileProvider extends Mock implements ProfileProvider {}
class MockLibraryProvider extends Mock implements LibraryProvider {}
class MockNotesRepository extends Mock implements NotesRepository {}
class MockHttpClient extends Mock implements http.Client {}

// Dummy response for HTTP client
class MockResponse extends Mock implements http.Response {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock SharedPreferences
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );

    // Mock PathProvider (if needed by Hive or Supabase internally)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return '.';
      },
    );

    registerFallbackValue(Uri.parse('https://example.com'));
  });

  testWidgets('AuthScreen UI test', (WidgetTester tester) async {
    // Create mocks
    final mockCloudService = MockCloudStorageService();
    final mockProfileProvider = MockProfileProvider();
    final mockNotesRepository = MockNotesRepository();
    
    // Use the real UserPreferences model
    final realPrefs = UserPreferences(hasCompletedOnboarding: false);

    // Setup Mock Returns
    when(() => mockNotesRepository.getPreferences()).thenReturn(realPrefs);
    
    // Build the widget
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CloudStorageService>.value(value: mockCloudService),
          ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
          Provider<NotesRepository>.value(value: mockNotesRepository),
          ChangeNotifierProvider<LibraryProvider>.value(value: MockLibraryProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuthScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify UI elements
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
    expect(find.byType(ElevatedButton), findsOneWidget); // Sign In Button
    expect(find.byType(TextButton), findsWidgets); // Sign Up & Guest Button
  });
}