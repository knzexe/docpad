import 'dart:convert';

/// Terminology Registry basic-auth login. The password stays in the
/// platform secure store and is never written to preferences or logs.
class TrCredentials {
  const TrCredentials({this.username = '', this.password = ''});

  final String username;
  final String password;

  bool get canAuthenticate => username.trim().isNotEmpty && password.isNotEmpty;

  String? get authorizationHeader {
    if (!canAuthenticate) return null;
    final token = base64Encode(utf8.encode('${username.trim()}:$password'));
    return 'Basic $token';
  }
}
