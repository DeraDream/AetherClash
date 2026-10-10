import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/mkcloud_firewall.freezed.dart';
part 'generated/mkcloud_firewall.g.dart';

const defaultMkcloudFirewallProps = MkcloudFirewallProps();
const mkcloudPollSecondsRange = (min: 1, max: 3600);

@freezed
abstract class MkcloudFirewallProps with _$MkcloudFirewallProps {
  const factory MkcloudFirewallProps({
    @Default(false) bool enable,
    @Default('') String apiKey,
    @Default(5) int pollSeconds,
    @Default([]) List<String> directCidrs,
  }) = _MkcloudFirewallProps;

  factory MkcloudFirewallProps.fromJson(Map<String, Object?> json) =>
      _$MkcloudFirewallPropsFromJson(json);

  factory MkcloudFirewallProps.safeFromJson(Map<String, Object?>? json) =>
      json == null
      ? defaultMkcloudFirewallProps
      : MkcloudFirewallProps.fromJson(json);
}

enum MkcloudRunKind { poll, query, whitelist }

enum MkcloudResultType { applied, notApplied, error }

@freezed
abstract class MkcloudProvince with _$MkcloudProvince {
  const factory MkcloudProvince({
    required String value,
    required String label,
  }) = _MkcloudProvince;
}

@freezed
abstract class MkcloudWhitelistEntry with _$MkcloudWhitelistEntry {
  const factory MkcloudWhitelistEntry({
    required String cidr,
    DateTime? createdAt,
  }) = _MkcloudWhitelistEntry;
}

@freezed
abstract class MkcloudResult with _$MkcloudResult {
  const factory MkcloudResult({
    required MkcloudResultType type,
    String? mode,
    String? province,
    String? currentIp,
    @Default([]) List<MkcloudWhitelistEntry> entries,
    @Default(0) int count,
    @Default(10) int limit,
    @Default([]) List<MkcloudProvince> provinces,
    String? message,
  }) = _MkcloudResult;
}

@freezed
abstract class MkcloudFirewallState with _$MkcloudFirewallState {
  const factory MkcloudFirewallState({
    @Default(false) bool isRunning,
    DateTime? lastRunAt,
    @Default(MkcloudRunKind.poll) MkcloudRunKind lastRunKind,
    MkcloudResult? result,
  }) = _MkcloudFirewallState;
}
