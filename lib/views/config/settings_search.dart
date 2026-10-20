import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/views/config/settings_index.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Every row the index knows about, narrowed by what the reader typed.
///
/// A row names itself and the list it lives in, so typing a list's name finds
/// everything on it and typing a row's name points at where it lives.
class SettingsSearchView extends StatefulWidget {
  const SettingsSearchView({super.key});

  @override
  State<SettingsSearchView> createState() => _SettingsSearchViewState();
}

class _SettingsSearchViewState extends State<SettingsSearchView> {
  var _query = SearchQuery('');

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final entries = settingsEntries
        .where(
          (entry) => _query.matches(entry.fieldsOf(appLocalizations).toList()),
        )
        .toList();

    return BaseScaffold(
      title: appLocalizations.search,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, context.contentTopPadding, 16, 8),
            child: InputDecorationTheme(
              data: searchPillTheme(context),
              child: SearchField(
                onChanged: (value) =>
                    setState(() => _query = SearchQuery(value)),
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(appLocalizations.none))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListItem.open(
                        title: Text(entry.title(appLocalizations)),
                        subtitle: Text(entry.page(appLocalizations)),
                        widget: entry.view(context),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
