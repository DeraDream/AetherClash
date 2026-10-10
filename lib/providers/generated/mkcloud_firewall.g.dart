// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../mkcloud_firewall.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mkcloudFirewallClient)
final mkcloudFirewallClientProvider = MkcloudFirewallClientProvider._();

final class MkcloudFirewallClientProvider
    extends
        $FunctionalProvider<
          MkcloudDirectTransport,
          MkcloudDirectTransport,
          MkcloudDirectTransport
        >
    with $Provider<MkcloudDirectTransport> {
  MkcloudFirewallClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mkcloudFirewallClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mkcloudFirewallClientHash();

  @$internal
  @override
  $ProviderElement<MkcloudDirectTransport> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MkcloudDirectTransport create(Ref ref) {
    return mkcloudFirewallClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MkcloudDirectTransport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MkcloudDirectTransport>(value),
    );
  }
}

String _$mkcloudFirewallClientHash() =>
    r'214b159afd77470960069fd0054d12a4841357ab';

@ProviderFor(MkcloudFirewall)
final mkcloudFirewallProvider = MkcloudFirewallProvider._();

final class MkcloudFirewallProvider
    extends $NotifierProvider<MkcloudFirewall, MkcloudFirewallState> {
  MkcloudFirewallProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mkcloudFirewallProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mkcloudFirewallHash();

  @$internal
  @override
  MkcloudFirewall create() => MkcloudFirewall();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MkcloudFirewallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MkcloudFirewallState>(value),
    );
  }
}

String _$mkcloudFirewallHash() => r'1ce45c5da52200952b3d1d4ef8af9788d3415d45';

abstract class _$MkcloudFirewall extends $Notifier<MkcloudFirewallState> {
  MkcloudFirewallState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MkcloudFirewallState, MkcloudFirewallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MkcloudFirewallState, MkcloudFirewallState>,
              MkcloudFirewallState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
