// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatState {
  List<AppChatMessage> get messages => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isStreaming => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get currentSessionId => throw _privateConstructorUsedError;
  String get currentProvider => throw _privateConstructorUsedError;
  String get currentModel => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatStateCopyWith<ChatState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
  @useResult
  $Res call(
      {List<AppChatMessage> messages,
      bool isLoading,
      bool isStreaming,
      String? error,
      String? currentSessionId,
      String currentProvider,
      String currentModel});
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? isStreaming = null,
    Object? error = freezed,
    Object? currentSessionId = freezed,
    Object? currentProvider = null,
    Object? currentModel = null,
  }) {
    return _then(_value.copyWith(
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<AppChatMessage>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isStreaming: null == isStreaming
          ? _value.isStreaming
          : isStreaming // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      currentSessionId: freezed == currentSessionId
          ? _value.currentSessionId
          : currentSessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentProvider: null == currentProvider
          ? _value.currentProvider
          : currentProvider // ignore: cast_nullable_to_non_nullable
              as String,
      currentModel: null == currentModel
          ? _value.currentModel
          : currentModel // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatStateImplCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$$ChatStateImplCopyWith(
          _$ChatStateImpl value, $Res Function(_$ChatStateImpl) then) =
      __$$ChatStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<AppChatMessage> messages,
      bool isLoading,
      bool isStreaming,
      String? error,
      String? currentSessionId,
      String currentProvider,
      String currentModel});
}

/// @nodoc
class __$$ChatStateImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatStateImpl>
    implements _$$ChatStateImplCopyWith<$Res> {
  __$$ChatStateImplCopyWithImpl(
      _$ChatStateImpl _value, $Res Function(_$ChatStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoading = null,
    Object? isStreaming = null,
    Object? error = freezed,
    Object? currentSessionId = freezed,
    Object? currentProvider = null,
    Object? currentModel = null,
  }) {
    return _then(_$ChatStateImpl(
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<AppChatMessage>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isStreaming: null == isStreaming
          ? _value.isStreaming
          : isStreaming // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      currentSessionId: freezed == currentSessionId
          ? _value.currentSessionId
          : currentSessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentProvider: null == currentProvider
          ? _value.currentProvider
          : currentProvider // ignore: cast_nullable_to_non_nullable
              as String,
      currentModel: null == currentModel
          ? _value.currentModel
          : currentModel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatStateImpl implements _ChatState {
  const _$ChatStateImpl(
      {final List<AppChatMessage> messages = const [],
      this.isLoading = false,
      this.isStreaming = false,
      this.error,
      this.currentSessionId,
      this.currentProvider = 'gemini',
      this.currentModel = 'gemini-1.5-flash'})
      : _messages = messages;

  final List<AppChatMessage> _messages;
  @override
  @JsonKey()
  List<AppChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isStreaming;
  @override
  final String? error;
  @override
  final String? currentSessionId;
  @override
  @JsonKey()
  final String currentProvider;
  @override
  @JsonKey()
  final String currentModel;

  @override
  String toString() {
    return 'ChatState(messages: $messages, isLoading: $isLoading, isStreaming: $isStreaming, error: $error, currentSessionId: $currentSessionId, currentProvider: $currentProvider, currentModel: $currentModel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatStateImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isStreaming, isStreaming) ||
                other.isStreaming == isStreaming) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.currentSessionId, currentSessionId) ||
                other.currentSessionId == currentSessionId) &&
            (identical(other.currentProvider, currentProvider) ||
                other.currentProvider == currentProvider) &&
            (identical(other.currentModel, currentModel) ||
                other.currentModel == currentModel));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_messages),
      isLoading,
      isStreaming,
      error,
      currentSessionId,
      currentProvider,
      currentModel);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatStateImplCopyWith<_$ChatStateImpl> get copyWith =>
      __$$ChatStateImplCopyWithImpl<_$ChatStateImpl>(this, _$identity);
}

