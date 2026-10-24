import 'dart:async';

import 'package:skyward/common/common.dart';
import 'package:skyward/common/service_probe.dart';
import 'package:skyward/core/controller.dart';
import 'package:skyward/core/method.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/providers/outbound_ip.dart';
import 'package:skyward/providers/providers.dart';
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

/// The way out: the address the traffic leaves home by, the hops the
/// subscription puts in the way, and what it was addressed to.
///
/// Clash's connection list already carries all three. `chains` names the hops
/// from the way out back, and its names hold the regions a subscription puts
/// there; `destinationGeoIP` and `sourceGeoIP` say where the two ends are. The
/// near end needs one more lookup: the Core resolves a public address to its
/// country and no further, and the province is what makes the dot land on the
/// right part of the map.
class RoutingBoardCard extends ConsumerStatefulWidget {
  const RoutingBoardCard({super.key});

  @override
  ConsumerState<RoutingBoardCard> createState() => _RoutingBoardCardState();
}

class _RoutingBoardCardState extends ConsumerState<RoutingBoardCard>
    with WidgetsBindingObserver, ActivePollingMixin<RoutingBoardCard> {
  late final OutboundIpProbe _probe;
  List<TrackerInfo> _connections = const [];

  /// Where the traffic leaves home by, asked of a provider that names a
  /// province. Held for as long as the address does not change.
  IpLocation? _location;
  DateTime? _locationAskedAt;
  bool _locationPending = false;
  Duration _locationWait = const Duration(minutes: 15);

  CoreController get _core => ref.read(coreHandlerProvider);

  // A route changes when the group does; the hops behind it move far less than
  // the traffic that rides them.
  @override
  Duration get pollInterval => const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    // The province needs a provider that names one, but the country does not:
    // a plain address lookup answers that even when the richer ones are
    // unreachable from where the phone is.
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
      _locationAskedAt = null;
      if ((_connections.isNotEmpty || _location != null) &&
          isCurrent() &&
          mounted) {
        setState(() {
          _connections = const [];
          _location = null;
        });
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
    unawaited(_askLocation());
  }

  /// A province does not change while the phone stays where it is, and the
  /// lookup costs a round trip through the Core. Fifteen minutes is long
  /// enough to survive a carrier reassignment and short enough to follow one;
  /// a lookup that failed is worth retrying in a minute.
  Future<void> _askLocation() async {
    if (_locationPending) {
      return;
    }
    final askedAt = _locationAskedAt;
    if (askedAt != null && DateTime.now().difference(askedAt) < _locationWait) {
      return;
    }
    _locationPending = true;
    _locationAskedAt = DateTime.now();
    try {
      final location = await lookupIpLocation(_core, directOutbound);
      if (!mounted) {
        return;
      }
      if (location == null) {
        _locationWait = const Duration(minutes: 1);
        return;
      }
      _locationWait = const Duration(minutes: 15);
      setState(() => _location = location);
    } catch (error) {
      _locationWait = const Duration(minutes: 1);
      commonPrint.log(
        'routing board location error: $error',
        logLevel: coreFailureLogLevel(error),
      );
    } finally {
      _locationPending = false;
    }
  }

  /// The connection worth drawing: the one moving the most right now.
  ///
  /// Counting bytes since the connection opened picks whichever download
  /// started earliest and keeps it for the session, which is why the board
  /// used to point at something the phone was not doing. Resolvers and the
  /// reachability pings every platform runs are skipped: they are short,
  /// frequent, and never the answer.
  TrackerInfo? _live() {
    TrackerInfo? fastest;
    var bestSpeed = 0;
    TrackerInfo? newest;
    for (final item in _connections) {
      if (_isNoise(item)) {
        continue;
      }
      final speed = (item.downloadSpeed ?? 0) + (item.uploadSpeed ?? 0);
      if (speed > bestSpeed) {
        bestSpeed = speed;
        fastest = item;
      }
      if (newest == null || item.start.isAfter(newest.start)) {
        newest = item;
      }
    }
    return fastest ?? newest;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    final hideIp = ref.watch(appSettingProvider.select((state) => state.hideIp));
    final active = _live();
    final location = _location;
    final direct = ref
        .watch(
          outboundIpProbeProvider.select(
            (state) => state.entryOf(directOutbound),
          ),
        )
        .value;
    final localCountry =
        geoCountryOfGeoIps(active?.metadata.sourceGeoIP ?? const <String>[]) ??
        geoCountryOf(location?.countryCode) ??
        geoCountryOf(direct?.countryCode);
    // Named down to the province when the provider says which one, and to the
    // city when the address is somewhere the province list does not cover.
    final localPlace = _placeIn(
      localCountry,
      geoPlaceOfRegion(location?.region) ??
          geoCityOfNode(location?.city ?? ''),
    );
    final stops = _stopsOf(active, localCountry, localPlace);
    String? exit;
    for (final name in active?.chains ?? const <String>[]) {
      if (!isBuiltinOutbound(name)) {
        exit = name;
        break;
      }
    }
    final destinationCountry = geoCountryOfGeoIps(
      active?.metadata.destinationGeoIP ?? const <String>[],
    );
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
            children: [
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeFrom,
                  value: localPlace?.label(chinese: chinese) ??
                      localCountry?.label(chinese: chinese),
                  detail: switch (location?.ip ?? direct?.ip) {
                    final ip? => hideIp ? ipMask : ip,
                    null => null,
                  },
                ),
              ),
              const _LegendArrow(),
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeVia,
                  value: exit ?? (active == null ? null : appLocalizations.direct),
                  detail: _relaysOf(active, chinese),
                ),
              ),
              const _LegendArrow(),
              Expanded(
                child: _Legend(
                  label: appLocalizations.routeTo,
                  value: active?.title,
                  detail: destinationCountry?.label(chinese: chinese),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The regions the hops pass through, innermost first, as one line.
  ///
  /// `chains` runs from the way out back towards the device, so reading it
  /// backwards is the order the traffic takes. A name that mentions one region
  /// says nothing the middle column does not already, so the line is left out
  /// rather than repeated.
  String? _relaysOf(TrackerInfo? active, bool chinese) {
    final seen = <GeoCountry>[];
    for (final chain in (active?.chains ?? const <String>[]).reversed) {
      for (final country in geoCountriesOfNode(chain)) {
        if (seen.isEmpty || seen.last != country) {
          seen.add(country);
        }
      }
    }
    if (seen.length < 2) {
      return null;
    }
    return seen.map((country) => country.label(chinese: chinese)).join(' · ');
  }

  /// The device, every region the hops pass through, then the destination.
  ///
  /// `chains` runs from the way out back towards the device, so it is walked
  /// backwards. A node name can name both of its ends, and a relay that does
  /// contributes two dots; two stops in one region would stack on the same
  /// dot, so the second is dropped.
  List<RouteStop> _stopsOf(
    TrackerInfo? active,
    GeoCountry? local,
    GeoPlace? localPlace,
  ) {
    final stops = <RouteStop>[
      if (local != null)
        RouteStop(local, RouteStopRole.local, place: localPlace),
    ];
    void add(GeoCountry country, GeoPlace? place) {
      if (stops.isNotEmpty && stops.last.country == country) {
        return;
      }
      stops.add(RouteStop(country, RouteStopRole.relay, place: place));
    }

    for (final chain in (active?.chains ?? const <String>[]).reversed) {
      final countries = geoCountriesOfNode(chain);
      if (countries.isEmpty) {
        continue;
      }
      // Only the last end of the name is the one the traffic leaves from, so
      // only it is worth pinning to a city — and only when the city is in that
      // country: `东京 02 | 中转 美国` names both, and the dot belongs in the
      // United States.
      final city = _placeIn(countries.last, geoCityOfNode(chain));
      for (var i = 0; i < countries.length; i++) {
        add(countries[i], i == countries.length - 1 ? city : null);
      }
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
      stops[stops.length - 1] = RouteStop(
        destination,
        RouteStopRole.destination,
        place: stops.last.place,
      );
    } else {
      stops.add(RouteStop(destination, RouteStopRole.destination));
    }
    return stops;
  }
}

/// A place is only worth pinning when it sits in the country the address
/// resolved to; a mismatch means the name mentioned somewhere else.
GeoPlace? _placeIn(GeoCountry? country, GeoPlace? place) {
  if (place == null || place.countryCode.isEmpty || country == null) {
    return place;
  }
  return place.countryCode == country.code ? place : null;
}

/// Hosts that answer their own question: a resolver's lookups and the
/// reachability probes each platform runs on a timer.
const _noiseHosts = [
  'connectivitycheck',
  'connectivity-check',
  'captive.apple.com',
  'clients3.google.com',
  'generate_204',
  'msftconnecttest',
  'msftncsi',
  'time.android.com',
  'time.windows.com',
  'dns.alidns',
  'dns.qq.com',
  'doh.pub',
];

bool _isNoise(TrackerInfo item) {
  final metadata = item.metadata;
  if (metadata.network == 'udp' && metadata.destinationPort == '53') {
    return true;
  }
  final host = metadata.host.toLowerCase();
  if (host.isEmpty) {
    return false;
  }
  return _noiseHosts.any(host.contains);
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, this.value, this.detail});

  final String label;
  final String? value;
  final String? detail;

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
        // The line is always there, empty or not, so the three columns keep
        // their values on one baseline.
        Text(
          detail ?? ' ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardText.label(context),
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
    return GlyphIcon(
      AppGlyphs.chevronForward,
      size: 12 * scale,
      color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }
}
