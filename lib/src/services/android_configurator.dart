import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/flavor_definition.dart';
import '../models/flavor_project_context.dart';

/// Applies Android Gradle flavor configuration and resources.
class AndroidConfigurator {
  AndroidConfigurator({required this.context, required this.stdout});

  final FlavorProjectContext context;
  final Stdout stdout;

  Future<void> apply(List<FlavorDefinition> flavors) async {
    await _ensureBaseManifestUsesStringResource();
    await _updateGradleFile(flavors);
    await _ensureSourceSets(flavors);
  }

  Future<void> _ensureBaseManifestUsesStringResource() async {
    final manifestFile = File(
      p.join(
        context.projectRoot.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );
    if (!manifestFile.existsSync()) {
      stdout.writeln(
        '  • Skipping main AndroidManifest.xml update (file not found)',
      );
      return;
    }
    final content = await manifestFile.readAsString();
    final labelPattern = RegExp(r'android:label="([^"]+)"');
    final match = labelPattern.firstMatch(content);
    if (match == null) {
      await _ensureBaseAppNameString();
      return;
    }
    final current = match.group(1);
    if (current == '@string/app_name') {
      await _ensureBaseAppNameString();
      return;
    }
    final updated = content.replaceFirst(
      labelPattern,
      'android:label="@string/app_name"',
    );
    await manifestFile.writeAsString(updated);
    stdout.writeln(
      '  • Updated main Android manifest label to use @string/app_name',
    );

    await _ensureBaseAppNameString();
  }

  Future<void> _ensureBaseAppNameString() async {
    final valuesDir = Directory(
      p.join(
        context.projectRoot.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'values',
      ),
    );
    if (!valuesDir.existsSync()) {
      valuesDir.createSync(recursive: true);
    }
    final stringsFile = File(p.join(valuesDir.path, 'strings.xml'));
    if (!stringsFile.existsSync()) {
      await stringsFile.writeAsString('''
<resources>
    <string name="app_name">${context.appName}</string>
</resources>
''');
      stdout.writeln('  • Created default Android app_name string resource');
      return;
    }

    final content = await stringsFile.readAsString();
    if (content.contains('name="app_name"')) {
      return;
    }
    final updated = content.replaceFirst(
      '</resources>',
      '    <string name="app_name">${context.appName}</string>\n</resources>',
    );
    await stringsFile.writeAsString(updated);
    stdout.writeln('  • Added app_name string to existing resources');
  }

  Future<void> _updateGradleFile(List<FlavorDefinition> flavors) async {
    final gradleFile = File(
      p.join(context.projectRoot.path, 'android', 'app', 'build.gradle'),
    );
    final gradleKtsFile = File(
      p.join(context.projectRoot.path, 'android', 'app', 'build.gradle.kts'),
    );

    final file = gradleFile.existsSync() ? gradleFile : gradleKtsFile;
    if (!file.existsSync()) {
      throw StateError(
        'Unable to find android/app/build.gradle or build.gradle.kts.',
      );
    }

    final isKotlinDsl = file.path.endsWith('.kts');
    final content = await file.readAsString();
    final newBlock = isKotlinDsl
        ? _kotlinDslBlock(flavors)
        : _groovyBlock(flavors);

    final updated = _injectFlavorBlock(original: content, block: newBlock);

    await file.writeAsString(updated);
    stdout.writeln(
      '  • Updated Android Gradle configuration (${p.basename(file.path)})',
    );
  }

  Future<void> _ensureSourceSets(List<FlavorDefinition> flavors) async {
    for (final flavor in flavors) {
      final flavorDir = Directory(
        p.join(context.projectRoot.path, 'android', 'app', 'src', flavor.name),
      );
      final manifestFile = File(p.join(flavorDir.path, 'AndroidManifest.xml'));
      final valuesDir = Directory(p.join(flavorDir.path, 'res', 'values'));
      final stringsFile = File(p.join(valuesDir.path, 'strings.xml'));

      if (!flavorDir.existsSync()) {
        flavorDir.createSync(recursive: true);
      }
      if (!valuesDir.existsSync()) {
        valuesDir.createSync(recursive: true);
      }

      manifestFile.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="@string/app_name"/>
</manifest>
''');

      stringsFile.writeAsStringSync('''
<resources>
    <string name="app_name">${flavor.appName}</string>
</resources>
''');
    }

    stdout.writeln('  • Created Android flavor source sets');
  }

  String _groovyBlock(List<FlavorDefinition> flavors) {
    final buffer = StringBuffer()
      ..writeln('    // >>> FLAVOR_CHEF productFlavors')
      ..writeln('    flavorDimensions "flavor"')
      ..writeln('    productFlavors {');

    for (final flavor in flavors) {
      buffer
        ..writeln('        ${flavor.name} {')
        ..writeln('            dimension "flavor"')
        ..writeln('            applicationId "${flavor.androidApplicationId}"');
      if (flavor.androidApplicationIdSuffix != null) {
        buffer.writeln(
          '            applicationIdSuffix "${flavor.androidApplicationIdSuffix}"',
        );
      }
      buffer.writeln(
        '            resValue "string", "app_name", "${flavor.appName}"',
      );
      if (flavor.versionNameSuffix != null) {
        buffer.writeln(
          '            versionNameSuffix "${flavor.versionNameSuffix}"',
        );
      }
      buffer
        ..writeln('        }')
        ..writeln('');
    }
    buffer
      ..writeln('    }')
      ..writeln('    // <<< FLAVOR_CHEF productFlavors');
    return buffer.toString();
  }

  String _kotlinDslBlock(List<FlavorDefinition> flavors) {
    final buffer = StringBuffer()
      ..writeln('    // >>> FLAVOR_CHEF productFlavors')
      ..writeln('    flavorDimensions += listOf("flavor")')
      ..writeln('    productFlavors {');

    for (final flavor in flavors) {
      buffer
        ..writeln('        create("${flavor.name}") {')
        ..writeln('            dimension = "flavor"')
        ..writeln(
          '            applicationId = "${flavor.androidApplicationId}"',
        );
      if (flavor.androidApplicationIdSuffix != null) {
        buffer.writeln(
          '            applicationIdSuffix = "${flavor.androidApplicationIdSuffix}"',
        );
      }
      buffer.writeln(
        '            resValue("string", "app_name", "${flavor.appName}")',
      );
      if (flavor.versionNameSuffix != null) {
        buffer.writeln(
          '            versionNameSuffix = "${flavor.versionNameSuffix}"',
        );
      }
      buffer
        ..writeln('        }')
        ..writeln('');
    }
    buffer
      ..writeln('    }')
      ..writeln('    // <<< FLAVOR_CHEF productFlavors');
    return buffer.toString();
  }

  String _injectFlavorBlock({required String original, required String block}) {
    final startMarker = '// >>> FLAVOR_CHEF productFlavors';
    final endMarker = '// <<< FLAVOR_CHEF productFlavors';

    final startIndex = original.indexOf(startMarker);
    final endIndex = original.indexOf(endMarker);

    if (startIndex != -1 && endIndex != -1) {
      final before = original.substring(0, startIndex);
      final after = original.substring(endIndex + endMarker.length);
      return '$before$block$after';
    }

    final androidBlockPattern = RegExp(r'android\s*\{');
    final match = androidBlockPattern.firstMatch(original);
    if (match == null) {
      throw StateError('Could not find android { } block in build.gradle.');
    }

    final insertIndex = match.end;
    final before = original.substring(0, insertIndex);
    final after = original.substring(insertIndex);
    return '$before\n$block$after';
  }
}
