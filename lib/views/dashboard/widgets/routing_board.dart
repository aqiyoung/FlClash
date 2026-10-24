import 'package:skyward/common/common.dart';
import 'package:skyward/common/service_probe.dart';
import 'package:skyward/core/controller.dart';
import 'package:skyward/core/method.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/app.dart';
import 'package:skyward/providers/core.dart';
import 'package:skyward/providers/outbound_ip.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:skyward/views/dashboard/layout.dart';
import 'package:skyward/views/dashboard/style.dart';
import 'package:skyward/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';
import 'current_outbound.dart';
import 'routing_map.dart';

/// The way out: the device, the hops the subscription puts in the way, and the
/// address the traffic was bound for.
///
/// Clash's connection list already carries all three. `chains` names the hops
/// from the way out back, and its names hold the regions a subscription puts
/// there; `destinationGeoIP` and `sourceGeoIP` say where the two ends are.
class RoutingBoardCard extends ConsumerStatefulWidget {
  const RoutingBoardCard({super.key});

  @override
  ConsumerState<RoutingBoardCard> createState() => _RoutingBoardCardState();
}

class _RoutingBoardCardState extends ConsumerState<RoutingBoardCard>
    with WidgetsBindingObserver, ActivePollingMixin<RoutingBoardCard> {
  late final OutboundIpProbe _probe;
  List<TrackerInfo> _connections = const [];

  CoreController get _core => ref.read(coreHandlerProvider);

  // A route changes when the group does; the hops behind it move far less than
  // the traffic that rides them.
  @override
  Duration get pollInterval => const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _probe = ref.read(outboundIpProbeProvider.notifier)..watch(directOutbound);
  }

  @override
  void dispose() {
    _probe.unwatch(directOutbound);
    super.dispose();
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    if (ref.read(coreStatusProvider) != CoreStatus.connected) {
      if (_connections.isNotEmpty && isCurrent() && mounted) {
        setState(() => _connections = const []);
      }
      return;
    }
    try {
      final next = await _core.getConnections();
      if (!isCurrent() || !mounted) {
        return;
      }
      setState(() => _connections = next);
    } catch (error) {
      commonPrint.log(
        'routing board error: $error',
        logLevel: coreFailureLogLevel(error),
      );
    }
  }

  /// The busiest connection is the one worth drawing: it holds still from one
  /// poll to the next, and it is what the phone is actually doing. A connection
  /// whose region the Core resolved wins, since the other end has nothing to
  /// pin to the map without it.
  TrackerInfo? _busiest() {
    TrackerInfo? best;
    var bestResolved = false;
    var bestTraffic = -1;
    for (final item in _connections) {
      final resolved = geoCountryOfGeoIps(item.metadata.destinationGeoIP) != null;
      final traffic = item.upload + item.download;
      if (best == null ||
          (resolved && !bestResolved) ||
          (resolved == bestResolved && traffic > bestTraffic)) {
        best = item;
        bestResolved = resolved;
        bestTraffic = traffic;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final active = _busiest();
    final direct = ref
        .watch(
          outboundIpProbeProvider.select(
            (state) => state.entryOf(directOutbound),
          ),
        )
        .value;
    // The device's own region: the Core resolves it for the connection when it
    // can, and a direct lookup answers for the rest.
    final local =
        geoCountryOfGeoIps(active?.metadata.sourceGeoIP ?? const <String>[]) ??
        geoCountryOf(direct?.countryCode);
    final stops = _stopsOf(active, local);
    String? exit;
    for (final name in active?.chains ?? const <String>[]) {
      if (!isBuiltinOutbound(name)) {
        exit = name;
        break;
      }
    }
    final relay = active == null ? null : (exit ?? appLocalizations.direct);
    final destination = active?.title;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.proxies,
            title: appLocalizations.routeBoard,
          ),
          const SizedBox(height: 14),
          RouteMap(stops: stops),
          const SizedBox(height: 16),
          Row(
            spacing: 6,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeFrom,
                  value: local?.label(chinese: chinese),
                ),
              ),
              const _LegendArrow(),
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeVia,
                  value: relay,
                ),
              ),
              const _LegendArrow(),
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeTo,
                  value: destination,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The device, every hop whose name names a region, then the destination.
  ///
  /// `chains` runs from the way out back towards the device, so it is walked
  /// backwards. Two hops in one region would stack on the same dot.
  List<RouteStop> _stopsOf(TrackerInfo? active, GeoCountry? local) {
    final stops = <RouteStop>[
      if (local != null) RouteStop(local, RouteStopRole.local),
    ];
    for (final chain in (active?.chains ?? const <String>[]).reversed) {
      final country = geoCountryOfNode(chain);
      if (country == null) {
        continue;
      }
      if (stops.isNotEmpty && stops.last.country == country) {
        continue;
      }
      stops.add(RouteStop(country, RouteStopRole.relay));
    }
    final destination = geoCountryOfGeoIps(
      active?.metadata.destinationGeoIP ?? const <String>[],
    );
    if (destination == null) {
      return stops;
    }
    if (stops.isNotEmpty &&
        stops.last.country == destination &&
        stops.last.role == RouteStopRole.relay) {
      stops[stops.length - 1] = RouteStop(destination, RouteStopRole.destination);
    } else {
      stops.add(RouteStop(destination, RouteStopRole.destination));
    }
    return stops;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.value(context, AppTextStyle.subheadline),
        ),
      ],
    );
  }
}

/// Points at the next stop rather than saying anything, so it stays quiet.
class _LegendArrow extends StatelessWidget {
  const _LegendArrow();

  @override
  Widget build(BuildContext context) {
    final scale = DashboardDensityScope.scaleOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * scale),
      child: GlyphIcon(
        AppGlyphs.chevronForward,
        size: 12 * scale,
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
