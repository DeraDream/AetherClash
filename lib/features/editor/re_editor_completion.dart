import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';

import 'clash_schema.dart';
import 'yaml_lines.dart';

final _caretLinePattern = RegExp(r'^( *)(-(?: +|$))?(.*)$');
final _keyTypedPattern = RegExp(r'^[\w.-]*$');
final _valueTypedPattern = RegExp(
  r'''^('[^']*'|"[^"]*"|[^\s#'"{\[][^#]*?):\s+(.*)$''',
);

/// Mihomo-aware YAML completion for the existing re_editor based editor.
///
/// This intentionally reuses AetherClash's current editor instead of replacing
/// it with FlClash's newer CodeForge stack. That keeps search, context menus,
/// import and save behavior unchanged while still gaining schema completions.
class ClashYamlAutocompleteBuilder implements CodeAutocompletePromptsBuilder {
  ClashYamlAutocompleteBuilder(this.controller, this.root);

  final CodeLineEditingController controller;
  final YamlSchema root;

  @override
  CodeAutocompleteEditingValue? build(
    BuildContext context,
    CodeLine codeLine,
    CodeLineSelection selection,
  ) {
    if (!selection.isCollapsed ||
        selection.extentIndex < 0 ||
        selection.extentOffset < 0 ||
        selection.extentOffset > codeLine.text.length) {
      return null;
    }

    final before = codeLine.text.substring(0, selection.extentOffset);
    if (before.trimLeft().startsWith('#') || before.contains(' #')) {
      return null;
    }

    final match = _caretLinePattern.firstMatch(before);
    if (match == null) {
      return null;
    }
    final indent = match[1]!.length;
    final dash = match[2];
    final startsItem = dash != null;
    final typed = match[3]!;
    final column = indent + (dash?.length ?? 0);

    final document = YamlDocumentLines(
      controller.codeLines.toList().map((line) => line.text).toList(),
    );
    final scope = document.mappingScope(
      selection.extentIndex,
      column,
      startsItem: startsItem,
      itemIndent: indent,
    );
    final node = scope == null ? null : _resolve(scope.path);
    if (node == null) {
      return null;
    }

    if (node.kind == YamlKind.scalar) {
      return _scalarItem(node, typed, document.lines);
    }
    if (node.kind != YamlKind.map) {
      return null;
    }

    final fields = node.fieldsFor(scope!.siblings['type']);
    final valueMatch = _valueTypedPattern.firstMatch(typed);
    if (valueMatch != null) {
      final key = unquoteYaml(valueMatch[1]!);
      final value = fields[key] ?? node.entry;
      if (value == null) {
        return null;
      }
      return _value(value, valueMatch[2]!, document.lines);
    }

    if (typed.isEmpty || !_keyTypedPattern.hasMatch(typed)) {
      return null;
    }

    final extraIndent = startsItem ? ' ' * (column - indent) : '';
    final prompts = <CodePrompt>[
      for (final entry in fields.entries)
        if (!scope.siblings.containsKey(entry.key) &&
            _matches(entry.key, typed))
          CodeFieldPrompt(
            word: entry.key,
            type: entry.value.hint,
            customAutocomplete: CodeAutocompleteResult.fromWord(
              _keyBody(entry.key, entry.value, extraIndent),
            ),
          ),
    ];
    return _result(typed, prompts);
  }

  YamlSchema? _resolve(List<YamlStep> path) {
    YamlSchema? node = root;
    for (final step in path) {
      node = switch ((node, step)) {
        (final YamlSchema map, YamlKeyStep(:final key))
            when map.kind == YamlKind.map =>
          map.fieldsFor(null)[key] ?? map.entry,
        (final YamlSchema list, YamlItemStep())
            when list.kind == YamlKind.list =>
          list.entry,
        _ => null,
      };
      if (node == null) {
        return null;
      }
    }
    return node;
  }

  String _keyBody(String key, YamlSchema value, String extraIndent) {
    return switch (value.kind) {
      YamlKind.scalar => '$key: ',
      YamlKind.map => '$key:\n$extraIndent  ',
      YamlKind.list => '$key:\n$extraIndent  - ',
    };
  }

  CodeAutocompleteEditingValue? _value(
    YamlSchema schema,
    String typed,
    List<String> lines,
  ) {
    var text = typed;
    if (text.startsWith('[')) {
      final entry = schema.entry;
      if (schema.kind != YamlKind.list || entry == null) {
        return null;
      }
      final separator = text.lastIndexOf(RegExp(r'[\[,]'));
      text = text.substring(separator + 1).trimLeft();
      return _scalar(entry, text, lines);
    }
    if (schema.kind != YamlKind.scalar) {
      return null;
    }
    if (text.startsWith("'") || text.startsWith('"')) {
      text = text.substring(1);
    }
    return _scalar(schema, text, lines);
  }

  CodeAutocompleteEditingValue? _scalarItem(
    YamlSchema item,
    String typed,
    List<String> lines,
  ) {
    return switch (item.scalar) {
      YamlScalar.rule => _rule(typed, lines, withPolicy: true),
      YamlScalar.rulePayload => _rule(typed, lines, withPolicy: false),
      _ => _scalar(item, typed, lines),
    };
  }

