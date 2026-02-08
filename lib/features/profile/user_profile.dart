class UserProfile {
  final int id;
  final String? firstName;
  final String? lastName;
  final String phone;
  final String role;
  final int? subdealerId;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;

  UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    required this.phone,
    required this.role,
    this.subdealerId,
    this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        phone: json['phone'] as String,
        role: json['role'] as String,
        subdealerId: json['subdealer_id'] as int?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
      };

  String get fullName {
    final parts = [
      if (firstName != null && firstName!.isNotEmpty) firstName,
      if (lastName != null && lastName!.isNotEmpty) lastName,
    ];
    return parts.isEmpty ? 'User' : parts.join(' ');
  }

  String get fullAddress {
    final parts = [
      if (address != null && address!.isNotEmpty) address,
      if (city != null && city!.isNotEmpty) city,
      if (state != null && state!.isNotEmpty) state,
      if (pincode != null && pincode!.isNotEmpty) pincode,
    ];
    return parts.isEmpty ? 'No address provided' : parts.join(', ');
  }
}
