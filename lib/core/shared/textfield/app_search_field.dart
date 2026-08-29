import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  COMPONENT: the search field every list screen shares.

  Promoted out of the Customers and Products tabs once a third list
  needed one — six screens now search, and six copies of the controller
  dance below is six places for it to drift.

  WHY THIS OWNS A CONTROLLER AT ALL.

  The cubit is the source of truth for the search term, but a
  TextField cannot be driven from state alone: rebuilding it with a
  fresh controller on every keystroke would fight the user's cursor.
  So the field keeps its own controller and syncs in ONE direction —
  when the cubit clears the search (the empty state's "Clear search"
  action, or a filter reset), the field follows. It never pushes the
  controller's text back into state except through [onChanged].

  Debouncing is NOT here. It belongs in the cubit, next to the
  sequence guard that makes it correct — a debounce alone still lets a
  slow query for "ju" land after "juan". See CustomerListCubit.

  Usage:
    AppSearchField(
      value: state.search,
      hintText: 'Name or number',
      onChanged: cubit.search,
      onClear: cubit.clearSearch,
    );
*/
class AppSearchField extends StatefulWidget {
  /// The term the cubit currently holds. Used to sync the field when
  /// the search is cleared from somewhere else on the screen.
  final String value;

  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const AppSearchField({
    super.key,
    required this.value,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // One direction only: follow a clear, never fight a keystroke.
    if (widget.value.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.body1.copyWith(color: AppPalette.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: AppTextStyles.body1.copyWith(color: AppPalette.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppPalette.textMuted,
          size: 20,
        ),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppPalette.textMuted,
                onPressed: () {
                  // Clear both halves: the controller for what is on
                  // screen, the cubit for what is queried.
                  _controller.clear();
                  widget.onClear();
                },
              ),
        filled: true,
        fillColor: AppPalette.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
        ),
      ),
    );
  }
}
