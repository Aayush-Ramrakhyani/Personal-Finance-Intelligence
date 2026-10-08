class AppConstants {
  // Set FINANCE_AI_API_URL env var at build time, e.g.:
  //   flutter build appbundle --dart-define=FINANCE_AI_API_URL=https://api.financeai.app/api/v1
  static const String baseUrl = String.fromEnvironment(
    'FINANCE_AI_API_URL',
    defaultValue: 'https://api.financeai.app/api/v1',
  );
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String appName = 'FinanceAI';
  static const int defaultPageLimit = 20;
  static const int maxCsvSizeMb = 10;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Date formats
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String monthYearFormat = 'MMM yyyy';
}
