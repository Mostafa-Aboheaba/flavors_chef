import 'dart:io';

/// Utility for interactive console prompts with validation.
class ConsolePrompter {
  ConsolePrompter({required this.stdin, required this.stdout});

  final Stdin stdin;
  final Stdout stdout;

  /// Prompts the user for input, optionally providing a default value.
  Future<String> askString({
    required String question,
    String? defaultValue,
    String? hint,
    bool Function(String value)? validate,
    String? validationMessage,
  }) async {
    while (true) {
      stdout.writeln(
        _composePrompt(
          question: question,
          defaultValue: defaultValue,
          hint: hint,
        ),
      );
      stdout.write('> ');
      final raw = stdin.readLineSync();
      final result = (raw == null || raw.isEmpty)
          ? (defaultValue ?? '')
          : raw.trim();
      if (validate == null || validate(result)) {
        if (result.isEmpty && defaultValue == null) {
          stdout.writeln('Please enter a value.');
          continue;
        }
        return result;
      }
      stdout.writeln(validationMessage ?? 'Invalid value.');
    }
  }

  /// Prompts the user for a yes/no answer.
  Future<bool> askYesNo({
    required String question,
    bool defaultValue = true,
  }) async {
    while (true) {
      stdout.writeln('$question (${defaultValue ? 'Y/n' : 'y/N'})');
      stdout.write('> ');
      final raw = stdin.readLineSync();
      if (raw == null || raw.isEmpty) {
        return defaultValue;
      }
      final normalized = raw.trim().toLowerCase();
      if (const ['y', 'yes'].contains(normalized)) {
        return true;
      }
      if (const ['n', 'no'].contains(normalized)) {
        return false;
      }
      stdout.writeln('Please respond with y or n.');
    }
  }

  /// Prompts the user to pick from provided options.
  Future<T> selectFrom<T>({
    required String question,
    required List<T> options,
    required String Function(T option) describe,
  }) async {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'must not be empty');
    }
    while (true) {
      stdout.writeln(question);
      for (final (index, option) in options.indexed) {
        stdout.writeln('  ${index + 1}. ${describe(option)}');
      }
      stdout.write('> ');
      final raw = stdin.readLineSync();
      final parsed = int.tryParse(raw ?? '');
      if (parsed == null || parsed < 1 || parsed > options.length) {
        stdout.writeln('Enter a number between 1 and ${options.length}.');
        continue;
      }
      return options[parsed - 1];
    }
  }

  String _composePrompt({
    required String question,
    String? defaultValue,
    String? hint,
  }) {
    final buffer = StringBuffer(question);
    if (defaultValue != null && defaultValue.isNotEmpty) {
      buffer.write(' (default: $defaultValue)');
    }
    if (hint != null && hint.isNotEmpty) {
      buffer.write('\nHint: $hint');
    }
    return buffer.toString();
  }
}
