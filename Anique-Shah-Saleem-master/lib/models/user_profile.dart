class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
    };
  }
}
