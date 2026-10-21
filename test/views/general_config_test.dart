import 'package:skyward/enum/enum.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/config.dart';
import 'package:skyward/providers/database.dart';
import 'package:skyward/state.dart';
import 'package:skyward/views/config/general.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    container.read(viewSizeProvider.notifier).value = const Size(1200, 1000);
  });

  tearDown(() => container.dispose());

  Future<void> pumpItem(WidgetTester tester, Widget item) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: Scaffold(body: ListView(children: [item])),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester) async {
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
  }

  Future<void> submitText(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextFormField), text);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
  }

  group('a text row stores what it normalized', () {
    testWidgets('the account row drops the colon user:pass splits on', (
      tester,
    ) async {
      await pumpItem(tester, const AuthenticationAccountItem());
      await openRow(tester);
      await submitText(tester, '  user:name  ');

      expect(
        container.read(networkSettingProvider).authentication.username,
        'username',
      );
    });

    testWidgets('the password row trims the value', (tester) async {
      await pumpItem(tester, const AuthenticationPasswordItem());
      await openRow(tester);
      await submitText(tester, '  secret  ');

      expect(
        container.read(networkSettingProvider).authentication.password,
        'secret',
      );
    });

    testWidgets('the controller secret row trims the value', (tester) async {
      await pumpItem(tester, const ExternalControllerSecretItem());
      await openRow(tester);
      await submitText(tester, '  token  ');

      expect(container.read(patchClashConfigProvider).secret, 'token');
    });
  });

  group('the authentication toggle seeds the account it needs', () {
    testWidgets('an empty account gets a generated pair', (tester) async {
      await pumpItem(tester, const AuthenticationItem());

      expect(
        container.read(networkSettingProvider).authentication.username,
        isEmpty,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final authentication = container
          .read(networkSettingProvider)
          .authentication;
      expect(authentication.enable, isTrue);
      expect(authentication.username, isNotEmpty);
      expect(authentication.password, isNotEmpty);
    });

    testWidgets('a filled account is left alone', (tester) async {
      container
          .read(networkSettingProvider.notifier)
          .update(
            (state) => state.copyWith.authentication(
              username: 'admin',
              password: 'saved',
            ),
          );

      await pumpItem(tester, const AuthenticationItem());
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final authentication = container
          .read(networkSettingProvider)
          .authentication;
      expect(authentication.username, 'admin');
      expect(authentication.password, 'saved');
    });
  });

  group('the log level picker', () {
    testWidgets('writes the level it was given', (tester) async {
      await pumpItem(tester, const LogLevelItem());
      final initial = container.read(patchClashConfigProvider).logLevel;
      final target = LogLevel.values.firstWhere((level) => level != initial);

      await openRow(tester);
      await tester.tap(find.text(target.name).last);
      await tester.pumpAndSettle();

      expect(container.read(patchClashConfigProvider).logLevel, target);
    });
  });

  group('the test url row', () {
    testWidgets('keeps the old value when the text is not a url', (
      tester,
    ) async {
      await pumpItem(tester, const TestUrlItem());
      final initial = container.read(appSettingProvider).testUrl;

      await openRow(tester);
      await submitText(tester, 'not a url');

      expect(container.read(appSettingProvider).testUrl, initial);
    });

    testWidgets('writes a url it accepts', (tester) async {
      await pumpItem(tester, const TestUrlItem());
      await openRow(tester);
      await submitText(tester, 'https://example.com');

      expect(container.read(appSettingProvider).testUrl, 'https://example.com');
    });
  });

  testWidgets('the user agent row shows the override it holds', (tester) async {
    container
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(globalUa: 'MyAgent'));

    await pumpItem(tester, const UaItem());

    expect(find.text('MyAgent'), findsOneWidget);
  });
}
