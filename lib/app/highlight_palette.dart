/// The highlight colours the reader offers, modelled as stable "slots".
///
/// Each highlight stores a slot's [storedHex] (its canonical/original hex) as
/// its `colorHex`. That stored value is a *stable identity*, not a presentation
/// value: it never changes when the displayed colour is retuned or customised,
/// and it stays a valid hex so older app versions still render something sane.
///
/// The *displayed* colour is resolved from the active theme
/// (see `HighlightColors` in `theme/app_themes.dart`), which maps each slot to a
/// per-mode default below, overridden by any user customisation. This is the
/// single source of truth for the swatch pickers, the highlights panel filter,
/// the "Full Palette" achievement, and the theme's default colour maps.
const highlightSlots = <({
  String id,
  String name,
  String storedHex,
  String defaultLightHex,
  String defaultDarkHex,
})>[
  (
    id: 'yellow',
    name: 'Yellow',
    storedHex: '#FBE083',
    defaultLightHex: '#EAC94E',
    defaultDarkHex: '#FBE083',
  ),
  (
    id: 'green',
    name: 'Green',
    storedHex: '#A3E29A',
    defaultLightHex: '#6FB877',
    defaultDarkHex: '#A3E29A',
  ),
  (
    id: 'blue',
    name: 'Blue',
    storedHex: '#A9C7F5',
    defaultLightHex: '#6B9AE0',
    defaultDarkHex: '#A9C7F5',
  ),
  (
    id: 'pink',
    name: 'Pink',
    storedHex: '#F4A8C4',
    defaultLightHex: '#E585A6',
    defaultDarkHex: '#F4A8C4',
  ),
];

/// Superseded stored hexes mapped to their current slot [storedHex].
///
/// The green and blue swatches were revised (they read as near-identical cyan
/// on dark backgrounds); highlights created before that keep their original
/// stored `colorHex`. [canonicalHighlightHex] maps a legacy hex to its
/// replacement so old highlights resolve to the right slot.
const _legacyHighlightHexes = <String, String>{
  '98E2C6': '#A3E29A', // old Green (cyan-leaning)
  'B5E2FA': '#A9C7F5', // old Blue (cyan-leaning)
};

/// Normalises a stored `colorHex` for comparison: upper-case, no leading `#`
/// and no surrounding whitespace.
String normalizeHighlightHex(String hex) =>
    hex.replaceAll('#', '').trim().toUpperCase();

/// Maps a stored `colorHex` to the current slot hex, translating any superseded
/// colour to its replacement. Returns the input unchanged when already current
/// (or unknown).
String canonicalHighlightHex(String hex) =>
    _legacyHighlightHexes[normalizeHighlightHex(hex)] ?? hex;

/// The slot id a stored `colorHex` belongs to, or null if it is not a known
/// palette colour (legacy hexes are resolved first).
String? slotIdForHex(String hex) {
  final canonical = normalizeHighlightHex(canonicalHighlightHex(hex));
  for (final s in highlightSlots) {
    if (normalizeHighlightHex(s.storedHex) == canonical) return s.id;
  }
  return null;
}

/// The stable hex to store on a highlight for [slotId].
String storedHexForSlot(String slotId) =>
    highlightSlots.firstWhere((s) => s.id == slotId).storedHex;

int _argbFromHex(String hex) =>
    int.parse(normalizeHighlightHex(hex), radix: 16) | 0xFF000000;

/// The built-in default colour (ARGB) for [slotId] in the given mode.
int defaultHighlightColorArgb(String slotId, {required bool dark}) {
  final s = highlightSlots.firstWhere((s) => s.id == slotId);
  return _argbFromHex(dark ? s.defaultDarkHex : s.defaultLightHex);
}

/// Resolved `slotId -> ARGB colour` for the given brightness, merging the
/// per-mode defaults with user [overrides] (keyed `'<slotId>_light'` /
/// `'<slotId>_dark'`).
Map<String, int> resolveHighlightColors({
  required bool dark,
  required Map<String, int> overrides,
}) {
  final mode = dark ? 'dark' : 'light';
  return {
    for (final s in highlightSlots)
      s.id: overrides['${s.id}_$mode'] ??
          defaultHighlightColorArgb(s.id, dark: dark),
  };
}
