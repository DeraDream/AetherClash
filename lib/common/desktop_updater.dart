import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/exception.dart';
import 'package:path/path.dart' as path;

enum DesktopUpdateStage { downloading, installing }

final class DesktopUpdateProgress {
  final DesktopUpdateStage stage;
  final int receivedBytes;
  final int totalBytes;

  const DesktopUpdateProgress({
    required this.stage,
    this.receivedBytes = 0,
    this.totalBytes = 0,
  });

  double? get fraction {
    if (stage == DesktopUpdateStage.installing) {
      return 1;
    }
    if (totalBytes <= 0) {
      return null;
    }
    return (receivedBytes / totalBytes).clamp(0, 1).toDouble();
  }
}

final class DesktopUpdateAsset {
  final String name;
  final Uri downloadUri;
  final int expectedBytes;
  final String? expectedSha256;

  const DesktopUpdateAsset({
    required this.name,
    required this.downloadUri,
    required this.expectedBytes,
    required this.expectedSha256,
  });
}

DesktopUpdateAsset? findDesktopUpdateAsset(
  Map<String, dynamic> release, {
  required String platform,
  required String arch,
}) {
  final suffix = switch (platform) {
    'windows' => '-windows-$arch-setup.exe',
    'macos' => '-macos-$arch.dmg',
    _ => '',
  };
  if (suffix.isEmpty) {
    return null;
  }
  final assets = release['assets'];
  if (assets is! List) {
    return null;
  }
  for (final rawAsset in assets) {
    if (rawAsset is! Map) {
      continue;
    }
    final name = rawAsset['name'];
    final downloadUrl = rawAsset['browser_download_url'];
    if (name is! String ||
        downloadUrl is! String ||
        !name.endsWith(suffix)) {
      continue;
    }
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || uri.scheme != 'https') {
      continue;
    }
    final size = rawAsset['size'];
    final digest = rawAsset['digest'];
    final digestMatch = digest is String
        ? RegExp(r'^sha256:([0-9a-fA-F]{64})
  }
  return null;
}

final class DesktopUpdater {
  bool get isSupported => Platform.isWindows || Platform.isMacOS;

