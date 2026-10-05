import 'clash_schema.dart';
import 'yaml_lines.dart';

final _caretLinePattern = RegExp(r'^( *)(-(?: +|$))?(.*)$');
final _keyTypedPattern = RegExp(r'^[\w.-]*$');
final _valueTypedPattern = RegExp(
  r'''^('[^']*'|"[^"]*"|[^\s#'"{\[][^#]*?):\s+(.*)$''',
);

class EditorSuggestion {
  final String label;
  final String detail;
  final String insertText;

  const EditorSuggestion({
    required this.label,
    required this.insertText,
    this.detail = '',
  });
}

class EditorCompletionResult {
  final String prefix;
  final List<EditorSuggestion> suggestions;

  const EditorCompletionResult({
    required this.prefix,
    required this.suggestions,
  });
}

class MihomoYamlCompletionEngine {
  final YamlSchema root;

  const MihomoYamlCompletionEngine(this.root);

  EditorCompletionResult? complete(List<String> lines, int line, int column) {
    if (line < 0 || line >= lines.length) {
      return null;
    }
    final lineText = lines[line];
    final safeColumn = column < 0
        ? 0
        : column > lineText.length
        ? lineText.length
        : column;
    final before = lineText.substring(0, safeColumn);
    if (before.contains(' #') || before.trimLeft().startsWith('#')) {
      return null;
    }

    final match = _caretLinePattern.firstMatch(before);
    if (match == null) {
      return null;
    }
    final indent = match[1]!.length;
    final startsItem = match[2] != null;
    final typed = match[3]!;
    final contentColumn = indent + (match[2]?.length ?? 0);
    final document = YamlDocumentLines(lines);
    final scope = document.mappingScope(
      line,
      contentColumn,
      startsItem: startsItem,
      itemIndent: indent,
    );
    final node = scope == null ? null : _resolve(scope.path);
    if (node == null) {
      return null;
    }

    final names = _DocumentNames(lines);
    if (node.kind == YamlKind.scalar) {
      return _scalarItem(node, typed, names);
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
      return _value(value, valueMatch[2]!, names);
    }

    if (typed.isNotEmpty && !_keyTypedPattern.hasMatch(typed)) {
      return null;
    }
    final candidates = <EditorSuggestion>[
      for (final entry in fields.entries)
        if (!scope.siblings.containsKey(entry.key))
          EditorSuggestion(
            label: entry.key,
            detail: entry.value.hint,
            insertText: '\${entry.key}: ',
          ),
    ];
    return _ranked(typed, candidates);
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

  EditorCompletionResult? _value(
    YamlSchema schema,
    String typed,
    _DocumentNames names,
  ) {
    var text = typed;
    if (text.startsWith('[')) {
      final entry = schema.entry;
      if (schema.kind != YamlKind.list || entry == null) {
        return null;
      }
      final split = text.lastIndexOf(RegExp(r'[\[,]'));
      text = text.substring(split + 1).trimLeft();
      return _scalar(entry, text, names);
    }
    if (schema.kind != YamlKind.scalar) {
      return null;
    }
    if (text.startsWith("'") || text.startsWith('"')) {
      text = text.substring(1);
    }
    return _scalar(schema, text, names);
  }

  EditorCompletionResult? _scalarItem(
    YamlSchema schema,
    String typed,
    _DocumentNames names,
  ) {
    return switch (schema.scalar) {
      YamlScalar.rule => _rule(typed, names, withPolicy: true),
      YamlScalar.rulePayload => _rule(typed, names, withPolicy: false),
      _ => _scalar(schema, typed, names),
    };
  }

  EditorCompletionResult? _scalar(
    YamlSchema schema,
    String typed,
    _DocumentNames names,
  ) {
    final labels = switch (schema.scalar) {
      YamlScalar.policy => names.policies(includeCompatible: true),
      YamlScalar.proxyProvider => names.proxyProviders,
      YamlScalar.ruleProvider => names.ruleProviders,
      YamlScalar.subRule => names.subRules,
      _ => schema.values,
    };
    if (labels.isEmpty) {
      return null;
    }
    return _ranked(
      typed,
      labels.map((value) => EditorSuggestion(label: value, insertText: value)),
    );
  }

  EditorCompletionResult? _rule(
    String typed,
    _DocumentNames names, {
    required bool withPolicy,
  }) {
    final parts = typed.split(',');
    final current = parts.last.trimLeft();
    final type = parts.first.trim().toUpperCase();

    if (parts.length == 1) {
      return _ranked(current, [
        for (final entry in ruleTypes.entries)
          if (withPolicy || !const {'MATCH', 'SUB-RULE'}.contains(entry.key))
            EditorSuggestion(
              label: entry.key,
              detail: entry.value,
              insertText: '\${entry.key},',
            ),
      ]);
    }
    if (parts.length == 2 && type == 'MATCH' && withPolicy) {
      return _ranked(
        current,
        names.policies().map(
          (value) => EditorSuggestion(label: value, insertText: value),
        ),
      );
    }
    if (parts.length == 2) {
      final values = switch (type) {
        'RULE-SET' => names.ruleProviders,
        _ => rulePayloadValues[type] ?? const <String>[],
      };
      return _ranked(
        current,
        values.map(
          (value) => EditorSuggestion(label: value, insertText: value),
        ),
      );
    }
    if (parts.length == 3 && withPolicy) {
      return _ranked(
        current,
        names.policies().map(
          (value) => EditorSuggestion(label: value, insertText: value),
        ),
      );
    }
    if ((parts.length == 3 || parts.length == 4) &&
        noResolveRuleTypes.contains(type)) {
      return _ranked(
        current,
        ruleOptions.map(
          (value) => EditorSuggestion(label: value, insertText: value),
        ),
      );
    }
    return null;
  }
}

EditorCompletionResult? _ranked(
  String typed,
  Iterable<EditorSuggestion> candidates,
) {
  final seen = <String>{};
  final ranked = <(int, int, EditorSuggestion)>[];
  var order = 0;
  for (final candidate in candidates) {
    if (!seen.add(candidate.label)) {
      continue;
    }
    final score = _completionScore(candidate.label, typed);
    if (score != null && candidate.label != typed) {
      ranked.add((score, order++, candidate));
    }
  }
  ranked.sort((a, b) {
    final score = b.$1.compareTo(a.$1);
    return score != 0 ? score : a.$2.compareTo(b.$2);
  });
  final suggestions = [
    for (final (_, _, suggestion) in ranked.take(60)) suggestion,
  ];
  if (suggestions.isEmpty) {
    return null;
  }
  return EditorCompletionResult(prefix: typed, suggestions: suggestions);
}

int? _completionScore(String candidate, String typed) {
  if (typed.isEmpty) {
    return 0;
  }
  final lower = candidate.toLowerCase();
  final input = typed.toLowerCase();
  if (lower.startsWith(input)) {
    return 3000 - candidate.length + (candidate.startsWith(typed) ? 100 : 0);
  }
  for (var index = 1; index < candidate.length; index++) {
    if (_startsSegment(candidate, index) && lower.startsWith(input, index)) {
      return 2000 - index - candidate.length;
    }
  }
  if (lower.isEmpty || input.isEmpty || lower[0] != input[0]) {
    return null;
  }
  var matched = 1;
  for (var index = 1; index < lower.length && matched < input.length; index++) {
    if (lower[index] == input[matched]) {
      matched++;
    }
  }
  return matched == input.length ? 1000 - candidate.length : null;
}

bool _startsSegment(String text, int index) {
  final previous = text[index - 1];
  if (previous == '-' || previous == '_' || previous == '.') {
    return true;
  }
  final current = text[index];
  return previous.toLowerCase() == previous &&
      previous.toUpperCase() != previous &&
      current.toUpperCase() == current &&
      current.toLowerCase() != current;
}

class _DocumentNames {
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
      final parsed = YamlLine.parse(text);
      if (parsed == null) {
        continue;
      }
      if (parsed.indent == 0 && !parsed.isItem) {
        flush();
        section = parsed.key;
        childIndent = null;
        continue;
      }
      switch (section) {
        case 'proxies' || 'proxy-groups':
          if (parsed.isItem &&
              parsed.indent == (childIndent ??= parsed.indent)) {
            flush();
            item = _Item(parsed.contentColumn);
            if (parsed.content.startsWith('{')) {
              item!.readFlow(parsed.content);
              flush();
              continue;
            }
          }
          final current = item;
          if (current != null && parsed.contentColumn == current.column) {
            switch (parsed.key) {
              case 'name':
                current.name = parsed.value;
              case 'type':
                current.type = parsed.value;
            }
          }
        case 'proxy-providers' || 'rule-providers' || 'sub-rules':
          if (!parsed.isItem &&
              parsed.key != null &&
              parsed.indent == (childIndent ??= parsed.indent)) {
            switch (section) {
              case 'proxy-providers':
                proxyProviders.add(parsed.key!);
              case 'rule-providers':
                ruleProviders.add(parsed.key!);
              case 'sub-rules':
                subRules.add(parsed.key!);
            }
          }
      }
    }
    flush();
  }

  List<String> policies({bool includeCompatible = false}) => [
    ...groups.keys,
    ...proxies.keys,
    ...builtinPolicies,
    if (includeCompatible) 'COMPATIBLE',
  ];
}

class _Item {
  final int column;
  String? name;
  String? type;

  _Item(this.column);

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
