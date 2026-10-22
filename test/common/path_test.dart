import 'dart:io';

import 'package:skyward/common/common.dart';
import 'package:skyward/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import '../helpers/app_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUpAll(() async {
    root = Directory.systemTemp.createTempSync('path_test');
    await useAppPaths(root);
  });

  tearDownAll(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  test('provider directories match the paths handed to the core', () async {
    const proxiesUrl = 'https://example.com/a.yaml';
    const rulesUrl = 'https://example.com/b.yaml';
    final proxiesDir = await appPath.getProviderDirPath(
      7,
      proxiesProviderDirectoryName,
    );
    final rulesDir = await appPath.getProviderDirPath(
      7,
      rulesProviderDirectoryName,
    );

    final result = await makeRealProfileTask(
      MakeRealProfileState(
        profilesPath: await appPath.profilesPath,
        profileId: 7,
        rawConfig: {
          'proxy-providers': {
            'a': {'type': 'http', 'url': proxiesUrl},
          },
          'rule-providers': {
            'b': {'type': 'http', 'url': rulesUrl},
          },
        },
        realPatchConfig: const PatchClashConfig(),
        appendSystemDns: false,
        proxyGroups: const [],
        rules: const [],
        addedRules: const [],
        defaultUA: 'FlClash',
      ),
    );
    final config = loadYaml(result.yaml) as YamlMap;

    expect(
      config['proxy-providers']['a']['path'],
      join(proxiesDir, 'a@$proxiesUrl'.toMd5()),
    );
    expect(
      config['rule-providers']['b']['path'],
      join(rulesDir, 'b@$rulesUrl'.toMd5()),
    );
  });

  test('confines a provider path the profile tried to choose', () async {
    final proxiesDir = await appPath.getProviderDirPath(
      7,
      proxiesProviderDirectoryName,
    );
    final rulesDir = await appPath.getProviderDirPath(
      7,
      rulesProviderDirectoryName,
    );

    final result = await makeRealProfileTask(
      MakeRealProfileState(
        profilesPath: await appPath.profilesPath,
        profileId: 7,
        rawConfig: {
          'proxy-providers': {
            'escape': {'type': 'file', 'path': '../../../../config.yaml'},
            'urlless': {'type': 'http', 'path': 'cache.db'},
            'literal': {
              'type': 'inline',
              'payload': ['DIRECT'],
            },
          },
          'rule-providers': {
            'sneak': {'type': 'file', 'path': '/etc/hosts'},
          },
        },
        realPatchConfig: const PatchClashConfig(),
        appendSystemDns: false,
        proxyGroups: const [],
        rules: const [],
        addedRules: const [],
        defaultUA: 'FlClash',
      ),
    );
    final config = loadYaml(result.yaml) as YamlMap;

    expect(
      config['proxy-providers']['escape']['path'],
      join(proxiesDir, 'proxy-providers/escape'.toMd5()),
    );
    expect(
      config['proxy-providers']['urlless']['path'],
      join(proxiesDir, 'proxy-providers/urlless'.toMd5()),
    );
    expect(config['proxy-providers']['literal']['path'], isNull);
    expect(
      config['rule-providers']['sneak']['path'],
      join(rulesDir, 'rule-providers/sneak'.toMd5()),
    );
  });

  test('survives a provider section that is not a map', () async {
    final result = await makeRealProfileTask(
      MakeRealProfileState(
        profilesPath: await appPath.profilesPath,
        profileId: 7,
        rawConfig: {
          'proxy-providers': ['not-a-map'],
          'rule-providers': {
            'broken': ['also-not-a-map'],
          },
        },
        realPatchConfig: const PatchClashConfig(),
        appendSystemDns: false,
        proxyGroups: const [],
        rules: const [],
        addedRules: const [],
        defaultUA: 'FlClash',
      ),
    );

    expect(result.yaml, isNotEmpty);
  });

  test('ensureProviderDirs creates both provider directories', () async {
    await appPath.ensureProviderDirs(9);

    for (final type in const [
      proxiesProviderDirectoryName,
      rulesProviderDirectoryName,
    ]) {
      expect(
        Directory(await appPath.getProviderDirPath(9, type)).existsSync(),
        isTrue,
      );
    }

    await expectLater(appPath.ensureProviderDirs(9), completes);
  });

  group('adoptWindowsDataDirectory', () {
    Directory roaming() {
      final directory = Directory.systemTemp.createTempSync('roaming');
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });
      return directory;
    }

    test('moves the FlClash directory under the app name', () async {
      final root = roaming();
      final legacy = Directory(join(root.path, 'com.follow', 'clash'))
        ..createSync(recursive: true);
      File(
        join(legacy.path, 'config.yaml'),
      ).writeAsStringSync('mixed-port: 7890');

      final directory = await adoptWindowsDataDirectory(root.path);

      expect(directory.path, join(root.path, appName));
      expect(
        File(join(directory.path, 'config.yaml')).readAsStringSync(),
        contains('7890'),
      );
      expect(legacy.existsSync(), isFalse);
    });

    test('leaves a directory that already carries the app name', () async {
      final root = roaming();
      final current = Directory(join(root.path, appName))
        ..createSync(recursive: true);
      final legacy = Directory(join(root.path, 'com.follow', 'clash'))
        ..createSync(recursive: true);

      final directory = await adoptWindowsDataDirectory(root.path);

      expect(directory.path, current.path);
      expect(legacy.existsSync(), isTrue);
    });

    test('creates the directory when nothing precedes it', () async {
      final root = roaming();

      final directory = await adoptWindowsDataDirectory(root.path);

      expect(directory.existsSync(), isTrue);
      expect(directory.path, join(root.path, appName));
    });
  });
}