  Future<void> prepareUpdate({
    required Map<String, dynamic> release,
    required Dio dio,
    required void Function(DesktopUpdateProgress progress) onProgress,
  }) async {
    final target = await _target();
    final asset = findDesktopUpdateAsset(
      release,
      platform: target.platform,
      arch: target.arch,
    );
    if (asset == null) {
      throw const MessageException('No compatible update package was found.');
    }

    final updateDirectory = await Directory.systemTemp.createTemp(
      'po0-clash-update-',
    );
    final package = File(path.join(updateDirectory.path, asset.name));
    onProgress(
      DesktopUpdateProgress(
        stage: DesktopUpdateStage.downloading,
        totalBytes: asset.expectedBytes,
      ),
    );
    try {
      await dio.download(
        asset.downloadUri.toString(),
        package.path,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
        onReceiveProgress: (received, total) {
          onProgress(
            DesktopUpdateProgress(
              stage: DesktopUpdateStage.downloading,
              receivedBytes: received,
              totalBytes: total > 0 ? total : asset.expectedBytes,
            ),
          );
        },
      );
      final actualBytes = await package.length();
      if (asset.expectedBytes > 0 && actualBytes != asset.expectedBytes) {
        throw const MessageException('The downloaded update is incomplete.');
      }
      final expectedSha256 = asset.expectedSha256;
      if (expectedSha256 != null) {
        final actualSha256 = (await sha256.bind(package.openRead()).first)
            .toString();
        if (actualSha256 != expectedSha256) {
          throw const MessageException(
            'The downloaded update failed its integrity check.',
          );
        }
      }
      onProgress(
        DesktopUpdateProgress(
          stage: DesktopUpdateStage.installing,
          receivedBytes: actualBytes,
          totalBytes: actualBytes,
        ),
      );
      if (Platform.isWindows) {
        await _launchWindowsUpdater(package);
      } else {
        await _launchMacOSUpdater(package);
      }
    } catch (_) {
      if (await updateDirectory.exists()) {
        await updateDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<({String platform, String arch})> _target() async {
    if (Platform.isWindows) {
      return (platform: 'windows', arch: 'amd64');
    }
    if (!Platform.isMacOS) {
      throw const MessageException('Desktop self-update is not supported here.');
    }
    final result = await Process.run('/usr/bin/uname', ['-m']);
    final machine = result.stdout.toString().trim();
    final arch = switch (machine) {
      'arm64' => 'arm64',
      'x86_64' => 'amd64',
      _ => null,
    };
    if (arch == null) {
      throw MessageException('Unsupported macOS architecture: $machine');
    }
    return (platform: 'macos', arch: arch);
  }

  Future<void> _launchWindowsUpdater(File installer) async {
    final executable = File(Platform.resolvedExecutable);
    final updateDirectory = installer.parent;
    final script = File(path.join(updateDirectory.path, 'update.ps1'));
    final installDirectory = executable.parent.path;
    await script.writeAsString('''
\$ErrorActionPreference = 'Stop'
\$appProcessId = $pid
\$installer = ${_powerShellQuote(installer.path)}
\$target = ${_powerShellQuote(executable.path)}
\$installDir = ${_powerShellQuote(installDirectory)}

for (\$i = 0; \$i -lt 40; \$i++) {
  if (-not (Get-Process -Id \$appProcessId -ErrorAction SilentlyContinue)) { break }
  Start-Sleep -Milliseconds 250
}
if (Get-Process -Id \$appProcessId -ErrorAction SilentlyContinue) {
  Stop-Process -Id \$appProcessId -Force
  Start-Sleep -Milliseconds 500
}

try {
  \$installerArgs = '/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="' + \$installDir + '"'
  \$process = Start-Process -FilePath \$installer -ArgumentList \$installerArgs -Verb RunAs -PassThru -Wait
  if (\$process.ExitCode -ne 0) {
    throw "installer exited with code \$(\$process.ExitCode)"
  }
  Start-Process -FilePath \$target
} catch {
  if (Test-Path -LiteralPath \$target) {
    Start-Process -FilePath \$target
  }
  exit 1
} finally {
  Remove-Item -LiteralPath \$installer -Force -ErrorAction SilentlyContinue
}
''');
    await Process.start(
      'powershell.exe',
      [
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script.path,
      ],
      mode: ProcessStartMode.detached,
    );
  }

  Future<void> _launchMacOSUpdater(File dmg) async {
    final executable = File(Platform.resolvedExecutable);
    final bundle = executable.parent.parent.parent;
    if (path.extension(bundle.path) != '.app') {
      throw const MessageException('The running macOS app bundle was not found.');
    }
    final updateDirectory = dmg.parent;
    final script = File(path.join(updateDirectory.path, 'update.sh'));
    await script.writeAsString('''
#!/bin/bash
set -euo pipefail
app_pid=$pid
dmg=${_shellQuote(dmg.path)}
target=${_shellQuote(bundle.path)}
update_root=${_shellQuote(updateDirectory.path)}
mountpoint="\$update_root/mnt"
replacement="\${target}.po0-update"

cleanup() {
  /usr/bin/hdiutil detach "\$mountpoint" -quiet >/dev/null 2>&1 || true
  /bin/rm -rf "\$replacement" "\$mountpoint"
}
trap cleanup EXIT

for _ in {1..40}; do
  if ! /bin/kill -0 "\$app_pid" >/dev/null 2>&1; then break; fi
  /bin/sleep 0.25
done
if /bin/kill -0 "\$app_pid" >/dev/null 2>&1; then
  /bin/kill "\$app_pid" >/dev/null 2>&1 || true
  /bin/sleep 1
  /bin/kill -9 "\$app_pid" >/dev/null 2>&1 || true
fi

/bin/mkdir -p "\$mountpoint"
/usr/bin/hdiutil attach "\$dmg" -nobrowse -readonly -quiet -mountpoint "\$mountpoint"
source_app="\$mountpoint/po0-clash.app"
[ -d "\$source_app" ] || exit 2

if [ -w "\$(/usr/bin/dirname "\$target")" ] && { [ ! -e "\$target" ] || [ -w "\$target" ]; }; then
  /bin/rm -rf "\$replacement"
  /usr/bin/ditto "\$source_app" "\$replacement"
  /usr/bin/xattr -dr com.apple.quarantine "\$replacement" 2>/dev/null || true
  /bin/rm -rf "\$target"
  /bin/mv "\$replacement" "\$target"
else
  command="/bin/rm -rf \$(printf '%q' "\$replacement") && /usr/bin/ditto \$(printf '%q' "\$source_app") \$(printf '%q' "\$replacement") && (/usr/bin/xattr -dr com.apple.quarantine \$(printf '%q' "\$replacement") 2>/dev/null || true) && /bin/rm -rf \$(printf '%q' "\$target") && /bin/mv \$(printf '%q' "\$replacement") \$(printf '%q' "\$target")"
  /usr/bin/osascript \
    -e 'on run argv' \
    -e 'do shell script item 1 of argv with administrator privileges' \
    -e 'end run' \
    "\$command"
fi

/usr/bin/hdiutil detach "\$mountpoint" -quiet >/dev/null 2>&1 || true
trap - EXIT
/usr/bin/open "\$target"
/bin/rm -rf "\$update_root"
''');
    await Process.start(
      '/bin/bash',
      [script.path],
      mode: ProcessStartMode.detached,
    );
  }
}

String _powerShellQuote(String value) => "'${value.replaceAll("'", "''")}'";

String _shellQuote(String value) => "'${value.replaceAll("'", "'\"'\"'")}'";

final desktopUpdater = DesktopUpdater();
).firstMatch(digest)
        : null;
    return DesktopUpdateAsset(
      name: name,
      downloadUri: uri,
      expectedBytes: size is int ? size : int.tryParse('$size') ?? 0,
      expectedSha256: digestMatch?.group(1)?.toLowerCase(),
    );
  }
  return null;
}

