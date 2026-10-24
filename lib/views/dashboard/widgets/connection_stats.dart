import 'package:skyward/common/common.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'connections_table.dart';

/// The counts of the three feeds, each opening its list, for the phone and
/// for a desktop page too short for the table.
class ConnectionStatsCard extends StatelessWidget {
  const ConnectionStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      semanticLabel: context.appLocalizations.connectionStats,
      padding: EdgeInsets.zero,
      child: const ConnectionStatsBar(),
    );
  }
}

/// The same counts as a row, for a card that holds other things above them. It
/// keeps the card's polling, so the counts are as fresh here as they were
/// alone.
class ConnectionStatsBar extends ConsumerStatefulWidget {
  const ConnectionStatsBar({super.key, this.divider = false});

  /// A hairline above the counts, for the card they now sit at the bottom of.
  final bool divider;

  @override
  ConsumerState<ConnectionStatsBar> createState() => _ConnectionStatsBarState();
}

class _ConnectionStatsBarState extends ConsumerState<ConnectionStatsBar>
    with
        WidgetsBindingObserver,
        ActivePollingMixin<ConnectionStatsBar>,
        RouteMotionHoldMixin<ConnectionStatsBar>,
        ConnectionsPolling<ConnectionStatsBar> {
  static const _inset = 8.0;

  @override
  bool get pollsConnections => false;

  @override
  Widget build(BuildContext context) {
    final shape = AppShape.all(
      dashboardCardRadius(DashboardDensityScope.of(context)) - _inset,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.divider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: context.colorScheme.outlineVariant,
          ),
        Padding(
          padding: const EdgeInsets.all(_inset),
          child: Row(
            children: [
              _Stat(
                feed: DashboardFeed.connections,
                shape: shape,
                count: ValueListenableBuilder(
                  valueListenable: connectionCount,
                  builder: (context, count, _) => _Count(count),
                ),
              ),
              _Stat(
                feed: DashboardFeed.requests,
                shape: shape,
                count: ThrottledCount(
                  provider: requestCountProvider,
                  builder: (_, count) => _Count(count),
                ),
              ),
              _Stat(
                feed: DashboardFeed.dns,
                shape: shape,
                count: ThrottledCount(
                  provider: dnsQueryCountProvider,
                  builder: (_, count) => _Count(count),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      dashboardCount(count),
      maxLines: 1,
      style: DashboardText.figure(
        context,
        AppTextStyle.title2,
      ).copyWith(letterSpacing: 0),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.feed, required this.shape, required this.count});

  final DashboardFeed feed;
  final OutlinedBorder shape;
  final Widget count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: feed.page.label,
        child: FocusRing(
          shape: shape,
          child: InkWell(
            customBorder: shape,
            hoverColor: DashboardColors.of(context).tone,
            onTap: () => openDashboardFeed(context, feed),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  count,
                  Text(
                    feed.page.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DashboardText.label(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
