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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';

// Mocks
class MockCloudStorageService extends Mock implements CloudStorageService {}
class MockProfileProvider extends Mock implements ProfileProvider {}
class MockLibraryProvider extends Mock implements LibraryProvider {}
class MockNotesRepository extends Mock implements NotesRepository {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
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

    registerFallbackValue(UserAttributes(data: {}));
    registerFallbackValue(Uri.parse('https://example.com'));
    
    // Mock HTTP client behavior
    final mockHttpClient = MockHttpClient();
    when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response('{"access_token": "fake", "refresh_token": "fake", "user": {"id": "fake", "aud": "authenticated", "role": "authenticated", "email": "fake@example.com", "phone": "", "confirmation_sent_at": "2023-01-01T00:00:00Z", "app_metadata": {"provider": "email", "providers": ["email"]}, "user_metadata": {}, "identities": [], "created_at": "2023-01-01T00:00:00Z", "updated_at": "2023-01-01T00:00:00Z"}}', 200));
    
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{}', 200));

    // Initialize Supabase with mock client
    await Supabase.initialize(
      url: 'https://example.com',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxd2JkdXFkemdlZXZ0Y2lmbnF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTk3NDksImV4cCI6MjA4Mzk5NTc0OX0.8EpXvPIoRrtKBwLM1ad0qd3I_85L-JVJ5HVfy4k6jsg',
      httpClient: mockHttpClient,
    );
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
          home: AuthScreen(),
        ),
      ),
    );

    // Verify UI elements
    expect(find.text('Classlly'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue as Guest (Offline)'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
  });
}