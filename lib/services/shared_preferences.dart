import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceProvider {
  SharedPreferenceProvider._();

  SharedPreferences _preferences;
  SharedPreferences get preferences => _preferences;

  static final SharedPreferenceProvider _instance =
      SharedPreferenceProvider._();
  static Future<SharedPreferenceProvider> getInstance() async {
    _instance._preferences ??= await SharedPreferences.getInstance();

    return _instance;
  }
}

extension Custom on SharedPreferences {
  increaseInt(String key) {
    final n = getInt(key);
    setInt(key, n + 1);
  }

  decreaseInt(String key) {
    final n = getInt(key);
    setInt(key, n - 1);
  }
}
