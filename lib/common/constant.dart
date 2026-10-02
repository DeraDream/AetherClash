// ignore_for_file: constant_identifier_names

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:material_ui/material_ui.dart';

const appName = 'po0-clash';
const appHelperService = 'Po0ClashHelperService';
const tunDeviceName = 'Po0Clash';
const coreManifestName = 'manifest.json';
const coreName = 'clash.meta';
const browserUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
const packageName = 'com.follow.clash';
final unixSocketPath = '/tmp/Po0ClashSocket_${Random().nextInt(10000)}.sock';
final windowsPipeName = '\\\\.\\pipe\\Po0ClashCore_${_randomPipeId()}';
const helperPort = 47990;
const helperSocketPath = '/run/po0clash/helper.sock';
const helperProtocolVersionHeader = 'x-po0clash-helper-protocol';
const helperProtocolVersion = '6';
const maxTextScale = 1.4;
const minTextScale = 0.8;
final baseInfoEdgeInsets = EdgeInsets.symmetric(
  vertical: 16.mAp,
  horizontal: 16.mAp,
);
final listHeaderPadding = EdgeInsets.only(
  left: 16.mAp,
  right: 8.mAp,
  top: 24.mAp,
  bottom: 8.mAp,
);
const sheetAppBarHeight = 68.0;

const watchExecution = false;

String _randomPipeId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

final defaultTextScaleFactor =
    WidgetsBinding.instance.platformDispatcher.textScaleFactor;

/// How long the Core may spend on one delay test. It spends this twice in the
/// worst case - once queueing for a slot, once on the probe itself - so the
/// guard below has to outlast twice this value.
const delayTestTimeoutDuration = Duration(seconds: 8);

const delayTestGuardDuration = Duration(seconds: 30);

const coreConnectionWaitDuration = Duration(seconds: 10);

/// Keep at or below the Core's delay-test concurrency (`delayTestConcurrency`
/// in core/common.go).
const maxConcurrentDelayTests = 16;
const midDuration = Duration(milliseconds: 200);
const commonDuration = Duration(milliseconds: 300);
const defaultUpdateDuration = Duration(days: 1);
const MMDB = 'GEOIP.metadb';
const ASN = 'ASN.mmdb';
const GEOIP = 'GEOIP.dat';
const GEOSITE = 'GEOSITE.dat';
final double kHeaderHeight = getWindowHeaderHeight(
  isDesktop: system.isDesktop,
  isMacOS: system.isMacOS,
);
const profilesDirectoryName = 'profiles';
const providersDirectoryName = 'providers';
const proxiesProviderDirectoryName = 'proxies';
const rulesProviderDirectoryName = 'rules';
const localhost = '127.0.0.1';
const clashConfigKey = 'clash_config';
const configKey = 'config';
const systemDnsRecordKey = 'system_dns_record';
const bootRecordKey = 'boot_record';
const defaultSystemDnsFallback = '223.5.5.5';
const double dialogCommonWidth = 300;
const repository = 'DeraDream/po0-clash';
const upstreamRepository = 'chen08209/FlClash';
const maxMobileWidth = 600;
const maxLaptopWidth = 840;
const defaultTestUrl = 'https://www.gstatic.com/generate_204';

const stringListEquality = ListEquality<String>();
const intListEquality = ListEquality<int>();
const ruleListEquality = ListEquality<Rule>();
const scriptListEquality = ListEquality<Script>();
const profileListEquality = ListEquality<Profile>();
const proxyGroupsEquality = ListEquality<ProxyGroup>();
const hotKeyActionListEquality = ListEquality<HotKeyAction>();
const stringAndStringMapEntryListEquality =
    ListEquality<MapEntry<String, String>>();
const keyboardModifierListEquality = SetEquality<KeyboardModifier>();

const proxiesListStoreKey = PageStorageKey<String>('proxies_list');
const toolsStoreKey = PageStorageKey<String>('tools');
const profilesStoreKey = PageStorageKey<String>('profiles');

const defaultPrimaryColor = 0xFF1677FF;

const maxLogsLength = 5000;
const maxRequestsLength = 2000;
const pausedMaxLogsLength = maxLogsLength * 2;
const pausedMaxRequestsLength = maxRequestsLength * 2;

const trafficSampleLength = 30;

const defaultPrimaryColors = [
  defaultPrimaryColor,
  0xFF5856D6,
  0xFFAF52DE,
  0xFFFF2D55,
  0xFFFF9500,
  0xFF34C759,
  0xFF30B0C7,
  0xFF8E8E93,
];

const scriptTemplate = '''
const main = (config) => {
  return config;
}''';

const backupDatabaseName = 'database.sqlite';
const configJsonName = 'config.json';
