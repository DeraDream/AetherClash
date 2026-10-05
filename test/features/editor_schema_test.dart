import 'package:fl_clash/features/editor/editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mihomo v1.19.32 editor schema', () {
    final config = EditorSchema.config.root;
    final proxy = config.fields['proxies']!.entry!;

    test('exposes XHTTP transport and options for VLESS', () {
      final vless = proxy.fieldsFor('vless');

      expect(vless['network']!.values, contains('xhttp'));
      expect(vless['xhttp-opts']!.fields.keys, containsAll([
        'path',
        'host',
        'mode',
        'headers',
      ]));
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
}
