import 'package:json_annotation/json_annotation.dart';
import 'package:roombooker_core/data/entities/request.dart';

part 'booking_amendment.g.dart';

enum AmendmentScope { thisInstance, thisAndFuture }

@JsonSerializable(explicitToJson: true)
class BookingAmendment {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final Request proposedRequest;
  final PrivateRequestDetails proposedDetails;
  final AmendmentScope scope;
  final DateTime proposedAt;

  BookingAmendment({
    this.id,
    required this.proposedRequest,
    required this.proposedDetails,
    required this.scope,
    required this.proposedAt,
  });

  BookingAmendment copyWith({String? id}) {
    return BookingAmendment(
      id: id ?? this.id,
      proposedRequest: proposedRequest,
      proposedDetails: proposedDetails,
      scope: scope,
      proposedAt: proposedAt,
    );
  }

  factory BookingAmendment.fromJson(Map<String, dynamic> json) =>
      _$BookingAmendmentFromJson(json);
  Map<String, dynamic> toJson() => _$BookingAmendmentToJson(this);
}
