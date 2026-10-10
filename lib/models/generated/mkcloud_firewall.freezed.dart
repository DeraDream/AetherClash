// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../mkcloud_firewall.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MkcloudFirewallProps {

 bool get enable; String get apiKey; int get pollSeconds; List<String> get directCidrs;
/// Create a copy of MkcloudFirewallProps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MkcloudFirewallPropsCopyWith<MkcloudFirewallProps> get copyWith => _$MkcloudFirewallPropsCopyWithImpl<MkcloudFirewallProps>(this as MkcloudFirewallProps, _$identity);

  /// Serializes this MkcloudFirewallProps to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MkcloudFirewallProps;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MkcloudFirewallProps&&(identical(other.enable, _this.enable) || other.enable == _this.enable)&&(identical(other.apiKey, _this.apiKey) || other.apiKey == _this.apiKey)&&(identical(other.pollSeconds, _this.pollSeconds) || other.pollSeconds == _this.pollSeconds)&&const DeepCollectionEquality().equals(other.directCidrs, _this.directCidrs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MkcloudFirewallProps;
  return Object.hash(runtimeType,_this.enable,_this.apiKey,_this.pollSeconds,const DeepCollectionEquality().hash(_this.directCidrs));
}

@override
String toString() {
  final _this = this as MkcloudFirewallProps;
  return 'MkcloudFirewallProps(enable: ${_this.enable}, apiKey: ${_this.apiKey}, pollSeconds: ${_this.pollSeconds}, directCidrs: ${_this.directCidrs})';
}


}

