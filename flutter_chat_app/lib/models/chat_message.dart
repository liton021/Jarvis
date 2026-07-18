import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class AppChatMessage with _$AppChatMessage {
  const factory AppChatMessage({
    required String id,
    required String text,
    required String senderId,
    required DateTime timestamp,
    @Default(false) bool isStreaming,
    Map<String, dynamic>? metadata,
  }) = _AppChatMessage;

  factory AppChatMessage.fromJson(Map<String, dynamic> json) =>
      _$AppChatMessageFromJson(json);
}