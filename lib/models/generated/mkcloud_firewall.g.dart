// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../mkcloud_firewall.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MkcloudFirewallProps _$MkcloudFirewallPropsFromJson(
  Map<String, dynamic> json,
) => _MkcloudFirewallProps(
  enable: json['enable'] as bool? ?? false,
  apiKey: json['apiKey'] as String? ?? '',
  pollSeconds: (json['pollSeconds'] as num?)?.toInt() ?? 5,
  directCidrs:
      (json['directCidrs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$MkcloudFirewallPropsToJson(
  _MkcloudFirewallProps instance,
) => <String, dynamic>{
  'enable': instance.enable,
  'apiKey': instance.apiKey,
  'pollSeconds': instance.pollSeconds,
  'directCidrs': instance.directCidrs,
};
