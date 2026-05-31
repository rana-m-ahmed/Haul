import 'package:json_annotation/json_annotation.dart';

part 'user_event.g.dart';

@JsonSerializable()
class UserEvent {
  final String eventId;
  final String eventName;
  final DateTime timestamp;
  final Map<String, dynamic>? payload;

  UserEvent({
    required this.eventId,
    required this.eventName,
    required this.timestamp,
    this.payload,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) => _$UserEventFromJson(json);
  Map<String, dynamic> toJson() => _$UserEventToJson(this);
}
