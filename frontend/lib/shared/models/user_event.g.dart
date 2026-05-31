// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserEvent _$UserEventFromJson(Map<String, dynamic> json) => UserEvent(
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: json['payload'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserEventToJson(UserEvent instance) => <String, dynamic>{
      'eventId': instance.eventId,
      'eventName': instance.eventName,
      'timestamp': instance.timestamp.toIso8601String(),
      'payload': instance.payload,
    };
