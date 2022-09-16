import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart' show AnalysisContext;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart' show AnalysisContextCollection;
import 'package:analyzer/dart/analysis/results.dart' show ParsedUnitResult;
import 'package:analyzer/dart/analysis/session.dart' show AnalysisSession;
import 'package:analyzer/dart/ast/ast.dart' as dart_ast;
import 'package:analyzer/dart/ast/visitor.dart' as dart_ast_visitor;
import 'package:args/args.dart';
import 'package:path/path.dart' as path;


/// Options used when running the code generator.
class GeneratorOptions {
  /// Creates a instance of GeneratorOptions
  const GeneratorOptions({this.input});

  /// Path to the file which will be processed.
  final String? input;

  /// Creates a [GeneratorOptions] from a Map representation where:
  /// `x = GeneratorOptions.fromMap(x.toMap())`.
  static GeneratorOptions fromMap(Map<String, Object> map) {
    return GeneratorOptions(
      input: map['input'] as String?,
    );
  }

  /// Converts a [GeneratorOptions] to a Map representation where:
  /// `x = GeneratorOptions.fromMap(x.toMap())`.
  Map<String, Object> toMap() {
    final Map<String, Object> result = <String, Object>{
      if (input != null) 'input': input!,
    };
    return result;
  }

  /// Overrides any non-null parameters from [options] into this to make a new
  /// [GeneratorOptions].
  GeneratorOptions merge(GeneratorOptions options) {
    return GeneratorOptions.fromMap(mergeMaps(toMap(), options.toMap()));
  }
}

/// Recursively merges [modification] into [base].  In other words, whenever
/// there is a conflict over the value of a key path, [modification]'s value for
/// that key path is selected.
Map<String, Object> mergeMaps(
  Map<String, Object> base,
  Map<String, Object> modification,
) {
  final Map<String, Object> result = <String, Object>{};
  for (final MapEntry<String, Object> entry in modification.entries) {
    if (base.containsKey(entry.key)) {
      final Object entryValue = entry.value;
      if (entryValue is Map<String, Object>) {
        assert(base[entry.key] is Map<String, Object>);
        result[entry.key] = mergeMaps((base[entry.key] as Map<String, Object>?)!, entryValue);
      } else {
        result[entry.key] = entry.value;
      }
    } else {
      result[entry.key] = entry.value;
    }
  }
  for (final MapEntry<String, Object> entry in base.entries) {
    if (!result.containsKey(entry.key)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}




class _RootBuilder extends dart_ast_visitor.RecursiveAstVisitor<Object?> {
  _RootBuilder(this.source);

  final String source;
  final Map json = <String, dynamic>{};

  @override
  Object? visitFieldDeclaration(dart_ast.FieldDeclaration node) {
    if (node.isStatic) {
      if (node.isStatic && node.staticKeyword?.next?.stringValue == 'const') {
        final key = node.staticKeyword?.next?.next?.lexeme ?? '';
        var value = node.staticKeyword?.next?.next?.next?.next?.lexeme ?? '';
        final isPlural = node.staticKeyword?.previous?.lexeme == 'plural' ? true : false;
        value = value.substring(1, value.length - 1);
        if (isPlural) {
          final plural = {
            "zero": key,
            "one": key,
            "many": key,
            "other": key,
          };
          json[value] = plural;
        } else {
          json[value] = key;
        }
      }
    }
    return null;
  }
}

/// Tool for generating json file from <string_resource>.dart file.
class JsonFileGenerator {
  /// Create and setup a [JsonFileGenerator] instance.
  static JsonFileGenerator setup() {
    return JsonFileGenerator();
  }

  /// Reads the file located at [path] and check for static const string variables
  /// and convert them map and save it in json file as strings.json. File is been
  /// saved in the directory from where this command is being called
  void convertAndSaveFileAsJson(String inputPath) {
    final List<String> includedPaths = <String>[path.absolute(path.normalize(inputPath))];
    final AnalysisContextCollection collection = AnalysisContextCollection(
      includedPaths: includedPaths,
      sdkPath: null,
    );

    final _RootBuilder rootBuilder = _RootBuilder(File(inputPath).readAsStringSync());
    for (final AnalysisContext context in collection.contexts) {
      for (final String path in context.contextRoot.analyzedFiles()) {
        final AnalysisSession session = context.currentSession;
        final ParsedUnitResult result = session.getParsedUnit(path) as ParsedUnitResult;
        if (result.errors.isEmpty) {
          final dart_ast.CompilationUnit unit = result.unit;
          unit.accept(rootBuilder);
        }
      }
    }

    final myFile = File('${inputPath.substring(0, inputPath.lastIndexOf('/'))}/strings.json');
    final encoder = JsonEncoder.withIndent('  ');
    final prettyPrint = encoder.convert(rootBuilder.json);

    myFile.writeAsStringSync(prettyPrint);
  }

  /// String that describes how the tool is used.
  static String get usage {
    return '''
json_file_generator is a tool for generating json file from .dart file.
It checks for static const string variables and convert them into key-value pair in json file. Which could be used Translation Management System like mojito.global

usage: json_file_generator --input <.dart file path> *

options:
${_argParser.usage}''';
  }

  static final ArgParser _argParser = ArgParser()
    ..addOption('input', help: 'REQUIRED: Path to string_resource.dart file.');

  /// Convert command-line arguments to [GeneratorOptions].
  static GeneratorOptions parseArgs(List<String> args) {
    final ArgResults results = _argParser.parse(args);

    final GeneratorOptions opts = GeneratorOptions(
      input: results['input'],
    );
    return opts;
  }

  /// The 'main' entrypoint used by the command-line tool.  [args] are the
  /// command-line arguments. The optional parameter
  /// [sdkPath] allows you to specify the Dart SDK path.
  static Future<int> run(List<String> args) async {
    final JsonFileGenerator jsonFileGenerator = JsonFileGenerator.setup();
    GeneratorOptions options = JsonFileGenerator.parseArgs(args);

    if (options.input == null) {
      print(usage);
      return 0;
    }
    jsonFileGenerator.convertAndSaveFileAsJson(options.input!);
    return 0;
  }
}
