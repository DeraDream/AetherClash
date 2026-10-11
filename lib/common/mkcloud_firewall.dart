import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/models/mkcloud_firewall.dart';

const mkcloudApiHost = 'www.mkcloud.net';
const mkcloudExitHosts = ['api.ipify.org', 'api4.ipify.org'];
const mkcloudExitUris = [
  'https://api.ipify.org?format=json',
  'https://api4.ipify.org?format=json',
];
const mkcloudApiUri =
    'https://$mkcloudApiHost/index.php?m=provincewhitelist&hosting_id=3438';

bool isIpv4(String value) => RegExp(
  r'^(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\.(?:25[0-5]|2[0-4]\d|1?\d?\d)){3}$',
).hasMatch(value);

Future<List<String>> resolveMkcloudDirectCidrs() async {
  final apiAddresses = <String>{};
  final exitAddresses = <String>{};
  for (final host in [mkcloudApiHost, ...mkcloudExitHosts]) {
    try {
      final resolved = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv4,
      ).timeout(const Duration(seconds: 8));
      final addresses = resolved.map((it) => '${it.address}/32');
      if (host == mkcloudApiHost) {
        apiAddresses.addAll(addresses);
      } else {
        exitAddresses.addAll(addresses);
      }
    } catch (_) {}
  }
  if (apiAddresses.isEmpty || exitAddresses.isEmpty) {
    throw HttpException(
      'Unable to resolve the MKCloud or exit IP service',
      uri: Uri.parse(mkcloudApiUri),
    );
  }
  return {...apiAddresses, ...exitAddresses}.toList(growable: false);
}

class MkcloudDirectTransport {
  HttpClient? _client;

  HttpClient get _http => _client ??= (HttpClient()
    ..findProxy = ((_) => 'DIRECT')
    ..connectionTimeout = const Duration(seconds: 8)
    ..idleTimeout = const Duration(seconds: 30));

  Future<Map<String, Object?>> post(
    Uri uri, {
    required String apiKey,
    required Map<String, Object?> body,
  }) async {
    final request = await _http
        .postUrl(uri)
        .timeout(const Duration(seconds: 12));
    request.headers.contentType = ContentType.json;
    request.headers.set('X-API-Key', apiKey);
    request.write(jsonEncode(body));
    final response = await request.close().timeout(const Duration(seconds: 12));
    final raw = await response.transform(utf8.decoder).join();
    final value = jsonDecode(raw);
    if (value is! Map) {
      throw const HttpException('Invalid MKCloud response');
    }
    final result = Map<String, Object?>.from(value);
    if (response.statusCode != HttpStatus.ok || result['code'] != 0) {
      throw HttpException('${result['msg'] ?? 'MKCloud request failed'}');
    }
    return result;
  }

  Future<String> currentIp() async {
    Object? lastError;
    for (final value in mkcloudExitUris) {
      try {
        final request = await _http
            .getUrl(Uri.parse(value))
            .timeout(const Duration(seconds: 12));
        final response = await request.close().timeout(
          const Duration(seconds: 12),
        );
        final raw = await response.transform(utf8.decoder).join();
        final body = jsonDecode(raw);
        final ip = body is Map ? body['ip']?.toString() : null;
        if (response.statusCode == HttpStatus.ok && ip != null && isIpv4(ip)) {
          return ip;
        }
        lastError = const HttpException('Invalid exit IP response');
      } catch (error) {
        lastError = error;
      }
    }
    throw HttpException(
      'Unable to determine the direct IPv4 exit${lastError == null ? '' : ': $lastError'}',
    );
  }

  void reset() {
    _client?.close(force: true);
    _client = null;
  }
}

MkcloudResult mkcloudResultOf(
  Map<String, Object?> response, {
  String? currentIp,
}) {
  final raw = response['data'];
  if (raw is! Map) {
    throw const FormatException('MKCloud response is missing data');
  }
  final data = Map<String, Object?>.from(raw);
  final entries = data['entries'] is List
      ? (data['entries'] as List)
            .whereType<Map>()
            .map((item) {
              final entry = Map<String, Object?>.from(item);
              return MkcloudWhitelistEntry(
                cidr: entry['cidr']?.toString() ?? '',
                createdAt: DateTime.tryParse(
                  entry['created_at']?.toString() ?? '',
                ),
              );
            })
            .where((it) => it.cidr.isNotEmpty)
            .toList()
      : <MkcloudWhitelistEntry>[];
  final provinces = data['provinces'] is List
      ? (data['provinces'] as List)
            .whereType<Map>()
            .map((item) {
              final province = Map<String, Object?>.from(item);
              return MkcloudProvince(
                value: province['value']?.toString() ?? '',
                label: province['label']?.toString() ?? '',
              );
            })
            .where((it) => it.value.isNotEmpty)
            .toList()
      : <MkcloudProvince>[];
  return MkcloudResult(
    type: MkcloudResultType.notApplied,
    mode: data['mode']?.toString(),
    province: data['province']?.toString(),
    currentIp: currentIp,
    entries: entries,
    count: int.tryParse('${data['count']}') ?? entries.length,
    limit: int.tryParse('${data['limit']}') ?? 10,
    provinces: provinces,
  );
}
