class Session {
  static String? token;

  static void saveToken(String t) => token = t;

  static String? getToken() => token;

  static void clear() => token = null;
}
