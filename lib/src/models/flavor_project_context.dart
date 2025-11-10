import 'dart:io';

import 'package:path/path.dart' as p;

/// Shared context for the project being flavorized.
class FlavorProjectContext {
  FlavorProjectContext({
    required Directory projectRoot,
    required this.appName,
    required this.androidApplicationId,
    required this.iosBundleId,
  }) : projectRoot = projectRoot.absolute;

  /// Root folder of the target Flutter project.
  final Directory projectRoot;

  /// Base application display name.
  final String appName;

  /// Base Android application id used if a flavor omits an override.
  final String androidApplicationId;

  /// Base iOS bundle identifier used if a flavor omits an override.
  final String iosBundleId;

  /// Returns the absolute path helper.
  String resolvePath(String relativeOrAbsolute) {
    if (p.isAbsolute(relativeOrAbsolute)) {
      return p.normalize(relativeOrAbsolute);
    }
    return p.normalize(p.join(projectRoot.path, relativeOrAbsolute));
  }
}
