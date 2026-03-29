class LogSanitizer {
  LogSanitizer._();

  static final RegExp _ansiRegex = RegExp(
    r'\x1B\[[0-9;]*[A-Za-z]|\x1B\][^\x07]*\x07|\x1B.',
  );
  static final RegExp _boxDrawingRegex = RegExp(
    r'[\u2500-\u259F\u2800-\u28FF]',
  );
  static final RegExp _controlCharsRegex = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );
  static final RegExp _extraSpacesRegex = RegExp(r'  +');

  static String sanitize(String line) {
    var sanitized = line;
    sanitized = sanitized.replaceAll(_ansiRegex, '');
    sanitized = sanitized.replaceAll(_boxDrawingRegex, '');
    sanitized = sanitized.replaceAll(_controlCharsRegex, '');
    sanitized = sanitized.replaceAll(_extraSpacesRegex, ' ').trim();
    return sanitized;
  }
}
