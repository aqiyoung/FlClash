import 'package:skyward/common/common.dart';
import 'package:material_ui/material_ui.dart';

import 'connection_stats.dart';
import 'service_status.dart';

/// The services and the three feeds in one card: the grid says whether the
/// outside world is reachable, the counts underneath say how much is going
/// through, and both open their own list when tapped.
class NetworkOverviewCard extends StatelessWidget {
  const NetworkOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ServiceStatusCard(
      title: context.appLocalizations.networkOverview,
      footer: const ConnectionStatsBar(divider: true),
    );
  }
}