final class DesktopUpdater {
  bool get isSupported => Platform.isWindows || Platform.isMacOS;

  Future<void> prepareUpdate({
    required Map<String, dynamic> release,
    required Dio dio,
    required void Function(DesktopUpdateProgress progress) onProgress,
  }) async {
    final target = await _target();
    final asset = findDesktopUpdateAsset(
      release,
      platform: target.platform,
      arch: target.arch,
    );
    if (asset == null) {
      throw const MessageException('No compatible update package was found.');
    }

    final updateDirectory = await Directory.systemTemp.createTemp(
      'po0-clash-update-',
    );
    final package = File(path.join(updateDirectory.path, asset.name));
    onProgress(
      DesktopUpdateProgress(
        stage: DesktopUpdateStage.downloading,
        totalBytes: asset.expectedBytes,
      ),
    );
    try {
      await dio.download(
        asset.downloadUri.toString(),
        package.path,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
        onReceiveProgress: (received, total) {
          onProgress(
            DesktopUpdateProgress(
              stage: DesktopUpdateStage.downloading,
              receivedBytes: received,
              totalBytes: total > 0 ? total : asset.expectedBytes,
            ),
          );
        },
      );
      final actualBytes = await package.length();
      if (asset.expectedBytes > 0 && actualBytes != asset.expectedBytes) {
        throw const MessageException('The downloaded update is incomplete.');
      }
      onProgress(
        DesktopUpdateProgress(
          stage: DesktopUpdateStage.installing,
          receivedBytes: actualBytes,
          totalBytes: actualBytes,
        ),
      );
      if (Platform.isWindows) {
        await _launchWindowsUpdater(package);
      } else {
        await _launchMacOSUpdater(package);
      }
    } catch (_) {
      if (await package.exists()) {
        await package.delete();
      }
      rethrow;
    }
  }

  Future<({String platform, String arch})> _target() async {
    if (Platform.isWindows) {
      return (platform: 'windows', arch: 'amd64');
    }
    if (!Platform.isMacOS) {
      throw const MessageException('Desktop self-update is not supported here.');
    }
    final result = await Process.run('/usr/bin/uname', ['-m']);
    final machine = result.stdout.toString().trim();
    final arch = switch (machine) {
      'arm64' => 'arm64',
      'x86_64' => 'amd64',
      _ => null,
    };
    if (arch == null) {
      throw MessageException('Unsupported macOS architecture: $machine');
    }
    return (platform: 'macos', arch: arch);
  }

