// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppChatMessage _$AppChatMessageFromJson(Map<String, dynamic> json) {
  return _AppChatMessage.fromJson(json);
}

/// @nodoc
mixin _$AppChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isStreaming => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppChatMessageCopyWith<AppChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppChatMessageCopyWith<$Res> {
  factory $AppChatMessageCopyWith(
          AppChatMessage value, $Res Function(AppChatMessage) then) =
      _$AppChatMessageCopyWithImpl<$Res, AppChatMessage>;
  @useResult
  $Res call(
      {String id,
      String text,
      String senderId,
      DateTime timestamp,
      bool isStreaming,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$AppChatMessageCopyWithImpl<$Res, $Val extends AppChatMessage>
    implements $AppChatMessageCopyWith<$Res> {
  _$AppChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? senderId = null,
    Object? timestamp = null,
    Object? isStreaming = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isStreaming: null == isStreaming
          ? _value.isStreaming
          : isStreaming // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppChatMessageImplCopyWith<$Res>
    implements $AppChatMessageCopyWith<$Res> {
  factory _$$AppChatMessageImplCopyWith(_$AppChatMessageImpl value,
          $Res Function(_$AppChatMessageImpl) then) =
      __$$AppChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String text,
      String senderId,
      DateTime timestamp,
      bool isStreaming,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$AppChatMessageImplCopyWithImpl<$Res>
    extends _$AppChatMessageCopyWithImpl<$Res, _$AppChatMessageImpl>
    implements _$$AppChatMessageImplCopyWith<$Res> {
  __$$AppChatMessageImplCopyWithImpl(
      _$AppChatMessageImpl _value, $Res Function(_$AppChatMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? senderId = null,
    Object? timestamp = null,
    Object? isStreaming = null,
    Object? metadata = freezed,
  }) {
    return _then(_$AppChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isStreaming: null == isStreaming
          ? _value.isStreaming
          : isStreaming // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppChatMessageImpl implements _AppChatMessage {
  const _$AppChatMessageImpl(
      {required this.id,
      required this.text,
      required this.senderId,
      required this.timestamp,
      this.isStreaming = false,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$AppChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  final String senderId;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isStreaming;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AppChatMessage(id: $id, text: $text, senderId: $senderId, timestamp: $timestamp, isStreaming: $isStreaming, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isStreaming, isStreaming) ||
                other.isStreaming == isStreaming) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, text, senderId, timestamp,
      isStreaming, const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppChatMessageImplCopyWith<_$AppChatMessageImpl> get copyWith =>
      __$$AppChatMessageImplCopyWithImpl<_$AppChatMessageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppChatMessageImplToJson(
      this,
    );
  }
}

abstract class _AppChatMessage implements AppChatMessage {
  const factory _AppChatMessage(
      {required final String id,
      required final String text,
      required final String senderId,
      required final DateTime timestamp,
      final bool isStreaming,
      final Map<String, dynamic>? metadata}) = _$AppChatMessageImpl;

  factory _AppChatMessage.fromJson(Map<String, dynamic> json) =
      _$AppChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  String get senderId;
  @override
  DateTime get timestamp;
  @override
  bool get isStreaming;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$AppChatMessageImplCopyWith<_$AppChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
