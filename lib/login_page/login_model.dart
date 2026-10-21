/// Data model for mobile login request.
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

/// User details returned in the login response.
class UserModel {
  final int id;
  final String username;
  final int roleId;
  final String role;
  final int? userTypeId;
  final String? userType;
  final String name;
  final String? email;
  final String? phone;
  final int? stateId;
  final String? stateName;
  final int? districtId;
  final String? districtName;
  final String? districtCode;
  final String? address;
  final int? isActive;
  final String? lastLoginAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.roleId,
    required this.role,
    this.userTypeId,
    this.userType,
    required this.name,
    this.email,
    this.phone,
    this.stateId,
    this.stateName,
    this.districtId,
    this.districtName,
    this.districtCode,
    this.address,
    this.isActive,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      roleId: json['roleId'] is int
          ? json['roleId'] as int
          : json['role_id'] is int
          ? json['role_id'] as int
          : int.tryParse(
                  json['roleId']?.toString() ??
                      json['role_id']?.toString() ??
                      '',
                ) ??
                0,
      role: json['role']?.toString() ?? '',
      userTypeId: json['userTypeId'] as int?,
      userType: json['userType']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      stateId: json['stateId'] as int?,
      stateName: json['stateName']?.toString(),
      districtId: json['districtId'] as int?,
      districtName: json['districtName']?.toString(),
      districtCode: json['districtCode']?.toString(),
      address: json['address']?.toString(),
      isActive: json['isActive'] as int?,
      lastLoginAt: json['lastLoginAt']?.toString(),
    );
  }

  /// Role 2 represents Coordinator (formerly Super Admin).
  bool get isCoordinator => roleId == 2;
  bool get isSuperAdmin => isCoordinator;

  /// Role 3 represents Branch Manager (formerly Admin).
  bool get isBranchManager => roleId == 3;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'roleId': roleId,
        'role': role,
        'userTypeId': userTypeId,
        'userType': userType,
        'name': name,
        'email': email,
        'phone': phone,
        'stateId': stateId,
        'stateName': stateName,
        'districtId': districtId,
        'districtName': districtName,
        'districtCode': districtCode,
        'address': address,
        'isActive': isActive,
        'lastLoginAt': lastLoginAt,
      };
}

/// Result of authentication returned by LoginViewModel.
class LoginResult {
  final bool isSuccess;
  final String? token;
  final UserModel? user;
  final bool isCoordinator;
  bool get isSuperAdmin => isCoordinator;
  final String? errorMessage;

  const LoginResult({
    required this.isSuccess,
    this.token,
    this.user,
    this.isCoordinator = false,
    this.errorMessage,
  });

  factory LoginResult.success({
    required String? token,
    required UserModel? user,
    required bool isCoordinator,
  }) {
    return LoginResult(
      isSuccess: true,
      token: token,
      user: user,
      isCoordinator: isCoordinator,
    );
  }

  factory LoginResult.failure(String message) {
    return LoginResult(isSuccess: false, errorMessage: message);
  }
}
