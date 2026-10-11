import 'package:flutter/material.dart';
import 'package:shadcn_kit/shadcn_kit.dart';

/// A rounded search bar (a pill-shaped [ShadcnInput]) with a magnifier and a
/// clear (×) button.
///
/// Pass [onTap] with [readOnly] to use it as a button that opens a search
/// screen instead of typing in place.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;

  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = ShadcnTheme.of(context);
    Widget field(TextEditingValue value) => ShadcnInput(
          controller: controller,
          placeholder: hint,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: ShadcnInputStyle(
            backgroundColor: t.muted,
            borderColor: t.muted,
            borderRadius: BorderRadius.circular(999),
            height: 44,
            iconSize: 20,
          ),
          leading: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.search_rounded),
          ),
          trailing: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                ),
        );

    // Rebuild only to show/hide the clear button as text changes.
    if (controller == null) return field(TextEditingValue.empty);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, _) => field(value),
    );
  }
}
