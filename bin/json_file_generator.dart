import 'dart:io' show exit;

import 'package:json_file_generator/src/json_file_generator_lib.dart';

Future<void> main(List<String> args) async {
  exit(await JsonFileGenerator.run(args));
}
