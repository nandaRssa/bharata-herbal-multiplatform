class Address {
  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String province;
  final String postalCode;
  final String fullAddress;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.fullAddress,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      label: json['label'] ?? 'Alamat',
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      fullAddress: json['full_address'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }
}
