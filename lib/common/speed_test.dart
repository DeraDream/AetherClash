import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const speedTestGroupName = '__AetherClash-SpeedTest__';
const speedTestListenerName = '__aetherclash-speedtest__';

int speedTestListenerPortFor(int mixedPort) {
  var port = 40000 + ((mixedPort.abs() * 37) % 8000);
  if (port == mixedPort) {
    port = port == 47999 ? 40000 : port + 1;
  }
  return port;
}

void installSpeedTestRuntimeConfig(
  Map<String, dynamic> config, {
  required int mixedPort,
}) {
  final rawGroups = config['proxy-groups'];
  final groups = rawGroups is List
      ? List<dynamic>.from(rawGroups)
      : <dynamic>[];
  groups.removeWhere(
    (item) => item is Map && item['name'] == speedTestGroupName,
  );
  groups.add(<String, dynamic>{
    'name': speedTestGroupName,
    'type': 'select',
    'proxies': <String>['DIRECT'],
    'include-all': true,
    'exclude-type': 'Reject|Compatible|Pass',
    'hidden': true,
  });
  config['proxy-groups'] = groups;

  final rawListeners = config['listeners'];
  final listeners = rawListeners is List
      ? List<dynamic>.from(rawListeners)
      : <dynamic>[];
  listeners.removeWhere(
    (item) => item is Map && item['name'] == speedTestListenerName,
  );
  listeners.add(<String, dynamic>{
    'name': speedTestListenerName,
    'type': 'mixed',
    'listen': '127.0.0.1',
    'port': speedTestListenerPortFor(mixedPort),
    'proxy': speedTestGroupName,
    'users': <dynamic>[],
    'udp': false,
  });
  config['listeners'] = listeners;
}

dynamic decodeSpeedTestJsonBody(List<int> bytes) {
  if (bytes.isEmpty) {
    throw const FormatException('Empty Speedtest response.');
  }

  List<int> payload = bytes;
  // Speedtest.net commonly serves the JS server list as gzip. HttpClient is
  // intentionally configured with autoUncompress=false for throughput
  // measurements, so decode the discovery response explicitly.
  if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
    payload = gzip.decode(bytes);
  }

  final body = utf8.decode(payload);
  return json.decode(body);
}

final class SpeedTestServer {
  const SpeedTestServer({
    required this.id,
    required this.name,
    required this.country,
    required this.sponsor,
    required this.url,
    required this.host,
    this.latencyMs,
  });

  factory SpeedTestServer.fromJson(Map<String, dynamic> json) {
    return SpeedTestServer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      sponsor: json['sponsor']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      host: json['host']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String country;
  final String sponsor;
  final String url;
  final String host;
  final int? latencyMs;

  SpeedTestServer copyWith({int? latencyMs}) {
    return SpeedTestServer(
      id: id,
      name: name,
      country: country,
      sponsor: sponsor,
      url: url,
      host: host,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  Uri get uploadUri => Uri.parse(url);

  Uri get baseUri {
    final uri = uploadUri;
    final segments = List<String>.from(uri.pathSegments);
    if (segments.isNotEmpty) {
      segments.removeLast();
    }
    return uri.replace(
      pathSegments: segments,
      query: null,
      fragment: null,
    );
  }

  Uri downloadUri(int worker, int iteration) {
    final base = baseUri;
    final path = [
      ...base.pathSegments,
      'random4000x4000.jpg',
    ].join('/');
    return base.replace(
      path: '/$path',
      queryParameters: {
        'x': '${DateTime.now().microsecondsSinceEpoch}-$worker-$iteration',
      },
    );
  }

  Uri get latencyUri {
    final base = baseUri;
    final path = [...base.pathSegments, 'latency.txt'].join('/');
    return base.replace(
      path: '/$path',
      queryParameters: {
        'x': '${DateTime.now().microsecondsSinceEpoch}',
      },
    );
  }

  String get label {
    final location = [
      if (name.isNotEmpty) name,
      if (country.isNotEmpty) country,
    ].join(', ');
    if (sponsor.isNotEmpty && location.isNotEmpty) {
      return '$sponsor · $location';
    }
    return sponsor.isNotEmpty ? sponsor : location;
  }
}

enum SpeedTestPhase { download, upload }

final class SpeedTestProgress {
  const SpeedTestProgress({
    required this.phase,
    required this.mbps,
    required this.progress,
    required this.transferredBytes,
  });

  final SpeedTestPhase phase;
  final double mbps;
  final double progress;
  final int transferredBytes;
}

final class SpeedTestResult {
  const SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
  });

  final double downloadMbps;
  final double uploadMbps;

  double get downloadMegabytesPerSecond => downloadMbps / 8;
  double get uploadMegabytesPerSecond => uploadMbps / 8;
}

final class SpeedTestEngine {
  SpeedTestEngine({required this.proxyPort});

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/154.0.0.0 Safari/537.36';

