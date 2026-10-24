import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/views/dashboard/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

extension DashboardWidgetView on DashboardWidget {
  Widget get card => switch (this) {
    DashboardWidget.currentOutbound => const CurrentOutboundCard(),
    DashboardWidget.networkControl => const NetworkControlCard(),
    DashboardWidget.networkOverview => const NetworkOverviewCard(),
    DashboardWidget.profiles => const ProfilesCard(),
    DashboardWidget.proxyGroups => const ProxyGroupsCard(),
    DashboardWidget.intranetIp => const IntranetIpCard(),
    DashboardWidget.memoryInfo => const MemoryInfo(),
  };

  Glyph get glyph => switch (this) {
    DashboardWidget.currentOutbound => AppGlyphs.status,
    DashboardWidget.networkControl => AppGlyphs.split,
    DashboardWidget.networkOverview => AppGlyphs.verified,
    DashboardWidget.profiles => AppGlyphs.profiles,
    DashboardWidget.proxyGroups => AppGlyphs.layers,
    DashboardWidget.intranetIp => AppGlyphs.devices,
    DashboardWidget.memoryInfo => AppGlyphs.memory,
  };

  String label(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return switch (this) {
      DashboardWidget.currentOutbound => appLocalizations.status,
      DashboardWidget.networkControl => appLocalizations.networkControl,
      DashboardWidget.networkOverview => appLocalizations.networkOverview,
      DashboardWidget.profiles => appLocalizations.profile,
      DashboardWidget.proxyGroups => appLocalizations.proxyGroup,
      DashboardWidget.intranetIp => appLocalizations.intranetIP,
      DashboardWidget.memoryInfo => appLocalizations.memoryInfo,
    };
  }

  String? description(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return switch (this) {
      DashboardWidget.currentOutbound => appLocalizations.currentOutboundDesc,
      DashboardWidget.memoryInfo => appLocalizations.memoryInfoDesc,
      _ => null,
    };
  }

  /// It holds the start button, which has nowhere else to go.
  bool get removable => this != DashboardWidget.currentOutbound;
}
