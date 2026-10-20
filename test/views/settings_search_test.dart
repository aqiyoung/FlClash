import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/settings_search.dart';
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

  Future<void> pumpSearch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: SettingsSearchView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the page carries a bar titled like the row that opened it', (
    tester,
  ) async {
    await pumpSearch(tester);
    final appLocalizations = tester
        .element(find.byType(SettingsSearchView))
        .appLocalizations;

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(appLocalizations.search),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the field wears the app\'s search pill', (tester) async {
    await pumpSearch(tester);
    final theme = InputDecorationTheme.of(
      tester.element(find.byType(TextField).first),
    );

    expect(theme.filled, isTrue);
    expect(theme.border?.borderSide, BorderSide.none);
  });

  testWidgets('the results sit in one section', (tester) async {
    await pumpSearch(tester);

    // A row outside a section falls back to a bare tile with no card around it.
    expect(find.byType(DecorationListItem), findsWidgets);
  });

  testWidgets('typing a row name leaves only that row', (tester) async {
    await pumpSearch(tester);
    final appLocalizations = tester
        .element(find.byType(SettingsSearchView))
        .appLocalizations;

    await tester.enterText(find.byType(TextField).first, 'vpn');
    await tester.pumpAndSettle();

    expect(find.text('VPN'), findsOneWidget);
    expect(find.text('Hosts'), findsNothing);
    expect(find.text(appLocalizations.autoLaunch), findsNothing);
  });

  testWidgets('typing a list name keeps the rows on that list', (tester) async {
    await pumpSearch(tester);

    await tester.enterText(find.byType(TextField).first, 'network');
    await tester.pumpAndSettle();

    expect(find.text('VPN'), findsOneWidget);
    expect(find.text('Hosts'), findsNothing);
  });

  testWidgets('a query no row carries says so', (tester) async {
    await pumpSearch(tester);
    final appLocalizations = tester
        .element(find.byType(SettingsSearchView))
        .appLocalizations;

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text(appLocalizations.none), findsOneWidget);
    expect(find.text('VPN'), findsNothing);
  });

  testWidgets('clearing the field brings the whole index back', (tester) async {
    await pumpSearch(tester);
    final appLocalizations = tester
        .element(find.byType(SettingsSearchView))
        .appLocalizations;

    await tester.enterText(find.byType(TextField).first, 'vpn');
    await tester.pumpAndSettle();
    expect(find.text(appLocalizations.autoLaunch), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    expect(find.text(appLocalizations.autoLaunch), findsOneWidget);
  });
}
