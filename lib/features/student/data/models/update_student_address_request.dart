class UpdateStudentAddressRequest {
  final String city;
  final String district;
  final String municipality;
  final String neighborhood;
  final String address;

  const UpdateStudentAddressRequest({
    required this.city,
    required this.district,
    required this.municipality,
    required this.neighborhood,
    required this.address,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'city': city,
    'district': district,
    'municipality': municipality,
    'neighborhood': neighborhood,
    'address': address,
  };
}
