import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// The shape an empty list takes: a glyph, the line that says there is nothing,
/// and optionally what the reader can do instead.
class EmptyState extends StatelessWidget {
  final Glyph glyph;
  final String title;
  final String? message;

  const EmptyState({
    super.key,
    required this.glyph,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlyphIcon(
              glyph,
              size: 34,
              color: colorScheme.onSurfaceVariant.opacity60,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.headline.of(context),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyle.footnote
                    .of(context)
                    .copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
