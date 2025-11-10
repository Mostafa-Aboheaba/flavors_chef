import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Summary of existing project metadata used as defaults for prompting.
class ProjectMetadata {
  ProjectMetadata({
    required this.projectRoot,
    required this.pubspecName,
    required this.displayName,
    required this.androidApplicationId,
    required this.iosBundleIdentifier,
  });

  final Directory projectRoot;
  final String pubspecName;
  final String displayName;
  final String androidApplicationId;
  final String iosBundleIdentifier;
}

/// Reads the target Flutter project and extracts existing metadata.
class ProjectInspector {
  ProjectInspector({required Directory projectRoot})
    : projectRoot = projectRoot.absolute;

  final Directory projectRoot;

  Future<ProjectMetadata> inspect() async {
    final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw StateError('No pubspec.yaml found in ${projectRoot.path}');
    }

    final pubspecYaml =
        loadYaml(await pubspecFile.readAsString()) as YamlMap? ?? YamlMap();
    final name = pubspecYaml['name']?.toString() ?? 'app';
    final descriptionName = pubspecYaml['description']?.toString() ?? name;
    final displayName = _titleCase(descriptionName.replaceAll('_', ' '));

    final androidId =
        await _readAndroidApplicationId() ??
        'com.example.$name'.replaceAll('-', '_');
    final iosId =
        await _readIosBundleIdentifier() ??
        'com.example.$name'.replaceAll('-', '_');

    return ProjectMetadata(
      projectRoot: projectRoot,
      pubspecName: name,
      displayName: displayName,
      androidApplicationId: androidId,
      iosBundleIdentifier: iosId,
    );
  }

  Future<String?> _readAndroidApplicationId() async {
    final manifestPath = p.join(
      projectRoot.path,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    );
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      return null;
    }
    final content = await manifestFile.readAsString();
    final packageMatch = RegExp(r'package="(?<id>[^"]+)"').firstMatch(content);
    if (packageMatch != null) {
      return packageMatch.namedGroup('id');
    }

    final gradleFile = File(
      p.join(projectRoot.path, 'android', 'app', 'build.gradle'),
    );
    if (!gradleFile.existsSync()) {
      return null;
    }
    final gradleContent = await gradleFile.readAsString();
    final applicationIdMatch = RegExp(
      r'applicationId\s+"(?<id>[^"]+)"',
    ).firstMatch(gradleContent);
    return applicationIdMatch?.namedGroup('id');
  }

  Future<String?> _readIosBundleIdentifier() async {
    final infoPlistPath = p.join(
      projectRoot.path,
      'ios',
      'Runner',
      'Info.plist',
    );
    final plistFile = File(infoPlistPath);
    if (!plistFile.existsSync()) {
      return null;
    }
    final doc = await plistFile.readAsString();
    final regex = RegExp(
      r'<key>CFBundleIdentifier</key>\s*<string>(?<id>[^<]+)</string>',
    );
    final match = regex.firstMatch(doc);
    if (match != null) {
      final bundleId = match.namedGroup('id');
      if (bundleId != null && bundleId != r'$(PRODUCT_BUNDLE_IDENTIFIER)') {
        return bundleId;
      }
    }
    final projectPbx = File(
      p.join(projectRoot.path, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    if (projectPbx.existsSync()) {
      final pbxContent = await projectPbx.readAsString();
      final match = RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(?<id>[^;]+);',
      ).firstMatch(pbxContent);
      if (match != null) {
        return match.namedGroup('id')?.trim();
      }
    }
    return null;
  }

  String _titleCase(String value) {
    final words = LineSplitter.split(value.replaceAll('-', ' '))
        .expand((line) => line.split(' '))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return value;
    }
    return words
        .map(
          (word) =>
              word.substring(0, 1).toUpperCase() +
              word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}
