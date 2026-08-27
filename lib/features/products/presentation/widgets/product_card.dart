import 'package:flutter/material.dart';
import 'package:utanglista_mobileapp/core/styles/app_palette.dart';
import 'package:utanglista_mobileapp/core/styles/app_text_styles.dart';
import 'package:utanglista_mobileapp/features/products/domain/entities/product_entity.dart';

/*
  One product in the catalogue.

  The barcode is shown when present and the row simply omits it when
  not — no "no barcode" placeholder. Half a street vendor's catalogue
  has none, and labelling every row with an absence would make the
  normal case look like a gap in the data.
*/
class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  /// Highlights a product the user just scanned, so it is findable in a
  /// long list without scrolling for it.
  final bool isHighlighted;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = !product.isActive;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isHighlighted ? AppPalette.primarySoft : AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isHighlighted ? AppPalette.primary : AppPalette.border,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          // Deactivated products stay readable, just clearly set back
          // from the ones still on sale (§28).
          opacity: isInactive ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isInactive
                        ? AppPalette.surfaceSubtle
                        : AppPalette.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    product.hasBarcode
                        ? Icons.qr_code_2_rounded
                        : Icons.inventory_2_outlined,
                    size: 20,
                    color: isInactive
                        ? AppPalette.textMuted
                        : AppPalette.primaryDark,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body1.copyWith(
                                color: AppPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          if (isInactive) ...[
                            const SizedBox(width: 6),
                            _Tag(
                              label: 'Inactive',
                              color: AppPalette.textSecondary,
                              background: AppPalette.textMuted.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children: [
                          Text(
                            product.price.format(),
                            style: AppTextStyles.body1.copyWith(
                              color: AppPalette.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' / ${product.unit}',
                            style: AppTextStyles.caption1.copyWith(
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      if (product.hasBarcode) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 12,
                              color: AppPalette.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.barcode!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption1.copyWith(
                                  color: AppPalette.textMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Tag({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption1.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
