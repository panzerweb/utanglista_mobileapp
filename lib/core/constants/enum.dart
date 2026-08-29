/*
  ------------------------------------------------------------------
  StoreCategory: "any medium a seller has".
  ------------------------------------------------------------------

  A category is a LABEL, never a mode. Nothing in the app behaves
  differently because of it — it exists so a user running several
  sidelines can tell their stores apart at a glance.

  In particular `personal` covers people who sell online. That is a
  description of the seller, not a feature: UtangLista is fully offline
  in every category and has no network code at all.

    retail    a fixed stall with walk-in buyers — the sari-sari store.
    street    street vendors. Unbarcoded goods (fishball, kwek-kwek),
              customers who still want to utang.
    personal  the general bucket, including online sellers.
*/
enum StoreCategory {
  personal(
    value: 'personal',
    label: 'Personal',
    description: 'Online selling, sidelines, or anything else',
  ),
  retail(
    value: 'retail',
    label: 'Retail',
    description: 'A stall or shop with walk-in customers',
  ),
  street(
    value: 'street',
    label: 'Street',
    description: 'Street vending, usually without barcodes',
  );

  final String value;
  final String label;
  final String description;

  const StoreCategory({
    required this.value,
    required this.label,
    required this.description,
  });

  /*
    Parses the raw column value back into an enum.

    Returns null for null, for an empty string, and for anything
    unrecognised — a category that was removed in a later version must
    render as "no category" rather than crash a list the user cannot
    then get out of.
  */
  static StoreCategory? fromValue(String? value) {
    if (value == null || value.isEmpty) return null;

    for (final category in StoreCategory.values) {
      if (category.value == value) return category;
    }

    return null;
  }
}
