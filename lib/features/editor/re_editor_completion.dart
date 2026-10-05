import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'clash_schema.dart';
import 'completion_engine.dart';

class MihomoYamlAutocompletePromptsBuilder
    implements CodeAutocompletePromptsBuilder {
  final CodeLineEditingController controller;
  final MihomoYamlCompletionEngine engine;

  MihomoYamlAutocompletePromptsBuilder({
    required this.controller,
    required EditorSchema schema,
  }) : engine = MihomoYamlCompletionEngine(schema.root);

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    if (!selection.isCollapsed) {
      return null;
    }
    final lines = controller.codeLines
        .toList()
        .map((line) => line.text)
        .toList();
    final completion = engine.complete(
      lines,
      selection.extentIndex,
      selection.extentOffset,
    );
    if (completion == null || completion.suggestions.isEmpty) {
      return null;
    }
    return CodeAutocompleteEditingValue(
      input: completion.prefix,
      prompts: [
        for (final suggestion in completion.suggestions)
          MihomoCodePrompt(suggestion),
      ],
      index: 0,
    );
  }
}

class MihomoCodePrompt extends CodePrompt {
  final EditorSuggestion suggestion;

  MihomoCodePrompt(this.suggestion) : super(word: suggestion.label);

  String get detail => suggestion.detail;

  @override
  CodeAutocompleteResult get autocomplete => CodeAutocompleteResult(
    input: '',
    word: suggestion.insertText,
    selection: TextSelection.collapsed(offset: suggestion.insertText.length),
  );

  @override
  bool match(String input) => true;
}
