import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient('https://kqwbduqdzgeevtcifnqx.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxd2JkdXFkemdlZXZ0Y2lmbnF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0MTk3NDksImV4cCI6MjA4Mzk5NTc0OX0.8EpXvPIoRrtKBwLM1ad0qd3I_85L-JVJ5HVfy4k6jsg');
  
  try {
    final res = await client.from('tasks').select('*');
    print('DEBUG: Found ${res.length} tasks in Supabase:');
    for (var r in res) {
      print('Task ID: ${r['id']} | User ID: ${r['user_id']} | Updated At: ${r['updated_at']}');
      print('DATA: ${r['data']}');
      print('-------------------');
    }
  } catch (e) {
    print('DEBUG Error: $e');
  }
}
