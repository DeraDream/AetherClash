import 'package:fl_clash/features/editor/editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  group('Mihomo v1.19.32 editor schema', () {
    final config = EditorSchema.config.root;
    final proxy = config.fields['proxies']!.entry!;

    test('exposes XHTTP transport and options for VLESS', () {
      final vless = proxy.fieldsFor('vless');

      expect(vless['network']!.values, contains('xhttp'));
      expect(
        vless['xhttp-opts']!.fields.keys,
        containsAll(['path', 'host', 'mode', 'headers']),
      );
      expect(
        vless['xhttp-opts']!.fields['mode']!.values,
        containsAll(['auto', 'packet-up', 'stream-up', 'stream-one']),
      );
    });

    test('exposes REALITY ML-KEM option', () {
      final vless = proxy.fieldsFor('vless');
      final reality = vless['reality-opts']!;

      expect(reality.fields, contains('support-x25519mlkem768'));
      expect(
        reality.fields['support-x25519mlkem768']!.values,
        containsAll(['true', 'false']),
      );
    });

    test('offers MIPS as the first TUN stack', () {
      final stack = config.fields['tun']!.fields['stack']!;

      expect(stack.values.first, 'mips');
      expect(stack.values, containsAll(['mips', 'mixed', 'system', 'gvisor']));
    });

    test('recognizes EasyTier and its v1.19.32 fields', () {
      expect(proxy.fields['type']!.values, contains('easytier'));
      final easyTier = proxy.fieldsFor('easytier');

      expect(
        easyTier.keys,
        containsAll([
          'network-name',
          'network-secret',
          'hostname',
          'peers',
          'listeners',
          'accept-dns',
          'enable-exit-node',
          'enable-encryption',
          'disable-p2p',
          'enable-quic-proxy',
          'tld-dns-zone',
        ]),
      );
    });
  });
  group('Mihomo YAML completion', () {
    Future<CodeAutocompleteEditingValue?> complete(
      WidgetTester tester,
      String source,
    ) async {
      final caret = source.indexOf('|');
      expect(caret, isNonNegative);
      final text = source.replaceFirst('|', '');
      final before = source.substring(0, caret);
      final line = '\n'.allMatches(before).length;
      final lineStart = before.lastIndexOf('\n') + 1;
      final column = caret - lineStart;
      final controller = CodeLineEditingController.fromText(text);
      addTearDown(controller.dispose);

      late BuildContext context;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );

      final selection = CodeLineSelection.collapsed(
        index: line,
        offset: column,
      );
      return ClashYamlAutocompleteBuilder(
        controller,
        EditorSchema.config.root,
      ).build(context, controller.codeLines[line], selection);
    }

    testWidgets('completes XHTTP for a VLESS network', (tester) async {
      final completion = await complete(
        tester,
        'proxies:\n'
        '  - name: demo\n'
        '    type: vless\n'
        '    network: xh|',
      );

      expect(
        completion!.prompts.map((prompt) => prompt.word),
        contains('xhttp'),
      );
    });

    testWidgets('completes the REALITY ML-KEM field', (tester) async {
      final completion = await complete(
        tester,
        'proxies:\n'
        '  - name: demo\n'
        '    type: vless\n'
        '    reality-opts:\n'
        '      support-x|',
      );

      expect(
        completion!.prompts.map((prompt) => prompt.word),
        contains('support-x25519mlkem768'),
      );
    });

    testWidgets('completes MIPS for the TUN stack', (tester) async {
      final completion = await complete(tester, 'tun:\n  stack: m|');

      expect(
        completion!.prompts.map((prompt) => prompt.word),
        contains('mips'),
      );
    });

    testWidgets('completes EasyTier-specific fields', (tester) async {
      final completion = await complete(
        tester,
        'proxies:\n'
        '  - name: mesh\n'
        '    type: easytier\n'
        '    network-|',
      );

      expect(
        completion!.prompts.map((prompt) => prompt.word),
        containsAll(['network-name', 'network-secret']),
      );
    });
  });

}
