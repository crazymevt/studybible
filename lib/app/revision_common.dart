// Shared constants for the sermon and journal revision-history features.

/// Kinds of revision snapshot. Manual revisions are user-initiated and kept
/// forever; the automatic kinds are capped per entity by [kMaxAutoRevisions].
class RevisionKind {
  static const manual = 'manual';
  static const conflict = 'conflict';
  static const restore = 'restore';
}

/// How many automatic (conflict / pre-restore) revisions to retain per entity
/// before the oldest are pruned. Manual revisions are never auto-pruned.
const int kMaxAutoRevisions = 20;
