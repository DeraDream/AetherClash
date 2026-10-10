import 'package:fl_clash/common/mkcloud_firewall.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses authoritative MKCloud status response', () {
    final result = mkcloudResultOf({
      'data': {
        'mode': 'ip',
        'province': null,
        'iplist': ['42.200.173.69/32'],
        'entries': [
          {'cidr': '42.200.173.69/32', 'created_at': '2026-10-10T17:31:58Z'},
        ],
        'count': 1,
        'limit': 10,
        'provinces': [
          {'value': 'guangdong', 'label': '广东'},
        ],
      },
    });

    expect(result.mode, 'ip');
    expect(result.entries.single.cidr, '42.200.173.69/32');
    expect(result.count, 1);
    expect(result.limit, 10);
    expect(result.provinces.single.value, 'guangdong');
  });

  test('validates IPv4 only', () {
    expect(isIpv4('203.0.113.1'), isTrue);
    expect(isIpv4('203.0.113.1/32'), isFalse);
    expect(isIpv4('999.0.0.1'), isFalse);
  });
}
