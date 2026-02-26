import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var file = File('.dart_tool/package_config.json');
  print(await file.readAsString());
}
