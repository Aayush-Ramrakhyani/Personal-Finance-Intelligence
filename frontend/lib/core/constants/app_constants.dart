class AppConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';
  static const String appName = 'Finance Intelligence';
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
