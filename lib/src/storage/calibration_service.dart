import 'package:shared_preferences/shared_preferences.dart';

class CalibrationService {
  static const String calibrationKey = 'heading_offset';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<double> loadCalibration() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs?.getDouble(calibrationKey) ?? 0.0;
  }

  Future<void> saveCalibration(double value) async {
    if (_prefs == null) {
      await init();
    }
    await _prefs?.setDouble(calibrationKey, value);
  }

  Future<void> close() async {
    // SharedPreferences no necesita ser cerrado
    // Este método se mantiene por compatibilidad
  }
}