  CodeAutocompleteEditingValue? _scalar(
    YamlSchema schema,
    String typed,
    List<String> lines,
  ) {
    if (typed.isEmpty) {
      return null;
    }
    final names = _DocumentNames(lines);
    final values = switch (schema.scalar) {
      YamlScalar.policy => [
        ...names.groups.keys,
        ...names.proxies.keys,
        ...builtinPolicies,
        'COMPATIBLE',
      ],
      YamlScalar.proxyProvider => names.proxyProviders,
      YamlScalar.ruleProvider => names.ruleProviders,
      YamlScalar.subRule => names.subRules,
      _ => schema.values,
    };
    final prompts = [
      for (final value in values)
        if (_matches(value, typed)) CodeKeywordPrompt(word: value),
    ];
    return _result(typed, prompts);
  }

  CodeAutocompleteEditingValue? _rule(
    String typed,
    List<String> lines, {
    required bool withPolicy,
  }) {
    final names = _DocumentNames(lines);
    final parts = typed.split(',');
    final text = parts.last.trimLeft();
    final type = parts.first.trim().toUpperCase();

    Iterable<String> values;
    switch (parts.length) {
      case 1:
        values = ruleTypes.keys.where(
          (value) => withPolicy || !const {'MATCH', 'SUB-RULE'}.contains(value),
        );
      case 2 when type == 'MATCH':
        values = withPolicy ? _policies(names) : const [];
      case 2:
        values = type == 'RULE-SET'
            ? names.ruleProviders
            : (rulePayloadValues[type] ?? const []);
      case 3 when withPolicy:
        values = _policies(names);
      case 3 || 4 when noResolveRuleTypes.contains(type):
        values = ruleOptions;
      default:
        values = const [];
    }

    final prompts = [
      for (final value in values)
        if (_matches(value, text)) CodeKeywordPrompt(word: value),
    ];
    return _result(text, prompts);
  }

  Iterable<String> _policies(_DocumentNames names) sync* {
    yield* names.groups.keys;
    yield* names.proxies.keys;
    yield* builtinPolicies;
  }

  CodeAutocompleteEditingValue? _result(
    String input,
    List<CodePrompt> prompts,
  ) {
    if (prompts.isEmpty) {
      return null;
    }
    return CodeAutocompleteEditingValue(
      input: input,
      prompts: prompts,
      index: 0,
    );
  }

  bool _matches(String value, String input) =>
      value != input && value.toLowerCase().startsWith(input.toLowerCase());
}

class _DocumentNames {
  static const _namingSections = {
    'proxies',
    'proxy-groups',
    'proxy-providers',
    'rule-providers',
    'sub-rules',
  };

  final groups = <String, String>{};
  final proxies = <String, String>{};
  final proxyProviders = <String>[];
  final ruleProviders = <String>[];
  final subRules = <String>[];

  _DocumentNames(List<String> lines) {
    String? section;
    int? childIndent;
    _Item? item;

    void flush() {
      final name = item?.name;
      if (name != null && name.isNotEmpty) {
        final target = section == 'proxy-groups' ? groups : proxies;
        target.putIfAbsent(name, () => item!.type ?? '');
      }
      item = null;
    }

    for (final text in lines) {
      final line = YamlLine.parse(text);
      if (line == null) {
        continue;
      }
      if (line.indent == 0 && !line.isItem) {
        flush();
        section = line.key;
        childIndent = null;
        continue;
      }
      if (!_namingSections.contains(section)) {
        continue;
      }
      switch (section) {
        case 'proxies' || 'proxy-groups':
          if (line.isItem && line.indent == (childIndent ??= line.indent)) {
            flush();
            item = _Item(line.contentColumn);
            if (line.content.startsWith('{')) {
              item!.readFlow(line.content);
              flush();
              continue;
            }
          }
          final current = item;
          if (current != null && line.contentColumn == current.column) {
            switch (line.key) {
              case 'name':
                current.name = line.value;
              case 'type':
                current.type = line.value;
            }
          }
        case 'proxy-providers' || 'rule-providers' || 'sub-rules':
          if (!line.isItem &&
              line.key != null &&
              line.indent == (childIndent ??= line.indent)) {
            final names = switch (section) {
              'proxy-providers' => proxyProviders,
              'rule-providers' => ruleProviders,
              _ => subRules,
            };
            names.add(line.key!);
          }
      }
    }
    flush();
  }
}

class _Item {
  _Item(this.column);

  final int column;
  String? name;
  String? type;

  static final _flowField = RegExp(
    r'''(?:^|[{,])\s*(name|type)\s*:\s*('[^']*'|"[^"]*"|[^,}]*)''',
  );

  void readFlow(String content) {
    for (final match in _flowField.allMatches(content)) {
      final value = unquoteYaml(match[2]!);
      if (match[1] == 'name') {
        name = value;
      } else {
        type = value;
      }
    }
  }
}
