class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? parentId;
  final String? zone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.parentId,
    this.zone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      parentId: json['parent_id'],
      zone: json['zone'],
    );
  }
}
