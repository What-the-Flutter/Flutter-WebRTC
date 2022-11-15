abstract class Logger {
  static void printRed({required String message, String? filename, String? method, int? line}) =>
      _print(message, 31, filename, method, line);

  static void printGreen({required String message, String? filename, String? method, int? line}) =>
      _print(message, 32, filename, method, line);

  static void printYellow({required String message, String? filename, String? method, int? line}) =>
      _print(message, 33, filename, method, line);

  static void printBlue({required String message, String? filename, String? method, int? line}) =>
      _print(message, 34, filename, method, line);

  static void printMagenta({
    required String message,
    String? filename,
    String? method,
    int? line,
  }) =>
      _print(message, 35, filename, method, line);

  static void printCyan({required String message, String? filename, String? method, int? line}) =>
      _print(message, 36, filename, method, line);

  static void _print(String message, int colorCode, String? file, String? method, int? line) {
    assert((file == null && line == null && method == null) ||
        (file != null && line != null && method != null));
    final fileWithLine = file == null ? '' : '$file - $method:$line - ';
    print('\x1b[${colorCode}m$fileWithLine$message\x1b[0m');
  }
}
