class User {
  final int uid;
  final String name;
  final String username;
  final int? partnerId;
  final String? sessionId;
  final String? accessToken;
  final bool isAuthenticated;

  const User({
    required this.uid,
    required this.name,
    required this.username,
    this.partnerId,
    this.sessionId,
    this.accessToken,
    this.isAuthenticated = true,
  });

  /// Identificador del cliente en Odoo para compras y pedidos
  int get customerId => partnerId ?? uid;
}