  final int proxyPort;
  final Set<HttpClient> _clients = {};
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    for (final client in _clients.toList()) {
      client.close(force: true);
    }
    _clients.clear();
  }

  HttpClient _newClient() {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6)
      ..idleTimeout = const Duration(seconds: 4)
      ..autoUncompress = false
      ..userAgent = _userAgent
      ..findProxy = (_) => 'PROXY 127.0.0.1:$proxyPort';
    _clients.add(client);
    return client;
  }

  void _disposeClient(HttpClient client) {
    _clients.remove(client);
    client.close(force: true);
  }

  Future<List<SpeedTestServer>> fetchServers({
    int limit = 20,
    int latencyCandidates = 10,
  }) async {
    _cancelled = false;
    final client = _newClient();
    try {
      final uri = Uri.https(
        'www.speedtest.net',
        '/api/js/servers',
        {
          'engine': 'js',
          'https_functional': 'true',
          'limit': '$limit',
        },
      );
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
      request.headers.set(
        HttpHeaders.refererHeader,
        'https://www.speedtest.net/',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Speedtest server list returned HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      final bytes = await response
          .fold<BytesBuilder>(
            BytesBuilder(copy: false),
            (builder, chunk) => builder..add(chunk),
          )
          .timeout(const Duration(seconds: 8));
      final decoded = decodeSpeedTestJsonBody(bytes.takeBytes());
      if (decoded is! List) {
        throw const FormatException('Invalid Speedtest server list.');
      }
      final servers = decoded
          .whereType<Map>()
          .map((item) => SpeedTestServer.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((server) =>
              server.id.isNotEmpty &&
              server.url.isNotEmpty &&
              Uri.tryParse(server.url)?.hasScheme == true)
          .take(limit)
          .toList(growable: false);
      if (servers.isEmpty) {
        return const [];
      }

      final count = math.min(latencyCandidates, servers.length);
      final measured = await Future.wait([
        for (var index = 0; index < count; index++)
          _withLatency(servers[index]),
      ]);
      final ranked = measured.where((server) => server.latencyMs != null).toList()
        ..sort((a, b) => a.latencyMs!.compareTo(b.latencyMs!));
      final timedOut = measured.where((server) => server.latencyMs == null);
      return [
        ...ranked,
        ...timedOut,
        ...servers.skip(count),
      ];
    } finally {
      _disposeClient(client);
    }
  }

  Future<SpeedTestServer> _withLatency(SpeedTestServer server) async {
    final latency = await measureServerLatency(server);
    return server.copyWith(latencyMs: latency);
  }

  Future<int?> measureServerLatency(SpeedTestServer server) async {
    if (_cancelled) return null;
    final client = _newClient();
    try {
      final samples = <int>[];
      for (var index = 0; index < 3; index++) {
        if (_cancelled) return null;
        final stopwatch = Stopwatch()..start();
        try {
          final request = await client.getUrl(
            server.latencyUri.replace(
              queryParameters: {
                'x': '${DateTime.now().microsecondsSinceEpoch}-$index',
              },
            ),
          );
          request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
          final response = await request.close().timeout(
            const Duration(seconds: 3),
          );
          await response.drain<void>().timeout(const Duration(seconds: 3));
          stopwatch.stop();
          if (response.statusCode >= 200 && response.statusCode < 400) {
            if (index > 0) {
              samples.add(stopwatch.elapsedMilliseconds);
            }
          }
        } catch (_) {
          // Ignore one failed latency sample.
        }
      }
      if (samples.isEmpty) return null;
      samples.sort();
      return samples[samples.length ~/ 2];
    } finally {
      _disposeClient(client);
    }
  }

  Future<SpeedTestResult> run({
    required SpeedTestServer server,
    required void Function(SpeedTestProgress progress) onProgress,
    Duration downloadDuration = const Duration(seconds: 15),
    Duration uploadDuration = const Duration(seconds: 15),
  }) async {
    _cancelled = false;
    final download = await _runDownload(
      server,
      duration: downloadDuration,
      onProgress: onProgress,
    );
    if (_cancelled) {
      throw const SpeedTestCancelled();
    }
    final upload = await _runUpload(
      server,
      duration: uploadDuration,
      onProgress: onProgress,
    );
    if (_cancelled) {
      throw const SpeedTestCancelled();
    }
    return SpeedTestResult(
      downloadMbps: download,
      uploadMbps: upload,
    );
  }

  Future<double> _runDownload(
    SpeedTestServer server, {
    required Duration duration,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    return _runPhase(
      phase: SpeedTestPhase.download,
      duration: duration,
      workers: 6,
      onProgress: onProgress,
      worker: (workerIndex, addBytes, isRunning) async {
        final client = _newClient();
        try {
          var iteration = 0;
          while (isRunning() && !_cancelled) {
            try {
              final request = await client.getUrl(
                server.downloadUri(workerIndex, iteration++),
              );
              request.headers.set(
                HttpHeaders.acceptEncodingHeader,
                'identity',
              );
              request.headers.set(
                HttpHeaders.cacheControlHeader,
                'no-store',
              );
              final response = await request.close().timeout(
                const Duration(seconds: 6),
              );
              if (response.statusCode < 200 ||
                  response.statusCode >= 400) {
                await response.drain<void>();
                continue;
              }
              await for (final chunk in response.timeout(
                const Duration(seconds: 6),
              )) {
                addBytes(chunk.length);
                if (!isRunning() || _cancelled) {
                  break;
                }
              }
            } catch (_) {
              if (_cancelled) break;
            }
          }
        } finally {
          _disposeClient(client);
        }
      },
    );
  }

  Future<double> _runUpload(
    SpeedTestServer server, {
    required Duration duration,
    required void Function(SpeedTestProgress progress) onProgress,
  }) async {
    final payload = _buildUploadPayload(999490);
    return _runPhase(
      phase: SpeedTestPhase.upload,
      duration: duration,
      workers: 4,
      onProgress: onProgress,
      worker: (workerIndex, addBytes, isRunning) async {
        final client = _newClient();
        try {
          while (isRunning() && !_cancelled) {
            try {
              final request = await client.postUrl(server.uploadUri);
              request.headers.set(
                HttpHeaders.contentTypeHeader,
                'application/octet-stream',
              );
              request.contentLength = payload.length;
              const piece = 64 * 1024;
              var offset = 0;
              while (offset < payload.length) {
                final end = math.min(offset + piece, payload.length);
                request.add(payload.sublist(offset, end));
                await request.flush();
                addBytes(end - offset);
                offset = end;
              }
              final response = await request.close().timeout(
                const Duration(seconds: 8),
              );
              await response.drain<void>().timeout(
                const Duration(seconds: 4),
              );
              if (response.statusCode < 200 ||
                  response.statusCode >= 400) {
                continue;
              }
            } catch (_) {
              if (_cancelled) break;
            }
          }
        } finally {
          _disposeClient(client);
        }
      },
    );
  }

  Future<double> _runPhase({
    required SpeedTestPhase phase,
    required Duration duration,
    required int workers,
    required void Function(SpeedTestProgress progress) onProgress,
    required Future<void> Function(
      int workerIndex,
      void Function(int bytes) addBytes,
      bool Function() isRunning,
    ) worker,
  }) async {
    var transferred = 0;
    var lastTransferred = 0;
    var liveMbps = 0.0;
    final stopwatch = Stopwatch()..start();
    var lastTick = Duration.zero;
    final samples = <double>[];

    bool isRunning() => !_cancelled && stopwatch.elapsed < duration;
    void addBytes(int bytes) {
      transferred += bytes;
    }

    final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final elapsed = stopwatch.elapsed;
      final deltaTime = elapsed - lastTick;
      final deltaBytes = transferred - lastTransferred;
      if (deltaTime.inMicroseconds > 0) {
        final instantMbps =
            deltaBytes * 8 / (deltaTime.inMicroseconds / 1000000) / 1000000;
        liveMbps = liveMbps == 0
            ? instantMbps
            : liveMbps * 0.65 + instantMbps * 0.35;
        if (elapsed > const Duration(seconds: 2) && liveMbps > 0) {
          samples.add(liveMbps);
        }
      }
      lastTransferred = transferred;
      lastTick = elapsed;
      onProgress(
        SpeedTestProgress(
          phase: phase,
          mbps: liveMbps,
          progress: (elapsed.inMilliseconds / duration.inMilliseconds)
              .clamp(0, 1)
              .toDouble(),
          transferredBytes: transferred,
        ),
      );
    });

    try {
      await Future.wait([
        for (var index = 0; index < workers; index++)
          worker(index, addBytes, isRunning),
      ]);
    } finally {
      timer.cancel();
      stopwatch.stop();
    }

    if (_cancelled) {
      throw const SpeedTestCancelled();
    }
    if (transferred <= 0) {
      throw const HttpException('No Speedtest data was transferred.');
    }
    if (samples.isEmpty) {
      final seconds = math.max(
        stopwatch.elapsedMicroseconds / 1000000.0,
        0.001,
      );
      return transferred * 8 / seconds / 1000000;
    }
    samples.sort();
    // A trimmed high-percentile estimate is closer to Speedtest-style
    // sustained throughput than including TCP/TLS ramp-up time.
    final start = (samples.length * 0.35).floor();
    final stable = samples.skip(start).toList();
    return stable.reduce((a, b) => a + b) / stable.length;
  }

  Uint8List _buildUploadPayload(int length) {
    final data = Uint8List(length);
    var value = 0x13579BDF;
    for (var index = 0; index < data.length; index++) {
      value ^= (value << 13) & 0x7fffffff;
      value ^= value >> 17;
      value ^= (value << 5) & 0x7fffffff;
      data[index] = value & 0xff;
    }
    return data;
  }
}

final class SpeedTestCancelled implements Exception {
  const SpeedTestCancelled();

  @override
  String toString() => 'Speed test cancelled';
}
