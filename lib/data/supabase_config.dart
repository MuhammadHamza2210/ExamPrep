/// Supabase project credentials. The anon key is safe to embed in a client
/// app — it only grants access allowed by the Row Level Security policies.
class SupabaseConfig {
  static const String url = 'https://clykenrvenrclsgilmfp.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNseWtlbnJ2ZW5yY2xzZ2lsbWZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0NTQ3OTcsImV4cCI6MjEwMDAzMDc5N30.EBAiRTDHQNz-00b06Q5MlxAPnT0BXAwxIMQpzsPa_Mo';

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.length > 40;
}
