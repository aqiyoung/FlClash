import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  Future<double> subtitleSizeFor(WidgetTester tester, Locale locale) async {
    late double size;
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: Builder(
          builder: (context) {
            size = context.listSubtitleStyle.fontSize!;
            return const SizedBox();
          },
        ),
      ),
    );
    return size;
  }

  testWidgets('a Han locale sets the row subtitle a step smaller', (
    tester,
  ) async {
    expect(await subtitleSizeFor(tester, const Locale('zh')), 13);
    expect(await subtitleSizeFor(tester, const Locale('ja')), 13);
  });

  testWidgets('a Latin locale keeps the subtitle at its own size', (
    tester,
  ) async {
    expect(await subtitleSizeFor(tester, const Locale('en')), 15);
  });
}
