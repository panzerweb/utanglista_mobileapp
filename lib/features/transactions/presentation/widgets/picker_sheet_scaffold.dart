import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';

/*
  The shared frame for the customer and product pickers: drag handle,
  title, search field, and a draggable scrollable body.

  Extracted because the two sheets differ only in what they list — and
  a picker that behaves differently depending on what it is picking is
  a picker the user has to learn twice.
*/
class PickerSheetScaffold extends StatefulWidget {
  final String title;
  final String searchHint;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;

  /// Built with the sheet's scroll controller — the list MUST use it,
  /// or dragging the sheet and scrolling the list fight each other.
  final Widget Function(ScrollController scrollController) builder;

  /// Optional action beside the search field, e.g. the scan button.
  final Widget? trailingAction;

  const PickerSheetScaffold({
    super.key,
    required this.title,
    required this.searchHint,
    required this.searchText,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.builder,
    this.trailingAction,
  });

  @override
  State<PickerSheetScaffold> createState() => _PickerSheetScaffoldState();
}

class _PickerSheetScaffoldState extends State<PickerSheetScaffold> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.searchText,
  );

  @override
  void didUpdateWidget(PickerSheetScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.searchText.isEmpty && _controller.text.isNotEmpty) {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppPalette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppPalette.textSecondary,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: widget.onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: AppTextStyles.body1.copyWith(
                          color: AppPalette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: widget.searchHint,
                          hintStyle: AppTextStyles.body1.copyWith(
                            color: AppPalette.textMuted,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppPalette.textMuted,
                            size: 20,
                          ),
                          suffixIcon: widget.searchText.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  color: AppPalette.textMuted,
                                  onPressed: () {
                                    _controller.clear();
                                    widget.onSearchCleared();
                                  },
                                ),
                          filled: true,
                          fillColor: AppPalette.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppPalette.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (widget.trailingAction != null) ...[
                      const SizedBox(width: 8),
                      widget.trailingAction!,
                    ],
                  ],
                ),
              ),

              Expanded(child: widget.builder(scrollController)),
            ],
          ),
        );
      },
    );
  }
}
