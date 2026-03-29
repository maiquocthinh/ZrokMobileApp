class CommandParser {
  static const validCommands = [
    'share',
    'access',
    'reserve',
    'status',
    'overview',
    'enable',
    'disable',
    'invite',
  ];
  static const validModes = ['public', 'private'];

  /// Parse raw user input into structured parts.
  /// Returns null if invalid.
  static CommandParseResult? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Remove "zrok" or "zrok2" prefix if present
    String clean = trimmed;
    if (trimmed.startsWith('zrok ')) {
      clean = trimmed.substring(5).trim();
    } else if (trimmed.startsWith('zrok2 ')) {
      clean = trimmed.substring(6).trim();
    }

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;

    final command = parts[0].toLowerCase();
    if (!validCommands.contains(command)) return null;

    return CommandParseResult(
      command: command,
      args: parts.sublist(1),
      fullCommand: clean,
    );
  }

  /// Generate the full command string for display.
  static String display(String command) => 'zrok $command';
}

class CommandParseResult {
  final String command;
  final List<String> args;
  final String fullCommand;

  const CommandParseResult({
    required this.command,
    required this.args,
    required this.fullCommand,
  });

  String get mode => args.isNotEmpty ? args[0] : '';
  String get target => args.length > 1 ? args[1] : '';
}
