String defaultAndroidApplicationId({
  required String base,
  required String flavorName,
}) {
  final sanitized = flavorName.replaceAll('_', '');
  final normalizedBase = base.trim();
  if (normalizedBase.isEmpty) {
    return sanitized;
  }
  if (normalizedBase.endsWith('.')) {
    return '$normalizedBase$sanitized';
  }
  return '$normalizedBase.$sanitized';
}

String defaultIosBundleId({required String base, required String flavorName}) {
  final sanitized = flavorName.replaceAll('_', '');
  final normalizedBase = base.trim();
  if (normalizedBase.isEmpty) {
    return sanitized;
  }
  if (normalizedBase.endsWith('.')) {
    return '$normalizedBase$sanitized';
  }
  return '$normalizedBase.$sanitized';
}

String defaultFlavorDisplayName({
  required String baseAppName,
  required String flavorName,
}) {
  final words = flavorName
      .split(RegExp('[\\s_]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
  if (words.isEmpty) {
    return baseAppName;
  }
  return '$baseAppName $words';
}
