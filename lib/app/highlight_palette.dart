/// The canonical highlight colours the reader offers.
///
/// Single source of truth for everything that needs the palette — the verse
/// action bar swatches, the highlights panel filter, and the "Full Palette"
/// achievement that rewards using them all. Adding or removing a colour here
/// updates all of them, including the achievement threshold, so the reward can
/// never drift out of reach of the colours actually on offer.
const highlightPalette = <({String hex, String name})>[
  (hex: '#FBE083', name: 'Yellow'),
  (hex: '#A3E29A', name: 'Green'),
  (hex: '#A9C7F5', name: 'Blue'),
  (hex: '#F4A8C4', name: 'Pink'),
];

/// Superseded highlight hexes mapped to their current palette hex.
///
/// The green and blue swatches were revised (they read as near-identical cyan
/// on dark backgrounds); highlights created before that keep their original
/// stored `colorHex`. Rather than rewrite the database — which would churn sync
/// and diverge from not-yet-upgraded devices — [canonicalHighlightHex] maps a
/// legacy hex to its replacement so old highlights render, name, filter, and
/// count toward the achievement exactly as if they used the new colour.
const _legacyHighlightHexes = <String, String>{
  '98E2C6': '#A3E29A', // old Green (cyan-leaning)
  'B5E2FA': '#A9C7F5', // old Blue (cyan-leaning)
};

/// Normalises a stored `colorHex` for comparison: upper-case, no leading `#`
/// and no surrounding whitespace, so palette membership survives any legacy or
/// cross-device formatting differences.
String normalizeHighlightHex(String hex) =>
    hex.replaceAll('#', '').trim().toUpperCase();

/// Maps a stored `colorHex` to the current palette hex, translating any
/// superseded colour to its replacement. Returns the input unchanged when it is
/// already current (or unknown), so it is safe to route every stored hex
/// through this before rendering, naming, or filtering.
String canonicalHighlightHex(String hex) =>
    _legacyHighlightHexes[normalizeHighlightHex(hex)] ?? hex;
