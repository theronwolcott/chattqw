class User {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  // The password is optional on the client side.
  // When creating a user, you might include it so the server can hash it.
  // After a login, the server should omit the password.
  final String? password;

  User({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.password,
    required this.createdAt,
  });

  /// Creates a [User] instance from a JSON map.
  /// If the JSON doesn't include a password or it's empty,
  /// the [password] property will be null.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      password: (json['password'] is String &&
              (json['password'] as String).isNotEmpty)
          ? json['password'] as String
          : null,
    );
  }

  /// Converts the [User] instance into a JSON map.
  ///
  /// The [includePassword] flag allows you to control whether the password
  /// should be included in the output JSON.
  /// - When creating a user, set [includePassword] to true so that the server
  ///   receives the password to hash and store.
  /// - When retrieving a user (e.g., via a GET endpoint), the server shouldn't
  ///   send a password back, so you would call `toJson(includePassword: false)`.
  Map<String, dynamic> toJson({bool includePassword = false}) {
    final Map<String, dynamic> data = {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt.toIso8601String(),
    };
    if (includePassword && password != null) {
      data['password'] = password;
    }
    return data;
  }
}
