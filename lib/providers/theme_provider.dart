import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';

class ThemeProvider extends ChangeNotifier {
  // Private fields
  bool _isDarkMode = false;
  int _selectedColorIndex = 0;
  ThemeData? _currentTheme;

  // Available color options
  final List<ColorOption> _availableColors = const [
    ColorOption('Blue', Colors.blue),
    ColorOption('Purple', Colors.purple),
    ColorOption('Teal', Colors.teal),
    ColorOption('Green', Colors.green),
    ColorOption('Orange', Colors.orange),
    ColorOption('Pink', Colors.pink),
    ColorOption('Red', Colors.red),
    ColorOption('Indigo', Colors.indigo),
  ];

  // Getters
  bool get isDarkMode => _isDarkMode;
  int get selectedColorIndex => _selectedColorIndex;
  List<ColorOption> get availableColors => _availableColors;
  Color get currentSeedColor => _availableColors[_selectedColorIndex].color;

  ThemeData get currentTheme {
    if (_currentTheme == null) {
      _generateTheme();
    }
    return _currentTheme!;
  }

  /// Initialize theme provider with saved preferences
  Future<void> initialize() async {
    try {
      AppLogger.info('🎨 Initializing theme provider');

      final prefs = await SharedPreferences.getInstance();

      // Load dark mode preference
      _isDarkMode = prefs.getBool(AppConstants.keyThemeMode) ?? false;

      // Load color preference
      _selectedColorIndex = prefs.getInt(AppConstants.keyThemeColor) ?? 0;

      // Validate color index
      if (_selectedColorIndex >= _availableColors.length) {
        _selectedColorIndex = 0;
      }

      // Generate theme
      _generateTheme();

      AppLogger.info(
          '✅ Theme initialized - Dark: $_isDarkMode, Color: ${_availableColors[_selectedColorIndex].name}');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Theme initialization failed: $e');

      // Fallback to defaults
      _isDarkMode = false;
      _selectedColorIndex = 0;
      _generateTheme();
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;

      // Update system UI overlay
      _updateSystemUI();

      // Save preference
      await _saveThemeMode();

      // Regenerate theme
      _generateTheme();

      AppLogger.info(
          '🌓 Theme mode toggled: ${_isDarkMode ? 'Dark' : 'Light'}');

      // Add haptic feedback
      HapticFeedback.lightImpact();

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to toggle dark mode: $e');
    }
  }

  /// Set theme color by index
  Future<void> setThemeColor(int colorIndex) async {
    try {
      if (colorIndex < 0 || colorIndex >= _availableColors.length) {
        AppLogger.warning('⚠️ Invalid color index: $colorIndex');
        return;
      }

      _selectedColorIndex = colorIndex;

      // Save preference
      await _saveThemeColor();

      // Regenerate theme
      _generateTheme();

      AppLogger.info(
          '🎨 Theme color changed to: ${_availableColors[colorIndex].name}');

      // Add haptic feedback
      HapticFeedback.selectionClick();

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to set theme color: $e');
    }
  }

  /// Set theme color by Color object
  Future<void> setThemeColorByColor(Color color) async {
    final index =
        _availableColors.indexWhere((option) => option.color == color);
    if (index != -1) {
      await setThemeColor(index);
    }
  }

  /// Generate Material 3 theme
  void _generateTheme() {
    try {
      final seedColor = _availableColors[_selectedColorIndex].color;

      if (_isDarkMode) {
        _currentTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 4,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        );
      } else {
        _currentTheme = ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 4,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        );
      }

      AppLogger.debug('🎨 Theme generated successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to generate theme: $e');
      // Fallback theme
      _currentTheme = ThemeData.light(useMaterial3: true);
    }
  }

  /// Update system UI overlay style
  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Save theme mode preference
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyThemeMode, _isDarkMode);
      AppLogger.debug('💾 Theme mode saved: $_isDarkMode');
    } catch (e) {
      AppLogger.error('❌ Failed to save theme mode: $e');
    }
  }

  /// Save theme color preference
  Future<void> _saveThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.keyThemeColor, _selectedColorIndex);
      AppLogger.debug('💾 Theme color saved: $_selectedColorIndex');
    } catch (e) {
      AppLogger.error('❌ Failed to save theme color: $e');
    }
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    try {
      _isDarkMode = false;
      _selectedColorIndex = 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyThemeMode);
      await prefs.remove(AppConstants.keyThemeColor);

      _generateTheme();
      _updateSystemUI();

      AppLogger.info('🔄 Theme reset to default');

      notifyListeners();
    } catch (e) {
      AppLogger.error('❌ Failed to reset theme: $e');
    }
  }

  /// Get theme mode name for display
  String get themeModeDisplayName {
    return _isDarkMode ? 'Dark Mode' : 'Light Mode';
  }

  /// Get current color name for display
  String get currentColorDisplayName {
    return _availableColors[_selectedColorIndex].name;
  }
}

/// Color option data class
class ColorOption {
  final String name;
  final Color color;

  const ColorOption(this.name, this.color);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorOption && other.name == name && other.color == color;
  }

  @override
  int get hashCode => name.hashCode ^ color.hashCode;

  @override
  String toString() => 'ColorOption($name, $color)';
}
