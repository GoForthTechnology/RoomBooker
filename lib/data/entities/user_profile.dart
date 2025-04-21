import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfile {
  final List<String> orgIDs;

  UserProfile({required this.orgIDs});

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
