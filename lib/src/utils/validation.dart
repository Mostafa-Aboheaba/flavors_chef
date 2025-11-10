final _hexColorRegExp = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$');
final _flavorNameRegExp = RegExp(r'^[a-z][a-z0-9_]*$');

bool isValidHexColor(String value) => _hexColorRegExp.hasMatch(value);

bool isValidFlavorName(String value) =>
    _flavorNameRegExp.hasMatch(value) && !value.contains('__');

String sanitizeFlavorName(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (normalized.isEmpty) {
    return 'flavor';
  }
  return normalized;
}