  Future<void> _launchWindowsUpdater(File installer) async {
    final executable = File(Platform.resolvedExecutable);
    final updateDirectory = installer.parent;
    final script = File(path.join(updateDirectory.path, 'update.ps1'));
    final installDirectory = executable.parent.path;
    await script.writeAsString('''
\$ErrorActionPreference = 'Stop'
\$appProcessId = $pid
\$installer = ${_powerShellQuote(installer.path)}
\$target = ${_powerShellQuote(executable.path)}
\$installDir = ${_powerShellQuote(installDirectory)}

for (\$i = 0; \$i -lt 40; \$i++) {
  if (-not (Get-Process -Id \$appProcessId -ErrorAction SilentlyContinue)) { break }
  Start-Sleep -Milliseconds 250
}
if (Get-Process -Id \$appProcessId -ErrorAction SilentlyContinue) {
  Stop-Process -Id \$appProcessId -Force
  Start-Sleep -Milliseconds 500
}

try {
  \$installerArgs = '/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="' + \$installDir + '"'
  \$process = Start-Process -FilePath \$installer -ArgumentList \$installerArgs -Verb RunAs -PassThru -Wait
  if (\$process.ExitCode -ne 0) {
    throw "installer exited with code \$(\$process.ExitCode)"
  }
  Start-Process -FilePath \$target
} catch {
  if (Test-Path -LiteralPath \$target) {
    Start-Process -FilePath \$target
  }
  exit 1
} finally {
  Remove-Item -LiteralPath \$installer -Force -ErrorAction SilentlyContinue
}
''');
    await Process.start(
      'powershell.exe',
      [
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script.path,
      ],
      mode: ProcessStartMode.detached,
    );
  }

  Future<void> _launchMacOSUpdater(File dmg) async {
    final executable = File(Platform.resolvedExecutable);
    final bundle = executable.parent.parent.parent;
    if (path.extension(bundle.path) != '.app') {
      throw const MessageException('The running macOS app bundle was not found.');
    }
    final updateDirectory = dmg.parent;
    final script = File(path.join(updateDirectory.path, 'update.sh'));
    await script.writeAsString('''
#!/bin/bash
set -euo pipefail
app_pid=$pid
dmg=${_shellQuote(dmg.path)}
target=${_shellQuote(bundle.path)}
update_root=${_shellQuote(updateDirectory.path)}
mountpoint="\$update_root/mnt"
replacement="\${target}.po0-update"

cleanup() {
  /usr/bin/hdiutil detach "\$mountpoint" -quiet >/dev/null 2>&1 || true
  /bin/rm -rf "\$replacement" "\$mountpoint"
}
trap cleanup EXIT

for _ in {1..40}; do
  if ! /bin/kill -0 "\$app_pid" >/dev/null 2>&1; then break; fi
  /bin/sleep 0.25
done
if /bin/kill -0 "\$app_pid" >/dev/null 2>&1; then
  /bin/kill "\$app_pid" >/dev/null 2>&1 || true
  /bin/sleep 1
  /bin/kill -9 "\$app_pid" >/dev/null 2>&1 || true
fi

/bin/mkdir -p "\$mountpoint"
/usr/bin/hdiutil attach "\$dmg" -nobrowse -readonly -quiet -mountpoint "\$mountpoint"
source_app="\$mountpoint/po0-clash.app"
[ -d "\$source_app" ] || exit 2

if [ -w "\$(/usr/bin/dirname "\$target")" ] && { [ ! -e "\$target" ] || [ -w "\$target" ]; }; then
  /bin/rm -rf "\$replacement"
  /usr/bin/ditto "\$source_app" "\$replacement"
  /usr/bin/xattr -dr com.apple.quarantine "\$replacement" 2>/dev/null || true
  /bin/rm -rf "\$target"
  /bin/mv "\$replacement" "\$target"
else
  command="/bin/rm -rf \$(printf '%q' "\$replacement") && /usr/bin/ditto \$(printf '%q' "\$source_app") \$(printf '%q' "\$replacement") && (/usr/bin/xattr -dr com.apple.quarantine \$(printf '%q' "\$replacement") 2>/dev/null || true) && /bin/rm -rf \$(printf '%q' "\$target") && /bin/mv \$(printf '%q' "\$replacement") \$(printf '%q' "\$target")"
  /usr/bin/osascript \
    -e 'on run argv' \
    -e 'do shell script item 1 of argv with administrator privileges' \
    -e 'end run' \
    "\$command"
fi

/usr/bin/hdiutil detach "\$mountpoint" -quiet >/dev/null 2>&1 || true
trap - EXIT
/usr/bin/open "\$target"
/bin/rm -rf "\$update_root"
''');
    await Process.start(
      '/bin/bash',
      [script.path],
      mode: ProcessStartMode.detached,
    );
  }
}

String _powerShellQuote(String value) => "'${value.replaceAll("'", "''")}'";

String _shellQuote(String value) => "'${value.replaceAll("'", "'\"'\"'")}'";

final desktopUpdater = DesktopUpdater();
