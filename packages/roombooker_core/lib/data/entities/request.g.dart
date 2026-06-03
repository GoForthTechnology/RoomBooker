// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateRequestDetails _$PrivateRequestDetailsFromJson(
  Map<String, dynamic> json,
) => PrivateRequestDetails(
  message: json['message'] as String? ?? "",
  eventName: json['eventName'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
);

Map<String, dynamic> _$PrivateRequestDetailsToJson(
  PrivateRequestDetails instance,
) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'message': instance.message,
  'eventName': instance.eventName,
};

Request _$RequestFromJson(Map<String, dynamic> json) => Request(
  recurrancePattern: json['recurrancePattern'] == null
      ? null
      : RecurrancePattern.fromJson(
          json['recurrancePattern'] as Map<String, dynamic>,
        ),
  eventStartTime: DateTime.parse(json['eventStartTime'] as String),
  eventEndTime: DateTime.parse(json['eventEndTime'] as String),
  roomID: json['roomID'] as String,
  roomName: json['roomName'] as String,
  publicName: json['publicName'] as String?,
  recurranceOverrides: (json['recurranceOverrides'] as Map<String, dynamic>?)
      ?.map(
        (k, e) => MapEntry(
          DateTime.parse(k),
          e == null ? null : Request.fromJson(e as Map<String, dynamic>),
        ),
      ),
  ignoreOverlaps: json['ignoreOverlaps'] as bool? ?? false,
);

Map<String, dynamic> _$RequestToJson(Request instance) => <String, dynamic>{
  'publicName': instance.publicName,
  'eventStartTime': instance.eventStartTime.toIso8601String(),
  'eventEndTime': instance.eventEndTime.toIso8601String(),
  'roomID': instance.roomID,
  'roomName': instance.roomName,
  'recurrancePattern': instance.recurrancePattern?.toJson(),
  'recurranceOverrides': instance.recurranceOverrides?.map(
    (k, e) => MapEntry(k.toIso8601String(), e?.toJson()),
  ),
  'ignoreOverlaps': instance.ignoreOverlaps,
};

RecurrancePattern _$RecurrancePatternFromJson(Map<String, dynamic> json) =>
    RecurrancePattern(
      frequency: $enumDecode(_$FrequencyEnumMap, json['frequency']),
      period: (json['period'] as num).toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      weekday: (json['weekday'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$WeekdayEnumMap, e))
          .toSet(),
      end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
    );

Map<String, dynamic> _$RecurrancePatternToJson(RecurrancePattern instance) =>
    <String, dynamic>{
      'frequency': _$FrequencyEnumMap[instance.frequency]!,
      'period': instance.period,
      'offset': instance.offset,
      'weekday': instance.weekday?.map((e) => _$WeekdayEnumMap[e]!).toList(),
      'end': instance.end?.toIso8601String(),
    };

const _$FrequencyEnumMap = {
  Frequency.never: 'never',
  Frequency.daily: 'daily',
  Frequency.weekly: 'weekly',
  Frequency.monthly: 'monthly',
  Frequency.annually: 'annually',
  Frequency.custom: 'custom',
};

const _$WeekdayEnumMap = {
  Weekday.sunday: 'sunday',
  Weekday.monday: 'monday',
  Weekday.tuesday: 'tuesday',
  Weekday.wednesday: 'wednesday',
  Weekday.thursday: 'thursday',
  Weekday.friday: 'friday',
  Weekday.saturday: 'saturday',
};
