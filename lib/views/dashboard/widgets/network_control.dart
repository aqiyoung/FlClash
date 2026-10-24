import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'network_takeover.dart';
import 'outbound_mode.dart';

/// The mode switch and the switches that let traffic through, in one card: all
/// three answer the same question, how traffic leaves this device, and each was
/// a card of its own until the reference layout put them together.
class NetworkControlCard extends ConsumerWidget {
  const NetworkControlCard({super.key, this.platform});

  /// The host's platform when null, so a test can pose as another one.
  final SupportPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = this.platform ?? SupportPlatform.currentPlatform;
    final appLocalizations = context.appLocalizations;
    return DashboardCard(
      semanticLabel: appLocalizations.networkControl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.split,
            title: appLocalizations.networkControl,
          ),
          const SizedBox(height: 12),
          const OutboundModeSelector(),
          if (desktopPlatforms.contains(platform)) ...[
            const SizedBox(height: 10),
            const TakeoverSwitchRows(),
          ] else if (platform == SupportPlatform.Android) ...[
            const SizedBox(height: 10),
            const VpnSwitchRow(),
          ],
        ],
      ),
    );
  }
}
