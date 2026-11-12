class LoginRequestModel {
  final String username;
  final String password;

  const LoginRequestModel({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponseModel {
  final bool isAuthenticated;
  final int uid;
  final String name;
  final String username;
  final int? partnerId;
  final String? sessionId;
  final String? accessToken;
  final String? message;

  const LoginResponseModel({
    required this.isAuthenticated,
    required this.uid,
    required this.name,
    required this.username,
    this.partnerId,
    this.sessionId,
    this.accessToken,
    this.message,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      uid: json['uid'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      partnerId: json['partnerId'] as int?,
      sessionId: json['sessionId'] as String?,
      accessToken: json['accessToken'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAuthenticated': isAuthenticated,
      'uid': uid,
      'name': name,
      'username': username,
      'partnerId': partnerId,
      'sessionId': sessionId,
      'accessToken': accessToken,
      'message': message,
    };
  }
}

class RegisterRequestModel {
  final String name;
  final String email;
  final String password;
  final String? phone;

  const RegisterRequestModel({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }
}

class RegisterResponseModel {
  final bool success;
  final int partnerId;
  final String name;
  final String email;
  final String? accessToken;
  final String? message;

  const RegisterResponseModel({
    required this.success,
    required this.partnerId,
    required this.name,
    required this.email,
    this.accessToken,
    this.message,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      success: json['success'] as bool? ?? false,
      partnerId: json['partnerId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accessToken: json['accessToken'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'partnerId': partnerId,
      'name': name,
      'email': email,
      'accessToken': accessToken,
      'message': message,
    };
  }
}
