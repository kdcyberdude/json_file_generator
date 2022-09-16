# json_file_generator

json_file_generator generates json file from static const string variables declared in .dart file.
The generated file i.e strings.json could be used by mojito.global [Translation Management System(TMS)]

## Runtime Requirements

json_file_generator generates only json file. So there is no extra runtime requirement.

## Usage

1) Add json_file_generator as a `dev_dependency`.
2) Run json_file_generator on your string resource ".dart" file to generate the required JSON file
   by running: `flutter pub get` then `flutter pub run json_file_generator --input <string_resource.dart file>` For example - `flutter pub run json_file_generator --input lib/src/localization/string_resource.dart`. This will generate strings.json file in the same directory as string_resource.dart file.

### How to define plural strings
1) Create a const `plural` object as follows -
    ```dart
    class Plural {
     const Plural();
    }

    const plural = Plural();
    ```
2) Annotate a static const string variable with `@plural` annotation.
3) This will create a nested json structure as follows -
    ```json
    {
        "{name} has {money} dollars": {
            "zero": "profileScreenMoneyCount",
            "one": "profileScreenMoneyCount",
            "many": "profileScreenMoneyCount",
            "other": "profileScreenMoneyCount"
        },
        "Did you know?": "didYouKnow"
    }
    ```

## Credits
Initial code for parsing a file is copied from pigeon package. https://pub.dev/packages/pigeon