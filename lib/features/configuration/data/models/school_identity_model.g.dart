// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_identity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolIdentityModel _$SchoolIdentityModelFromJson(Map<String, dynamic> json) =>
    SchoolIdentityModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      country: json['country'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      municipality: json['municipality'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      tillPhone: json['tillPhone'] as String?,
      ticketCopies: (json['ticketCopies'] as num?)?.toInt(),
      email: json['email'] as String,
    );

Map<String, dynamic> _$SchoolIdentityModelToJson(
  SchoolIdentityModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'country': instance.country,
  'city': instance.city,
  'district': instance.district,
  'municipality': instance.municipality,
  'address': instance.address,
  'phone': instance.phone,
  'tillPhone': instance.tillPhone,
  'ticketCopies': instance.ticketCopies,
  'email': instance.email,
};
