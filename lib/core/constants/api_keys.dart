class ApiKeys {
  // RapidAPI - Cricbuzz Cricket
  static const String rapidApiKey = String.fromEnvironment('RAPID_API_KEY'); 
  // Key removed for security. Pass via --dart-define or Cloudflare Environment Variables.
  
  static const String rapidApiHost = 'cricbuzz-cricket.p.rapidapi.com';

  // Cashfree Payments
  static const String cashfreeAppId = String.fromEnvironment('CASHFREE_APP_ID'); 
  static const String cashfreeSecretKey = String.fromEnvironment('CASHFREE_SECRET_KEY'); 
  static const String cashfreeEnvironment = 'PROD';
}
