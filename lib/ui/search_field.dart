import 'package:fl_clash/common/input_limits.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/inherited.dart';
import 'package:fl_clash/ui/l10n.dart';
import 'package:fl_clash/ui/measure.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:fl_clash/ui/surface.dart';
import 'package:fl_clash/ui/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Below this many items a sheet is short enough to scan without a search.
const sheetSearchMinItemCount = 10;

/// The shape every search field in the app wears: a filled pill as tall as the
/// dock's, so a page's search and the dock's read as the same control.
///
/// [filled] is false where the field sits on liquid glass, which brings its own
/// surface.
InputDecorationThemeData searchPillTheme(
  BuildContext context, {
  bool filled = true,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final pill = AppShape.input.copyWith(borderRadius: AppRadius.full);
  final fieldPadding =
      (BottomInsetScope.dockedSearchHeight -
          MeasureScope.of(context).textHeight(AppTextStyle.body)) /
      2;
  return InputDecorationTheme.of(context).copyWith(
    filled: filled,
    fillColor: SurfaceLevel.floatingOf(colorScheme).colorOf(colorScheme),
    border: pill.copyWith(borderSide: BorderSide.none),
    focusedBorder: pill.copyWith(
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: fieldPadding,
    ),
  );
}

class SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const SearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.focusNode,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = UiLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (_, value, _) {
        return TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          textInputAction: TextInputAction.search,
          style: AppTextStyle.body.of(context),
          inputFormatters: TextInputLimits.limit(TextInputLimits.search),
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            hintText: localizations.search,
            prefixIcon: const GlyphIcon(AppGlyphs.search, size: 20),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: localizations.clearSearch,
                    onPressed: _handleClear,
                    icon: const GlyphIcon(AppGlyphs.close, size: 20),
                  ),
          ),
        );
      },
    );
  }
}
