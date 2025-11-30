class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Map<String, Map<String, String>> _users = {};

  Future<String?> login(String id, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_users.containsKey(id) && _users[id]!['password'] == password) {
      return _users[id]!['role'];
    }
    return null;
  }
}
