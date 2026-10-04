import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/models/models.dart';
import 'package:path/path.dart' as path;

import 'path.dart';

const _updateRecoveryFormatVersion = 1;
const _updateRecoveryFileName = 'update-recovery.json';
const _updateRecoveryMaxAge = Duration(minutes: 30);

typedef UpdateRecoveryPathResolver = Future<String> Function();

final class UpdateRecoveryState {
  const UpdateRecoveryState({
    required this.running,
    required this.systemProxy,
    required this.tun,
    required this.createdAt,
  });

  factory UpdateRecoveryState.now({
    required bool running,
    required bool systemProxy,
    required bool tun,
    DateTime? now,
  }) {
    return UpdateRecoveryState(
      running: running,
      systemProxy: systemProxy,
      tun: tun,
      createdAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  factory UpdateRecoveryState.fromJson(Map<String, dynamic> json) {
    if (json['version'] != _updateRecoveryFormatVersion) {
      throw const FormatException('Unsupported update recovery version.');
    }
    final createdAtMs = json['createdAt'] as int?;
    final running = json['running'] as bool?;
    final systemProxy = json['systemProxy'] as bool?;
    final tun = json['tun'] as bool?;
    if (createdAtMs == null ||
        running == null ||
        systemProxy == null ||
        tun == null) {
      throw const FormatException('Invalid update recovery payload.');
    }
    return UpdateRecoveryState(
      running: running,
      systemProxy: systemProxy,
      tun: tun,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAtMs,
        isUtc: true,
      ),
    );
  }

  final bool running;
  final bool systemProxy;
  final bool tun;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'version': _updateRecoveryFormatVersion,
    'running': running,
    'systemProxy': systemProxy,
    'tun': tun,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
  };

  bool isFresh(DateTime now) {
    final age = now.toUtc().difference(createdAt.toUtc());
    return !age.isNegative && age <= _updateRecoveryMaxAge;
  }
}

Config applyUpdateRecoveryState(Config config, UpdateRecoveryState state) {
  return config.copyWith(
    networkProps: config.networkProps.copyWith(
      systemProxy: state.systemProxy,
    ),
    patchClashConfig: config.patchClashConfig.copyWith.tun(
      enable: state.tun,
    ),
  );
}

final class UpdateRecoveryStore {
  UpdateRecoveryStore({UpdateRecoveryPathResolver? homeDirectory})
    : _homeDirectory = homeDirectory ?? (() => appPath.homeDirPath);

  final UpdateRecoveryPathResolver _homeDirectory;

  Future<File> _file() async {
    final home = await _homeDirectory();
    return File(path.join(home, _updateRecoveryFileName));
  }

  Future<void> save(UpdateRecoveryState state) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temp = File(file.path + '.tmp');
    await temp.writeAsString(json.encode(state.toJson()), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  /// Reads and consumes the one-shot state. A malformed or stale marker is
  /// deleted instead of influencing a normal application launch.
  Future<UpdateRecoveryState?> take({DateTime? now}) async {
    final file = await _file();
    if (!await file.exists()) return null;

    try {
      final decoded = json.decode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Update recovery is not an object.');
      }
      final state = UpdateRecoveryState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (!state.isFresh(now ?? DateTime.now())) {
        return null;
      }
      return state;
    } catch (_) {
      return null;
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Timestamp limiting prevents a stale marker from restoring forever.
      }
    }
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final updateRecovery = UpdateRecoveryStore();
