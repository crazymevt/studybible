import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Builds a Quill [Document] from a stored content string that may be either
/// Quill Delta JSON (the current format) or legacy plain text / Markdown (how
/// journals were stored before rich text). This is the migration safety net:
/// legacy entries are imported verbatim as plain text rather than being lost or
/// clobbered by a failed `Document.fromJson`.
///
/// Only a top-level JSON array is treated as a Delta; anything else — including
/// a bare string, object, or unparseable text — is imported literally so no
/// characters are dropped.
Document documentFromStoredContent(String content) {
  if (content.trim().isEmpty) return Document();
  try {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return Document.fromJson(decoded);
    }
  } catch (_) {
    // Not Delta JSON — fall through and import as plain text.
  }
  // A Quill document must end in a newline.
  final normalized = content.endsWith('\n') ? content : '$content\n';
  return Document.fromDelta(Delta()..insert(normalized));
}
