class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Map<String, Map<String, String>> _users = {
    'ADM001': {'password': 'ADM001', 'role': 'admin', 'name': 'Super Admin'},
    'T270206001': {
      'password': 'T270206001',
      'role': 'teacher',
      'name': 'Tina Dev',
    },
    'S150807001': {
      'password': 'S150807001',
      'role': 'student',
      'name': 'Dinda Putri',
    },
  };

  Future<String?> login(String id, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_users.containsKey(id) && _users[id]!['password'] == password) {
      return _users[id]!['role'];
    }
    return null;
  }
}
