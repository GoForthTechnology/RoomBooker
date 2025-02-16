// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
