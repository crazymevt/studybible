import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'dart:convert';
void main() {
  final d = Delta()
    ..insert('Introduction')
    ..insert('\n', {'header': 2})
    ..insert('Point 1: ', {'bold': true})
    ..insert('Some text')
    ..insert('\n', {'list': 'bullet'});
  print(jsonEncode(d.toJson()));
}
