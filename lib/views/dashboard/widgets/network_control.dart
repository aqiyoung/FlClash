import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'intranet_ip.dart';
import 'network_takeover.dart';
import 'outbound_mode.dart';

/// The mode switch and the switches that let traffic through, in one card: all
/// of them answer the same question, how traffic leaves this device and who
/// may come in, and each was a card of its own until the reference layout put
/// them together.
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
          const SizedBox(height: 10),
          if (desktopPlatforms.contains(platform)) ...[
            const TakeoverSwitchRows(),
            const SizedBox(height: 8),
            const LanSwitchRow(showAddress: true),
          ] else if (platform == SupportPlatform.Android)
            // The two switches a phone has sit side by side: each is a single
            // value, and neither needs the card's full width.
            const Row(
              spacing: 8,
              children: [
                Expanded(child: VpnSwitchRow(compact: true)),
                Expanded(
                  child: LanSwitchRow(showAddress: true, compact: true),
                ),
              ],
            )
          else
            const LanSwitchRow(showAddress: true),
        ],
      ),
    );
  }
}