abstract class _ChatState implements ChatState {
  const factory _ChatState(
      {final List<AppChatMessage> messages,
      final bool isLoading,
      final bool isStreaming,
      final String? error,
      final String? currentSessionId,
      final String currentProvider,
      final String currentModel}) = _$ChatStateImpl;

  @override
  List<AppChatMessage> get messages;
  @override
  bool get isLoading;
  @override
  bool get isStreaming;
  @override
  String? get error;
  @override
  String? get currentSessionId;
  @override
  String get currentProvider;
  @override
  String get currentModel;
  @override
  @JsonKey(ignore: true)
  _$$ChatStateImplCopyWith<_$ChatStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SettingsState {
  String get selectedProvider => throw _privateConstructorUsedError;
  String get selectedModel => throw _privateConstructorUsedError;
  bool get streamingEnabled => throw _privateConstructorUsedError;
  bool get markdownEnabled => throw _privateConstructorUsedError;
  String get themeMode => throw _privateConstructorUsedError;
  bool get showTimestamps => throw _privateConstructorUsedError;
  String? get geminiApiKey => throw _privateConstructorUsedError;
  bool get hasGeminiKey => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SettingsStateCopyWith<SettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsStateCopyWith<$Res> {
  factory $SettingsStateCopyWith(
          SettingsState value, $Res Function(SettingsState) then) =
      _$SettingsStateCopyWithImpl<$Res, SettingsState>;
  @useResult
  $Res call(
      {String selectedProvider,
      String selectedModel,
      bool streamingEnabled,
      bool markdownEnabled,
      String themeMode,
      bool showTimestamps,
      String? geminiApiKey,
      bool hasGeminiKey});
}

/// @nodoc
class _$SettingsStateCopyWithImpl<$Res, $Val extends SettingsState>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedProvider = null,
    Object? selectedModel = null,
    Object? streamingEnabled = null,
    Object? markdownEnabled = null,
    Object? themeMode = null,
    Object? showTimestamps = null,
    Object? geminiApiKey = freezed,
    Object? hasGeminiKey = null,
  }) {
    return _then(_value.copyWith(
      selectedProvider: null == selectedProvider
          ? _value.selectedProvider
          : selectedProvider // ignore: cast_nullable_to_non_nullable
              as String,
      selectedModel: null == selectedModel
          ? _value.selectedModel
          : selectedModel // ignore: cast_nullable_to_non_nullable
              as String,
      streamingEnabled: null == streamingEnabled
          ? _value.streamingEnabled
          : streamingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      markdownEnabled: null == markdownEnabled
          ? _value.markdownEnabled
          : markdownEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      showTimestamps: null == showTimestamps
          ? _value.showTimestamps
          : showTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      geminiApiKey: freezed == geminiApiKey
          ? _value.geminiApiKey
          : geminiApiKey // ignore: cast_nullable_to_non_nullable
              as String?,
      hasGeminiKey: null == hasGeminiKey
          ? _value.hasGeminiKey
          : hasGeminiKey // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsStateImplCopyWith<$Res>
    implements $SettingsStateCopyWith<$Res> {
  factory _$$SettingsStateImplCopyWith(
          _$SettingsStateImpl value, $Res Function(_$SettingsStateImpl) then) =
      __$$SettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String selectedProvider,
      String selectedModel,
      bool streamingEnabled,
      bool markdownEnabled,
      String themeMode,
      bool showTimestamps,
      String? geminiApiKey,
      bool hasGeminiKey});
}

/// @nodoc
class __$$SettingsStateImplCopyWithImpl<$Res>
    extends _$SettingsStateCopyWithImpl<$Res, _$SettingsStateImpl>
    implements _$$SettingsStateImplCopyWith<$Res> {
  __$$SettingsStateImplCopyWithImpl(
      _$SettingsStateImpl _value, $Res Function(_$SettingsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedProvider = null,
    Object? selectedModel = null,
    Object? streamingEnabled = null,
    Object? markdownEnabled = null,
    Object? themeMode = null,
    Object? showTimestamps = null,
    Object? geminiApiKey = freezed,
    Object? hasGeminiKey = null,
  }) {
    return _then(_$SettingsStateImpl(
      selectedProvider: null == selectedProvider
          ? _value.selectedProvider
          : selectedProvider // ignore: cast_nullable_to_non_nullable
              as String,
      selectedModel: null == selectedModel
          ? _value.selectedModel
          : selectedModel // ignore: cast_nullable_to_non_nullable
              as String,
      streamingEnabled: null == streamingEnabled
          ? _value.streamingEnabled
          : streamingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      markdownEnabled: null == markdownEnabled
          ? _value.markdownEnabled
          : markdownEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
      showTimestamps: null == showTimestamps
          ? _value.showTimestamps
          : showTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      geminiApiKey: freezed == geminiApiKey
          ? _value.geminiApiKey
          : geminiApiKey // ignore: cast_nullable_to_non_nullable
              as String?,
      hasGeminiKey: null == hasGeminiKey
          ? _value.hasGeminiKey
          : hasGeminiKey // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SettingsStateImpl implements _SettingsState {
  const _$SettingsStateImpl(
      {this.selectedProvider = 'gemini',
      this.selectedModel = 'gemini-1.5-flash',
      this.streamingEnabled = true,
      this.markdownEnabled = true,
      this.themeMode = 'system',
      this.showTimestamps = false,
      this.geminiApiKey,
      this.hasGeminiKey = false});

  @override
  @JsonKey()
  final String selectedProvider;
  @override
  @JsonKey()
  final String selectedModel;
  @override
  @JsonKey()
  final bool streamingEnabled;
  @override
  @JsonKey()
  final bool markdownEnabled;
  @override
  @JsonKey()
  final String themeMode;
  @override
  @JsonKey()
  final bool showTimestamps;
  @override
  final String? geminiApiKey;
  @override
  @JsonKey()
  final bool hasGeminiKey;

  @override
  String toString() {
    return 'SettingsState(selectedProvider: $selectedProvider, selectedModel: $selectedModel, streamingEnabled: $streamingEnabled, markdownEnabled: $markdownEnabled, themeMode: $themeMode, showTimestamps: $showTimestamps, geminiApiKey: $geminiApiKey, hasGeminiKey: $hasGeminiKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsStateImpl &&
            (identical(other.selectedProvider, selectedProvider) ||
                other.selectedProvider == selectedProvider) &&
            (identical(other.selectedModel, selectedModel) ||
                other.selectedModel == selectedModel) &&
            (identical(other.streamingEnabled, streamingEnabled) ||
                other.streamingEnabled == streamingEnabled) &&
            (identical(other.markdownEnabled, markdownEnabled) ||
                other.markdownEnabled == markdownEnabled) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.showTimestamps, showTimestamps) ||
                other.showTimestamps == showTimestamps) &&
            (identical(other.geminiApiKey, geminiApiKey) ||
                other.geminiApiKey == geminiApiKey) &&
            (identical(other.hasGeminiKey, hasGeminiKey) ||
                other.hasGeminiKey == hasGeminiKey));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      selectedProvider,
      selectedModel,
      streamingEnabled,
      markdownEnabled,
      themeMode,
      showTimestamps,
      geminiApiKey,
      hasGeminiKey);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      __$$SettingsStateImplCopyWithImpl<_$SettingsStateImpl>(this, _$identity);
}

abstract class _SettingsState implements SettingsState {
  const factory _SettingsState(
      {final String selectedProvider,
      final String selectedModel,
      final bool streamingEnabled,
      final bool markdownEnabled,
      final String themeMode,
      final bool showTimestamps,
      final String? geminiApiKey,
      final bool hasGeminiKey}) = _$SettingsStateImpl;

  @override
  String get selectedProvider;
  @override
  String get selectedModel;
  @override
  bool get streamingEnabled;
  @override
  bool get markdownEnabled;
  @override
  String get themeMode;
  @override
  bool get showTimestamps;
  @override
  String? get geminiApiKey;
  @override
  bool get hasGeminiKey;
  @override
  @JsonKey(ignore: true)
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
