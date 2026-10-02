import 'package:fl_clash/common/desktop_updater.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> releaseWithAssets() => <String, dynamic>{
  'assets': <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'po0-clash-5.4.0-windows-amd64.zip',
      'browser_download_url': 'https://example.com/windows.zip',
      'size': 100,
    },
    <String, dynamic>{
      'name': 'po0-clash-5.4.0-windows-amd64-setup.exe',
      'browser_download_url': 'https://example.com/windows.exe',
      'size': 200,
      'digest':
          'sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    },
    <String, dynamic>{
      'name': 'po0-clash-5.4.0-macos-arm64.dmg',
      'browser_download_url': 'https://example.com/macos-arm64.dmg',
      'size': 300,
    },
    <String, dynamic>{
      'name': 'po0-clash-5.4.0-macos-amd64.dmg',
      'browser_download_url': 'https://example.com/macos-amd64.dmg',
      'size': 400,
    },
  ],
};

void main() {
  test('selects the Windows installer instead of the portable zip', () {
    final asset = findDesktopUpdateAsset(
      releaseWithAssets(),
      platform: 'windows',
      arch: 'amd64',
    );

    expect(asset?.name, 'po0-clash-5.4.0-windows-amd64-setup.exe');
    expect(asset?.expectedBytes, 200);
    expect(
      asset?.expectedSha256,
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
  });

  test('selects the matching macOS architecture', () {
    final arm64 = findDesktopUpdateAsset(
      releaseWithAssets(),
      platform: 'macos',
      arch: 'arm64',
    );
    final amd64 = findDesktopUpdateAsset(
      releaseWithAssets(),
      platform: 'macos',
      arch: 'amd64',
    );

    expect(arm64?.name, 'po0-clash-5.4.0-macos-arm64.dmg');
    expect(amd64?.name, 'po0-clash-5.4.0-macos-amd64.dmg');
  });

  test('rejects an insecure release asset URL', () {
    final asset = findDesktopUpdateAsset(
      <String, dynamic>{
        'assets': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'po0-clash-5.4.0-windows-amd64-setup.exe',
            'browser_download_url': 'http://example.com/windows.exe',
            'size': 200,
          },
        ],
      },
      platform: 'windows',
      arch: 'amd64',
    );

    expect(asset, isNull);
  });
}
