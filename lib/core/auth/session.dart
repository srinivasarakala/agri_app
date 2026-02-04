class Session {
  final String accessToken;
  final String refreshToken;
  final String role; // DEALER_ADMIN or SUBDEALER
  final int? subdealerId;

  Session({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.subdealerId,
  });

  bool get isAdmin => role == 'DEALER_ADMIN';
  bool get isSubdealer => role == 'SUBDEALER';
}
