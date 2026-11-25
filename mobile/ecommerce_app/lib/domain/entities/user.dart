class User {
  final int uid;
  final String name;
  final String username;
  final int? partnerId;
  final String? phone;
  final String? sessionId;
  final String? accessToken;
  final bool isAuthenticated;

  const User({
    required this.uid,
    required this.name,
    required this.username,
    this.partnerId,
    this.phone,
    this.sessionId,
    this.accessToken,
    this.isAuthenticated = true,
  });

  User copyWith({
    int? uid,
    String? name,
    String? username,
    int? partnerId,
    String? phone,
    String? sessionId,
    String? accessToken,
    bool? isAuthenticated,
  }) {
    return User(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      partnerId: partnerId ?? this.partnerId,
      phone: phone ?? this.phone,
      sessionId: sessionId ?? this.sessionId,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  /// Identificador del cliente en Odoo para compras y pedidos
  int get customerId => partnerId ?? uid;
}
