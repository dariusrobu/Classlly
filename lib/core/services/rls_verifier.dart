import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

enum RLSStatus { enabled, disabled, misconfigured, untested }

class RLSVerificationResult {
  final RLSStatus status;
  final String message;
  final DateTime timestamp;

  RLSVerificationResult({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  bool get isSecure => status == RLSStatus.enabled;
}

class RLSVerifier {
  final SupabaseClient _client;

  RLSVerifier() : _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<RLSVerificationResult> verify() async {
    if (_userId == null) {
      return RLSVerificationResult(
        status: RLSStatus.untested,
        message: 'No user logged in',
        timestamp: DateTime.now(),
      );
    }

    try {
      return await _testRLSEnforcement();
    } catch (e) {
      debugPrint('RLS_VERIFIER_ERROR: $e');
      return RLSVerificationResult(
        status: RLSStatus.misconfigured,
        message: 'Verification failed: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<RLSVerificationResult> _testRLSEnforcement() async {
    final testId = 'rls_verify_${DateTime.now().millisecondsSinceEpoch}';
    const fakeUserId = '00000000-0000-0000-0000-000000000000';

    try {
      await _client.from('sync_store').upsert({
        'id': testId,
        'user_id': fakeUserId,
        'collection': 'rls_test',
        'data': {'test': true},
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _client
          .from('sync_store')
          .delete()
          .eq('id', testId)
          .eq('collection', 'rls_test');

      return RLSVerificationResult(
        status: RLSStatus.disabled,
        message: 'RLS appears to be DISABLED - cross-user write succeeded',
        timestamp: DateTime.now(),
      );
    } on PostgrestException catch (e) {
      final errorMsg = e.message.toLowerCase();
      if (errorMsg.contains('row-level security') ||
          errorMsg.contains('rls') ||
          errorMsg.contains('permission')) {
        return RLSVerificationResult(
          status: RLSStatus.enabled,
          message: 'RLS is properly enforced',
          timestamp: DateTime.now(),
        );
      }
      return RLSVerificationResult(
        status: RLSStatus.misconfigured,
        message: 'Unexpected error: ${e.message}',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<bool> canAccessOwnData() async {
    if (_userId == null) return false;
    try {
      await _client
          .from('sync_store')
          .select('id')
          .eq('user_id', _userId!)
          .limit(1);
      return true;
    } catch (e) {
      debugPrint('RLS canAccessOwnData error: $e');
      return false;
    }
  }

  Future<bool> canAccessOtherUserData() async {
    if (_userId == null) return false;
    const fakeUserId = '00000000-0000-0000-0000-000000000000';
    try {
      final result = await _client
          .from('sync_store')
          .select('id')
          .eq('user_id', fakeUserId)
          .limit(1);
      return (result as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
