// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_amendment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingAmendment _$BookingAmendmentFromJson(Map<String, dynamic> json) =>
    BookingAmendment(
      proposedRequest: Request.fromJson(
        json['proposedRequest'] as Map<String, dynamic>,
      ),
      proposedDetails: PrivateRequestDetails.fromJson(
        json['proposedDetails'] as Map<String, dynamic>,
      ),
      scope: $enumDecode(_$AmendmentScopeEnumMap, json['scope']),
      proposedAt: DateTime.parse(json['proposedAt'] as String),
      instanceStartDate: json['instanceStartDate'] == null
          ? null
          : DateTime.parse(json['instanceStartDate'] as String),
    );

Map<String, dynamic> _$BookingAmendmentToJson(BookingAmendment instance) =>
    <String, dynamic>{
      'proposedRequest': instance.proposedRequest.toJson(),
      'proposedDetails': instance.proposedDetails.toJson(),
      'scope': _$AmendmentScopeEnumMap[instance.scope]!,
      'proposedAt': instance.proposedAt.toIso8601String(),
      'instanceStartDate': instance.instanceStartDate?.toIso8601String(),
    };

const _$AmendmentScopeEnumMap = {
  AmendmentScope.thisInstance: 'thisInstance',
  AmendmentScope.thisAndFuture: 'thisAndFuture',
};
