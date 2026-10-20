import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The facts about a node that its card has no room for.
class ProxyDetailSheet extends ConsumerWidget {
  final Proxy proxy;
  final String? testUrl;

  const ProxyDetailSheet({super.key, required this.proxy, this.testUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: testUrl),
    );
    final delayText = delay == null
        ? appLocalizations.noData
        : delay > 0
        ? '$delay ms'
        : delayFailureText(delay, appLocalizations);
    return CommonScaffold(
      title: appLocalizations.details(appLocalizations.nodes),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(top: context.contentTopPadding, bottom: 16),
        children: [
          generateSection(
            items: [
              ListItem(
                title: Text(appLocalizations.name),
                subtitle: Text(proxy.name),
                trailing: IconButton(
                  tooltip: appLocalizations.copy,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: proxy.name)),
                  icon: const GlyphIcon(AppGlyphs.copy),
                ),
              ),
              ListItem(
                title: Text(appLocalizations.type),
                trailing: Text(proxy.type, style: context.listSubtitleStyle),
              ),
              ListItem(
                title: Text(appLocalizations.delay),
                trailing: Text(delayText, style: context.listSubtitleStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
