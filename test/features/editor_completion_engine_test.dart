import 'package:fl_clash/features/editor/editor.dart';
import 'package:test/test.dart';

void main() {
  final engine = MihomoYamlCompletionEngine(EditorSchema.config.root);

  EditorCompletionResult? complete(List<String> lines) {
    final line = lines.length - 1;
    return engine.complete(lines, line, lines[line].length);
  }

  List<String> labels(EditorCompletionResult? result) =>
      result?.suggestions.map((item) => item.label).toList() ?? const [];

  test('completes top-level Mihomo config keys', () {
    final result = complete(['pro']);
    expect(result?.prefix, 'pro');
    expect(labels(result), contains('proxies'));
    expect(labels(result), contains('proxy-groups'));
  });

  test('offers XHTTP as a VLESS transport', () {
    final result = complete([
      'proxies:',
      '  - name: edge',
      '    type: vless',
      '    network: xh',
    ]);
    expect(result?.prefix, 'xh');
    expect(labels(result), contains('xhttp'));
  });

  test('offers XHTTP option fields and modes', () {
    final field = complete([
      'proxies:',
      '  - name: edge',
      '    type: vless',
      '    network: xhttp',
      '    xhttp-opts:',
      '      mo',
    ]);
    expect(labels(field), contains('mode'));

    final mode = complete([
      'proxies:',
      '  - name: edge',
      '    type: vless',
      '    network: xhttp',
      '    xhttp-opts:',
      '      mode: str',
    ]);
    expect(labels(mode), containsAll(['stream-up', 'stream-one']));
  });

  test('offers REALITY ML-KEM field', () {
    final result = complete([
      'proxies:',
      '  - name: edge',
      '    type: vless',
      '    reality-opts:',
      '      supp',
    ]);
    expect(labels(result), contains('support-x25519mlkem768'));
  });

  test('offers MIPS in TUN stack values', () {
    final result = complete([
      'tun:',
      '  stack: mi',
    ]);
    expect(labels(result), contains('mips'));
  });

  test('recognizes EasyTier and its fields', () {
    final type = complete([
      'proxies:',
      '  - name: mesh',
      '    type: easy',
    ]);
    expect(labels(type), contains('easytier'));

    final field = complete([
      'proxies:',
      '  - name: mesh',
      '    type: easytier',
      '    network-n',
    ]);
    expect(labels(field), contains('network-name'));
  });

  test('does not offer an already present sibling key', () {
    final result = complete([
      'tun:',
      '  enable: true',
      '  e',
    ]);
    expect(labels(result), isNot(contains('enable')));
  });
}