/// @nodoc
abstract mixin class $MkcloudFirewallPropsCopyWith<$Res>  {
  factory $MkcloudFirewallPropsCopyWith(MkcloudFirewallProps value, $Res Function(MkcloudFirewallProps) _then) = _$MkcloudFirewallPropsCopyWithImpl;
@useResult
$Res call({
 bool enable, String apiKey, int pollSeconds, List<String> directCidrs
});




}
/// @nodoc
class _$MkcloudFirewallPropsCopyWithImpl<$Res>
    implements $MkcloudFirewallPropsCopyWith<$Res> {
  _$MkcloudFirewallPropsCopyWithImpl(this._self, this._then);

  final MkcloudFirewallProps _self;
  final $Res Function(MkcloudFirewallProps) _then;

/// Create a copy of MkcloudFirewallProps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enable = null,Object? apiKey = null,Object? pollSeconds = null,Object? directCidrs = null,}) {
  return _then(MkcloudFirewallProps(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,pollSeconds: null == pollSeconds ? _self.pollSeconds : pollSeconds // ignore: cast_nullable_to_non_nullable
as int,directCidrs: null == directCidrs ? _self.directCidrs : directCidrs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MkcloudFirewallProps].
extension MkcloudFirewallPropsPatterns on MkcloudFirewallProps {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MkcloudFirewallProps value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MkcloudFirewallProps() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MkcloudFirewallProps value)  $default,){
final _that = this;
switch (_that) {
case _MkcloudFirewallProps():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MkcloudFirewallProps value)?  $default,){
final _that = this;
switch (_that) {
case _MkcloudFirewallProps() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enable,  String apiKey,  int pollSeconds,  List<String> directCidrs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MkcloudFirewallProps() when $default != null:
return $default(_that.enable,_that.apiKey,_that.pollSeconds,_that.directCidrs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enable,  String apiKey,  int pollSeconds,  List<String> directCidrs)  $default,) {final _that = this;
switch (_that) {
case _MkcloudFirewallProps():
return $default(_that.enable,_that.apiKey,_that.pollSeconds,_that.directCidrs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enable,  String apiKey,  int pollSeconds,  List<String> directCidrs)?  $default,) {final _that = this;
switch (_that) {
case _MkcloudFirewallProps() when $default != null:
return $default(_that.enable,_that.apiKey,_that.pollSeconds,_that.directCidrs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MkcloudFirewallProps implements MkcloudFirewallProps {
  const _MkcloudFirewallProps({this.enable = false, this.apiKey = '', this.pollSeconds = 5,  List<String> directCidrs = const []}): _directCidrs = directCidrs;
  factory _MkcloudFirewallProps.fromJson(Map<String, dynamic> json) => _$MkcloudFirewallPropsFromJson(json);

@override@JsonKey() final  bool enable;
@override@JsonKey() final  String apiKey;
@override@JsonKey() final  int pollSeconds;
 final  List<String> _directCidrs;
@override@JsonKey() List<String> get directCidrs {
  if (_directCidrs is EqualUnmodifiableListView) return _directCidrs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_directCidrs);
}


/// Create a copy of MkcloudFirewallProps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MkcloudFirewallPropsCopyWith<_MkcloudFirewallProps> get copyWith => __$MkcloudFirewallPropsCopyWithImpl<_MkcloudFirewallProps>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MkcloudFirewallPropsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MkcloudFirewallProps&&(identical(other.enable, enable) || other.enable == enable)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey)&&(identical(other.pollSeconds, pollSeconds) || other.pollSeconds == pollSeconds)&&const DeepCollectionEquality().equals(other.directCidrs, _directCidrs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enable,apiKey,pollSeconds,const DeepCollectionEquality().hash(_directCidrs));
}

@override
String toString() {
    return 'MkcloudFirewallProps(enable: $enable, apiKey: $apiKey, pollSeconds: $pollSeconds, directCidrs: $directCidrs)';
}


}

/// @nodoc
abstract mixin class _$MkcloudFirewallPropsCopyWith<$Res> implements $MkcloudFirewallPropsCopyWith<$Res> {
  factory _$MkcloudFirewallPropsCopyWith(_MkcloudFirewallProps value, $Res Function(_MkcloudFirewallProps) _then) = __$MkcloudFirewallPropsCopyWithImpl;
@override @useResult
$Res call({
 bool enable, String apiKey, int pollSeconds, List<String> directCidrs
});




}
/// @nodoc
class __$MkcloudFirewallPropsCopyWithImpl<$Res>
    implements _$MkcloudFirewallPropsCopyWith<$Res> {
  __$MkcloudFirewallPropsCopyWithImpl(this._self, this._then);

  final _MkcloudFirewallProps _self;
  final $Res Function(_MkcloudFirewallProps) _then;

/// Create a copy of MkcloudFirewallProps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enable = null,Object? apiKey = null,Object? pollSeconds = null,Object? directCidrs = null,}) {
  return _then(_MkcloudFirewallProps(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,pollSeconds: null == pollSeconds ? _self.pollSeconds : pollSeconds // ignore: cast_nullable_to_non_nullable
as int,directCidrs: null == directCidrs ? _self._directCidrs : directCidrs // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$MkcloudProvince {

 String get value; String get label;
/// Create a copy of MkcloudProvince
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MkcloudProvinceCopyWith<MkcloudProvince> get copyWith => _$MkcloudProvinceCopyWithImpl<MkcloudProvince>(this as MkcloudProvince, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MkcloudProvince;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MkcloudProvince&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.label, _this.label) || other.label == _this.label));
}


@override
int get hashCode {
  final _this = this as MkcloudProvince;
  return Object.hash(runtimeType,_this.value,_this.label);
}

@override
String toString() {
  final _this = this as MkcloudProvince;
  return 'MkcloudProvince(value: ${_this.value}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $MkcloudProvinceCopyWith<$Res>  {
  factory $MkcloudProvinceCopyWith(MkcloudProvince value, $Res Function(MkcloudProvince) _then) = _$MkcloudProvinceCopyWithImpl;
@useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class _$MkcloudProvinceCopyWithImpl<$Res>
    implements $MkcloudProvinceCopyWith<$Res> {
  _$MkcloudProvinceCopyWithImpl(this._self, this._then);

  final MkcloudProvince _self;
  final $Res Function(MkcloudProvince) _then;

/// Create a copy of MkcloudProvince
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? label = null,}) {
  return _then(MkcloudProvince(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MkcloudProvince].
extension MkcloudProvincePatterns on MkcloudProvince {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MkcloudProvince value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MkcloudProvince() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MkcloudProvince value)  $default,){
final _that = this;
switch (_that) {
case _MkcloudProvince():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MkcloudProvince value)?  $default,){
final _that = this;
switch (_that) {
case _MkcloudProvince() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MkcloudProvince() when $default != null:
return $default(_that.value,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  String label)  $default,) {final _that = this;
switch (_that) {
case _MkcloudProvince():
return $default(_that.value,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  String label)?  $default,) {final _that = this;
switch (_that) {
case _MkcloudProvince() when $default != null:
return $default(_that.value,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _MkcloudProvince implements MkcloudProvince {
  const _MkcloudProvince({required this.value, required this.label});
  

@override final  String value;
@override final  String label;

/// Create a copy of MkcloudProvince
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MkcloudProvinceCopyWith<_MkcloudProvince> get copyWith => __$MkcloudProvinceCopyWithImpl<_MkcloudProvince>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MkcloudProvince&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode {
    return Object.hash(runtimeType,value,label);
}

@override
String toString() {
    return 'MkcloudProvince(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class _$MkcloudProvinceCopyWith<$Res> implements $MkcloudProvinceCopyWith<$Res> {
  factory _$MkcloudProvinceCopyWith(_MkcloudProvince value, $Res Function(_MkcloudProvince) _then) = __$MkcloudProvinceCopyWithImpl;
@override @useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class __$MkcloudProvinceCopyWithImpl<$Res>
    implements _$MkcloudProvinceCopyWith<$Res> {
  __$MkcloudProvinceCopyWithImpl(this._self, this._then);

  final _MkcloudProvince _self;
  final $Res Function(_MkcloudProvince) _then;

/// Create a copy of MkcloudProvince
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? label = null,}) {
  return _then(_MkcloudProvince(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MkcloudWhitelistEntry {

 String get cidr; DateTime? get createdAt;
/// Create a copy of MkcloudWhitelistEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MkcloudWhitelistEntryCopyWith<MkcloudWhitelistEntry> get copyWith => _$MkcloudWhitelistEntryCopyWithImpl<MkcloudWhitelistEntry>(this as MkcloudWhitelistEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MkcloudWhitelistEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MkcloudWhitelistEntry&&(identical(other.cidr, _this.cidr) || other.cidr == _this.cidr)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as MkcloudWhitelistEntry;
  return Object.hash(runtimeType,_this.cidr,_this.createdAt);
}

@override
String toString() {
  final _this = this as MkcloudWhitelistEntry;
  return 'MkcloudWhitelistEntry(cidr: ${_this.cidr}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MkcloudWhitelistEntryCopyWith<$Res>  {
  factory $MkcloudWhitelistEntryCopyWith(MkcloudWhitelistEntry value, $Res Function(MkcloudWhitelistEntry) _then) = _$MkcloudWhitelistEntryCopyWithImpl;
@useResult
$Res call({
 String cidr, DateTime? createdAt
});




}
/// @nodoc
class _$MkcloudWhitelistEntryCopyWithImpl<$Res>
    implements $MkcloudWhitelistEntryCopyWith<$Res> {
  _$MkcloudWhitelistEntryCopyWithImpl(this._self, this._then);

  final MkcloudWhitelistEntry _self;
  final $Res Function(MkcloudWhitelistEntry) _then;

/// Create a copy of MkcloudWhitelistEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cidr = null,Object? createdAt = freezed,}) {
  return _then(MkcloudWhitelistEntry(
cidr: null == cidr ? _self.cidr : cidr // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MkcloudWhitelistEntry].
extension MkcloudWhitelistEntryPatterns on MkcloudWhitelistEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MkcloudWhitelistEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MkcloudWhitelistEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MkcloudWhitelistEntry value)  $default,){
final _that = this;
switch (_that) {
case _MkcloudWhitelistEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MkcloudWhitelistEntry value)?  $default,){
final _that = this;
switch (_that) {
case _MkcloudWhitelistEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cidr,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MkcloudWhitelistEntry() when $default != null:
return $default(_that.cidr,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cidr,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _MkcloudWhitelistEntry():
return $default(_that.cidr,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cidr,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MkcloudWhitelistEntry() when $default != null:
return $default(_that.cidr,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _MkcloudWhitelistEntry implements MkcloudWhitelistEntry {
  const _MkcloudWhitelistEntry({required this.cidr, this.createdAt});
  

@override final  String cidr;
@override final  DateTime? createdAt;

/// Create a copy of MkcloudWhitelistEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MkcloudWhitelistEntryCopyWith<_MkcloudWhitelistEntry> get copyWith => __$MkcloudWhitelistEntryCopyWithImpl<_MkcloudWhitelistEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MkcloudWhitelistEntry&&(identical(other.cidr, cidr) || other.cidr == cidr)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,cidr,createdAt);
}

@override
String toString() {
    return 'MkcloudWhitelistEntry(cidr: $cidr, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MkcloudWhitelistEntryCopyWith<$Res> implements $MkcloudWhitelistEntryCopyWith<$Res> {
  factory _$MkcloudWhitelistEntryCopyWith(_MkcloudWhitelistEntry value, $Res Function(_MkcloudWhitelistEntry) _then) = __$MkcloudWhitelistEntryCopyWithImpl;
@override @useResult
$Res call({
 String cidr, DateTime? createdAt
});




}
/// @nodoc
class __$MkcloudWhitelistEntryCopyWithImpl<$Res>
    implements _$MkcloudWhitelistEntryCopyWith<$Res> {
  __$MkcloudWhitelistEntryCopyWithImpl(this._self, this._then);

  final _MkcloudWhitelistEntry _self;
  final $Res Function(_MkcloudWhitelistEntry) _then;

/// Create a copy of MkcloudWhitelistEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cidr = null,Object? createdAt = freezed,}) {
  return _then(_MkcloudWhitelistEntry(
cidr: null == cidr ? _self.cidr : cidr // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MkcloudResult {

 MkcloudResultType get type; String? get mode; String? get province; String? get currentIp; List<MkcloudWhitelistEntry> get entries; int get count; int get limit; List<MkcloudProvince> get provinces; String? get message;
/// Create a copy of MkcloudResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MkcloudResultCopyWith<MkcloudResult> get copyWith => _$MkcloudResultCopyWithImpl<MkcloudResult>(this as MkcloudResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MkcloudResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MkcloudResult&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.province, _this.province) || other.province == _this.province)&&(identical(other.currentIp, _this.currentIp) || other.currentIp == _this.currentIp)&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&const DeepCollectionEquality().equals(other.provinces, _this.provinces)&&(identical(other.message, _this.message) || other.message == _this.message));
}


@override
int get hashCode {
  final _this = this as MkcloudResult;
  return Object.hash(runtimeType,_this.type,_this.mode,_this.province,_this.currentIp,const DeepCollectionEquality().hash(_this.entries),_this.count,_this.limit,const DeepCollectionEquality().hash(_this.provinces),_this.message);
}

@override
String toString() {
  final _this = this as MkcloudResult;
  return 'MkcloudResult(type: ${_this.type}, mode: ${_this.mode}, province: ${_this.province}, currentIp: ${_this.currentIp}, entries: ${_this.entries}, count: ${_this.count}, limit: ${_this.limit}, provinces: ${_this.provinces}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $MkcloudResultCopyWith<$Res>  {
  factory $MkcloudResultCopyWith(MkcloudResult value, $Res Function(MkcloudResult) _then) = _$MkcloudResultCopyWithImpl;
@useResult
$Res call({
 MkcloudResultType type, String? mode, String? province, String? currentIp, List<MkcloudWhitelistEntry> entries, int count, int limit, List<MkcloudProvince> provinces, String? message
});




}
/// @nodoc
class _$MkcloudResultCopyWithImpl<$Res>
    implements $MkcloudResultCopyWith<$Res> {
  _$MkcloudResultCopyWithImpl(this._self, this._then);

  final MkcloudResult _self;
  final $Res Function(MkcloudResult) _then;

/// Create a copy of MkcloudResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? mode = freezed,Object? province = freezed,Object? currentIp = freezed,Object? entries = null,Object? count = null,Object? limit = null,Object? provinces = null,Object? message = freezed,}) {
  return _then(MkcloudResult(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MkcloudResultType,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String?,currentIp: freezed == currentIp ? _self.currentIp : currentIp // ignore: cast_nullable_to_non_nullable
as String?,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<MkcloudWhitelistEntry>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,provinces: null == provinces ? _self.provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<MkcloudProvince>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MkcloudResult].
extension MkcloudResultPatterns on MkcloudResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MkcloudResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MkcloudResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MkcloudResult value)  $default,){
final _that = this;
switch (_that) {
case _MkcloudResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MkcloudResult value)?  $default,){
final _that = this;
switch (_that) {
case _MkcloudResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MkcloudResultType type,  String? mode,  String? province,  String? currentIp,  List<MkcloudWhitelistEntry> entries,  int count,  int limit,  List<MkcloudProvince> provinces,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MkcloudResult() when $default != null:
return $default(_that.type,_that.mode,_that.province,_that.currentIp,_that.entries,_that.count,_that.limit,_that.provinces,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MkcloudResultType type,  String? mode,  String? province,  String? currentIp,  List<MkcloudWhitelistEntry> entries,  int count,  int limit,  List<MkcloudProvince> provinces,  String? message)  $default,) {final _that = this;
switch (_that) {
case _MkcloudResult():
return $default(_that.type,_that.mode,_that.province,_that.currentIp,_that.entries,_that.count,_that.limit,_that.provinces,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MkcloudResultType type,  String? mode,  String? province,  String? currentIp,  List<MkcloudWhitelistEntry> entries,  int count,  int limit,  List<MkcloudProvince> provinces,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _MkcloudResult() when $default != null:
return $default(_that.type,_that.mode,_that.province,_that.currentIp,_that.entries,_that.count,_that.limit,_that.provinces,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _MkcloudResult implements MkcloudResult {
  const _MkcloudResult({required this.type, this.mode, this.province, this.currentIp,  List<MkcloudWhitelistEntry> entries = const [], this.count = 0, this.limit = 10,  List<MkcloudProvince> provinces = const [], this.message}): _entries = entries,_provinces = provinces;
  

@override final  MkcloudResultType type;
@override final  String? mode;
@override final  String? province;
@override final  String? currentIp;
 final  List<MkcloudWhitelistEntry> _entries;
@override@JsonKey() List<MkcloudWhitelistEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

@override@JsonKey() final  int count;
@override@JsonKey() final  int limit;
 final  List<MkcloudProvince> _provinces;
@override@JsonKey() List<MkcloudProvince> get provinces {
  if (_provinces is EqualUnmodifiableListView) return _provinces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_provinces);
}

@override final  String? message;

/// Create a copy of MkcloudResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MkcloudResultCopyWith<_MkcloudResult> get copyWith => __$MkcloudResultCopyWithImpl<_MkcloudResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MkcloudResult&&(identical(other.type, type) || other.type == type)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.province, province) || other.province == province)&&(identical(other.currentIp, currentIp) || other.currentIp == currentIp)&&const DeepCollectionEquality().equals(other.entries, _entries)&&(identical(other.count, count) || other.count == count)&&(identical(other.limit, limit) || other.limit == limit)&&const DeepCollectionEquality().equals(other.provinces, _provinces)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,mode,province,currentIp,const DeepCollectionEquality().hash(_entries),count,limit,const DeepCollectionEquality().hash(_provinces),message);
}

@override
String toString() {
    return 'MkcloudResult(type: $type, mode: $mode, province: $province, currentIp: $currentIp, entries: $entries, count: $count, limit: $limit, provinces: $provinces, message: $message)';
}


}

/// @nodoc
abstract mixin class _$MkcloudResultCopyWith<$Res> implements $MkcloudResultCopyWith<$Res> {
  factory _$MkcloudResultCopyWith(_MkcloudResult value, $Res Function(_MkcloudResult) _then) = __$MkcloudResultCopyWithImpl;
@override @useResult
$Res call({
 MkcloudResultType type, String? mode, String? province, String? currentIp, List<MkcloudWhitelistEntry> entries, int count, int limit, List<MkcloudProvince> provinces, String? message
});




}
/// @nodoc
class __$MkcloudResultCopyWithImpl<$Res>
    implements _$MkcloudResultCopyWith<$Res> {
  __$MkcloudResultCopyWithImpl(this._self, this._then);

  final _MkcloudResult _self;
  final $Res Function(_MkcloudResult) _then;

/// Create a copy of MkcloudResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? mode = freezed,Object? province = freezed,Object? currentIp = freezed,Object? entries = null,Object? count = null,Object? limit = null,Object? provinces = null,Object? message = freezed,}) {
  return _then(_MkcloudResult(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MkcloudResultType,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String?,currentIp: freezed == currentIp ? _self.currentIp : currentIp // ignore: cast_nullable_to_non_nullable
as String?,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<MkcloudWhitelistEntry>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,provinces: null == provinces ? _self._provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<MkcloudProvince>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$MkcloudFirewallState {

 bool get isRunning; DateTime? get lastRunAt; MkcloudRunKind get lastRunKind; MkcloudResult? get result;
/// Create a copy of MkcloudFirewallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MkcloudFirewallStateCopyWith<MkcloudFirewallState> get copyWith => _$MkcloudFirewallStateCopyWithImpl<MkcloudFirewallState>(this as MkcloudFirewallState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MkcloudFirewallState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MkcloudFirewallState&&(identical(other.isRunning, _this.isRunning) || other.isRunning == _this.isRunning)&&(identical(other.lastRunAt, _this.lastRunAt) || other.lastRunAt == _this.lastRunAt)&&(identical(other.lastRunKind, _this.lastRunKind) || other.lastRunKind == _this.lastRunKind)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as MkcloudFirewallState;
  return Object.hash(runtimeType,_this.isRunning,_this.lastRunAt,_this.lastRunKind,_this.result);
}

@override
String toString() {
  final _this = this as MkcloudFirewallState;
  return 'MkcloudFirewallState(isRunning: ${_this.isRunning}, lastRunAt: ${_this.lastRunAt}, lastRunKind: ${_this.lastRunKind}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $MkcloudFirewallStateCopyWith<$Res>  {
  factory $MkcloudFirewallStateCopyWith(MkcloudFirewallState value, $Res Function(MkcloudFirewallState) _then) = _$MkcloudFirewallStateCopyWithImpl;
@useResult
$Res call({
 bool isRunning, DateTime? lastRunAt, MkcloudRunKind lastRunKind, MkcloudResult? result
});


$MkcloudResultCopyWith<$Res>? get result;

}
/// @nodoc
class _$MkcloudFirewallStateCopyWithImpl<$Res>
    implements $MkcloudFirewallStateCopyWith<$Res> {
  _$MkcloudFirewallStateCopyWithImpl(this._self, this._then);

  final MkcloudFirewallState _self;
  final $Res Function(MkcloudFirewallState) _then;

/// Create a copy of MkcloudFirewallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRunning = null,Object? lastRunAt = freezed,Object? lastRunKind = null,Object? result = freezed,}) {
  return _then(MkcloudFirewallState(
isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRunKind: null == lastRunKind ? _self.lastRunKind : lastRunKind // ignore: cast_nullable_to_non_nullable
as MkcloudRunKind,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as MkcloudResult?,
  ));
}
/// Create a copy of MkcloudFirewallState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MkcloudResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $MkcloudResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [MkcloudFirewallState].
extension MkcloudFirewallStatePatterns on MkcloudFirewallState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MkcloudFirewallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MkcloudFirewallState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MkcloudFirewallState value)  $default,){
final _that = this;
switch (_that) {
case _MkcloudFirewallState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MkcloudFirewallState value)?  $default,){
final _that = this;
switch (_that) {
case _MkcloudFirewallState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRunning,  DateTime? lastRunAt,  MkcloudRunKind lastRunKind,  MkcloudResult? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MkcloudFirewallState() when $default != null:
return $default(_that.isRunning,_that.lastRunAt,_that.lastRunKind,_that.result);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRunning,  DateTime? lastRunAt,  MkcloudRunKind lastRunKind,  MkcloudResult? result)  $default,) {final _that = this;
switch (_that) {
case _MkcloudFirewallState():
return $default(_that.isRunning,_that.lastRunAt,_that.lastRunKind,_that.result);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRunning,  DateTime? lastRunAt,  MkcloudRunKind lastRunKind,  MkcloudResult? result)?  $default,) {final _that = this;
switch (_that) {
case _MkcloudFirewallState() when $default != null:
return $default(_that.isRunning,_that.lastRunAt,_that.lastRunKind,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _MkcloudFirewallState implements MkcloudFirewallState {
  const _MkcloudFirewallState({this.isRunning = false, this.lastRunAt, this.lastRunKind = MkcloudRunKind.poll, this.result});
  

@override@JsonKey() final  bool isRunning;
@override final  DateTime? lastRunAt;
@override@JsonKey() final  MkcloudRunKind lastRunKind;
@override final  MkcloudResult? result;

/// Create a copy of MkcloudFirewallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MkcloudFirewallStateCopyWith<_MkcloudFirewallState> get copyWith => __$MkcloudFirewallStateCopyWithImpl<_MkcloudFirewallState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MkcloudFirewallState&&(identical(other.isRunning, isRunning) || other.isRunning == isRunning)&&(identical(other.lastRunAt, lastRunAt) || other.lastRunAt == lastRunAt)&&(identical(other.lastRunKind, lastRunKind) || other.lastRunKind == lastRunKind)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isRunning,lastRunAt,lastRunKind,result);
}

@override
String toString() {
    return 'MkcloudFirewallState(isRunning: $isRunning, lastRunAt: $lastRunAt, lastRunKind: $lastRunKind, result: $result)';
}


}

/// @nodoc
abstract mixin class _$MkcloudFirewallStateCopyWith<$Res> implements $MkcloudFirewallStateCopyWith<$Res> {
  factory _$MkcloudFirewallStateCopyWith(_MkcloudFirewallState value, $Res Function(_MkcloudFirewallState) _then) = __$MkcloudFirewallStateCopyWithImpl;
@override @useResult
$Res call({
 bool isRunning, DateTime? lastRunAt, MkcloudRunKind lastRunKind, MkcloudResult? result
});


@override $MkcloudResultCopyWith<$Res>? get result;

}
/// @nodoc
class __$MkcloudFirewallStateCopyWithImpl<$Res>
    implements _$MkcloudFirewallStateCopyWith<$Res> {
  __$MkcloudFirewallStateCopyWithImpl(this._self, this._then);

  final _MkcloudFirewallState _self;
  final $Res Function(_MkcloudFirewallState) _then;

/// Create a copy of MkcloudFirewallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRunning = null,Object? lastRunAt = freezed,Object? lastRunKind = null,Object? result = freezed,}) {
  return _then(_MkcloudFirewallState(
isRunning: null == isRunning ? _self.isRunning : isRunning // ignore: cast_nullable_to_non_nullable
as bool,lastRunAt: freezed == lastRunAt ? _self.lastRunAt : lastRunAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastRunKind: null == lastRunKind ? _self.lastRunKind : lastRunKind // ignore: cast_nullable_to_non_nullable
as MkcloudRunKind,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as MkcloudResult?,
  ));
}

/// Create a copy of MkcloudFirewallState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MkcloudResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $MkcloudResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
