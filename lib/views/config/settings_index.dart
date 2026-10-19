import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// One row a reader can find by typing part of its name.
///
/// [page] names the list the row sits in, and [view] builds that list, so a
/// hit opens the page the row lives on without the index knowing where the row
/// sits inside it. A row missing here cannot be found by settings search, so a
/// new row should come with its entry.
class SettingsEntry {
  const SettingsEntry({
    required this.title,
    required this.page,
    required this.view,
  });

  final ConfigLabel title;
  final ConfigLabel page;
  final Widget Function(BuildContext context) view;

  Iterable<String?> fieldsOf(AppLocalizations appLocalizations) => [
    title(appLocalizations),
    page(appLocalizations),
  ];
}

/// Rows of the lists that carry enough of them to be worth searching.
final settingsEntries = <SettingsEntry>[..._generalEntries, ..._networkEntries];

final _generalEntries = <SettingsEntry>[
  SettingsEntry(
    title: (l) => l.autoLaunch,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.silentLaunch,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.autoRun,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.minimizeOnExit,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.allowLan,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.externalController,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.externalControllerSecret,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.authentication,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.account,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.password,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.port,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.unifiedDelay,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.tcpConcurrent,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.findProcessMode,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.autoCloseConnections,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.onlyStatisticsProxy,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.checkCertificate,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.autoCheckUpdate,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.appendSystemDns,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.geodataLoader,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.logLevel,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.logcat,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.testUrl,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => l.userAgent,
    page: (l) => l.general,
    view: _generalView,
  ),
  SettingsEntry(
    title: (l) => 'Hosts',
    page: (l) => l.general,
    view: _generalView,
  ),
];

final _networkEntries = <SettingsEntry>[
  SettingsEntry(
    title: (l) => 'VPN',
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.tun,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.stackMode,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => 'MTU',
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.allowBypass,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.bypassPrivateRoute,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.bypassDomain,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.routeAddress,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.routeExcludeAddress,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.systemProxy,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => 'IPv6',
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.autoSetSystemDns,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.dnsHijacking,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.interfaceNameMode,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.interfaceName,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.disableKeepAlive,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.keepAliveIdle,
    page: (l) => l.network,
    view: _networkView,
  ),
  SettingsEntry(
    title: (l) => l.routingMark,
    page: (l) => l.network,
    view: _networkView,
  ),
];

/// Kept as tear-offs so the entries stay const.
Widget _generalView(BuildContext context) => const GeneralView();

Widget _networkView(BuildContext context) => BaseScaffold(
  title: context.appLocalizations.network,
  body: const NetworkListView(),
);
