import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_service.dart';
import 'database/diet_record_repository.dart';
import 'database/food_template_repository.dart';
import 'database/meal_food_record_repository.dart';
import 'database/training_record_repository.dart';
import 'models/diet_record.dart';
import 'models/food_template.dart';
import 'models/food_unit_type.dart';
import 'models/meal_food_record.dart';
import 'models/training_record.dart';
import 'models/user_profile.dart';
import 'services/nutrition_target_calculator.dart';
import 'storage/auth_session_store.dart';
import 'storage/avatar_file_store.dart';
import 'storage/local_auth_store.dart';
import 'storage/user_profile_store.dart';

const Color _sunOrange = Color(0xFFFF8F00);
const Color _sunOrangeDeep = Color(0xFFE66F00);
const Color _sunIvory = Color(0xFFFFFDF5);
const Color _sunLemon = Color(0xFFFFC947);
const Color _sunCoral = Color(0xFFFF6F61);
const Color _sunApricot = Color(0xFFFFD48A);
const Color _sunWarmGrey = Color(0xFFEEDFCB);
const Color _sunInk = Color(0xFF3A2A1A);
const BorderRadius _sunnyCardRadius = BorderRadius.all(Radius.circular(32));
const BorderRadius _sunnyPillRadius = BorderRadius.all(Radius.circular(999));

List<BoxShadow> _sunnyShadow([Color tint = _sunOrange]) {
  return <BoxShadow>[
    BoxShadow(
      color: tint.withValues(alpha: 0.20),
      blurRadius: 30,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: tint.withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}

BoxDecoration _sunnySurfaceDecoration(
  BuildContext context, {
  Color? color,
  Gradient? gradient,
  BorderRadius borderRadius = _sunnyCardRadius,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: gradient == null ? (color ?? _sunIvory) : null,
    gradient: gradient,
    borderRadius: borderRadius,
    border: Border.all(
      color: colorScheme.outlineVariant.withValues(alpha: 0.28),
    ),
    boxShadow: _sunnyShadow(),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _sunOrange,
          brightness: Brightness.light,
        ).copyWith(
          primary: _sunOrange,
          onPrimary: Colors.white,
          secondary: _sunLemon,
          onSecondary: const Color(0xFF473000),
          tertiary: _sunCoral,
          onTertiary: Colors.white,
          surface: _sunIvory,
          onSurface: _sunInk,
          surfaceContainer: const Color(0xFFFFF5E1),
          surfaceContainerHigh: const Color(0xFFFFEBC4),
          surfaceContainerHighest: const Color(0xFFFFDF9D),
          outline: const Color(0xFFE3CDAE),
          outlineVariant: _sunWarmGrey,
        );

    return MaterialApp(
      title: '\u5065\u8eab\u8bb0\u5f55',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: _sunIvory,
        canvasColor: _sunIvory,
        shadowColor: _sunOrange.withValues(alpha: 0.14),
        textTheme: ThemeData(
          brightness: Brightness.light,
        ).textTheme.apply(bodyColor: _sunInk, displayColor: _sunInk),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: _sunInk,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: _sunIvory,
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: _sunnyCardRadius),
          shadowColor: _sunOrange.withValues(alpha: 0.12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _sunOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _sunInk,
            side: BorderSide(color: colorScheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: const StadiumBorder(),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.88),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: _sunOrange, width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _sunIvory.withValues(alpha: 0.94),
          surfaceTintColor: Colors.transparent,
          indicatorColor: _sunOrange.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? _sunOrangeDeep : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? _sunOrangeDeep : colorScheme.onSurfaceVariant,
            );
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _sunOrange,
          linearTrackColor: Color(0xFFFFE4B8),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authStore = const LocalAuthStore()});

  final LocalAuthStore authStore;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isCheckingSession = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final userId = await widget.authStore.loadCurrentUserId();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSignedIn = userId != null && userId.isNotEmpty;
      _isCheckingSession = false;
    });
  }

  void _enterApp() {
    setState(() {
      _isSignedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isSignedIn) {
      return const HomePage();
    }

    return AuthPage(authStore: widget.authStore, onAuthenticated: _enterApp);
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.authStore,
    required this.onAuthenticated,
  });

  final LocalAuthStore authStore;
  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      if (_isRegisterMode) {
        final shouldAskMigration = await widget.authStore
            .hasMigratableGuestData();
        final user = await widget.authStore.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) {
          return;
        }
        if (shouldAskMigration) {
          final shouldMigrate = await _showGuestMigrationDialog();
          if (shouldMigrate) {
            await widget.authStore.migrateGuestDataToUser(user.userId);
          }
        }
      } else {
        await widget.authStore.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
      }

      if (mounted) {
        widget.onAuthenticated();
      }
    } on LocalAuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorText = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = '操作失败，请稍后重试';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool> _showGuestMigrationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('迁移游客数据'),
          content: const Text('检测到您之前有使用过本 App，是否将现有数据迁移到新账号？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('否'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('是'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _continueAsGuest() async {
    await widget.authStore.continueAsGuest();
    if (mounted) {
      widget.onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRegisterMode ? '注册账号' : '登录账号';
    final actionText = _isRegisterMode ? '注册并进入' : '登录';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: _sunnySurfaceDecoration(context, color: _sunIvory),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      _AuthTextField(
                        controller: _usernameController,
                        labelText: '账号',
                        icon: Icons.person_outline_rounded,
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 12),
                        _AuthTextField(
                          controller: _emailController,
                          labelText: '邮箱',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _AuthTextField(
                        controller: _passwordController,
                        labelText: '密码',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(actionText),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : _continueAsGuest,
                        child: const Text('游客体验'),
                      ),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _errorText = null;
                                });
                              },
                        child: Text(_isRegisterMode ? '已有账号？去登录' : '没有账号？去注册'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class WeightEntry {
  const WeightEntry({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String(), 'weightKg': weightKg};
  }

  static WeightEntry? fromMap(dynamic map) {
    if (map is! Map) {
      return null;
    }

    final rawDate = map['date'];
    final rawWeight = map['weightKg'];
    final parsedDate = DateTime.tryParse(rawDate?.toString() ?? '');
    final parsedWeight = rawWeight is num
        ? rawWeight.toDouble()
        : double.tryParse(rawWeight?.toString() ?? '');

    if (parsedDate == null || parsedWeight == null || parsedWeight <= 0) {
      return null;
    }

    return WeightEntry(date: parsedDate, weightKg: parsedWeight);
  }
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _formatDateLabel(DateTime selectedDate) {
  final today = _normalizeDate(DateTime.now());
  final normalized = _normalizeDate(selectedDate);

  if (DateUtils.isSameDay(normalized, today)) {
    return '\u4eca\u5929';
  }
  if (normalized.year == today.year) {
    return DateFormat('M/d').format(normalized);
  }
  return DateFormat('yyyy/M/d').format(normalized);
}

DateTime _monthStart(DateTime value) {
  return DateTime(value.year, value.month);
}

bool _isSameYearMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

String _formatWeightMonthLabel(DateTime month, {bool includeYear = false}) {
  return includeYear
      ? DateFormat('yyyy年M月').format(month)
      : DateFormat('M月').format(month);
}

String _formatAmountText(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.0001) {
    return rounded.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

double _sanitizeNonNegativeValue(double value) {
  if (!value.isFinite || value < 0) {
    return 0;
  }
  return value;
}

double _mealFoodAmountMultiplier(FoodUnitType unitType, double amount) {
  return unitType == FoodUnitType.per100g ? amount / 100 : amount;
}

void _showCenteredFloatingMessage(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) {
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CenteredFloatingMessage(
      message: message,
      onDismissed: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _MacroProgressData {
  const _MacroProgressData({
    required this.label,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.color,
  });

  final String label;
  final double currentValue;
  final double targetValue;
  final String unit;
  final Color color;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _targetWeightKey = 'home_target_weight_kg';
  static const String _weightEntriesKey = 'home_weight_entries';

  final UserProfileStore _userProfileStore =
      SharedPreferencesUserProfileStore.instance;
  int _currentIndex = 0;
  double? _targetWeightKg;
  double _todayCalories = 0;
  double _todayCarbs = 0;
  double _todayProtein = 0;
  double _todayFat = 0;
  String? _overviewError;
  final List<WeightEntry> _weightEntries = <WeightEntry>[];
  DateTime? _selectedWeightMonth;
  UserProfile _userProfile = const UserProfile();

  NutritionTargetState get _nutritionTargetState => buildNutritionTargetState(
    weightKg: _targetWeightKg,
    profile: _userProfile,
  );

  @override
  void initState() {
    super.initState();
    _loadPersistedWeightData();
    _loadUserProfile();
    _refreshOverview();
  }

  Future<String> _scopedPreferenceKey(String key) async {
    final userId = await AuthSessionStore.effectiveUserId();
    return AuthSessionStore.scopedKey(userId, key);
  }

  Future<void> _loadPersistedWeightData() async {
    final preferences = await SharedPreferences.getInstance();
    final targetWeightKey = await _scopedPreferenceKey(_targetWeightKey);
    final weightEntriesKey = await _scopedPreferenceKey(_weightEntriesKey);

    double? targetWeight;
    final storedTargetWeight = preferences.getDouble(targetWeightKey);
    if (storedTargetWeight != null && storedTargetWeight > 0) {
      targetWeight = storedTargetWeight;
    } else {
      final rawTargetWeight = preferences.getString(targetWeightKey);
      final parsedTargetWeight = double.tryParse(rawTargetWeight ?? '');
      if (parsedTargetWeight != null && parsedTargetWeight > 0) {
        targetWeight = parsedTargetWeight;
      }
    }

    var loadedEntries = <WeightEntry>[];
    final rawEntries = preferences.getString(weightEntriesKey);
    if (rawEntries != null && rawEntries.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEntries);
        if (decoded is List) {
          loadedEntries =
              decoded.map(WeightEntry.fromMap).whereType<WeightEntry>().toList()
                ..sort((a, b) => a.date.compareTo(b.date));
        }
      } catch (_) {
        await preferences.remove(weightEntriesKey);
        loadedEntries = <WeightEntry>[];
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _weightEntries
        ..clear()
        ..addAll(loadedEntries);
      _selectedWeightMonth = _resolveSelectedWeightMonth(_selectedWeightMonth);

      if (targetWeight != null) {
        _targetWeightKg = targetWeight;
      } else {
        _targetWeightKg = null;
      }
    });
  }

  Future<void> _persistWeightData() async {
    final preferences = await SharedPreferences.getInstance();
    final targetWeightKey = await _scopedPreferenceKey(_targetWeightKey);
    final weightEntriesKey = await _scopedPreferenceKey(_weightEntriesKey);

    if (_targetWeightKg != null && _targetWeightKg! > 0) {
      await preferences.setDouble(targetWeightKey, _targetWeightKg!);
    } else {
      await preferences.remove(targetWeightKey);
    }

    final serializedEntries = jsonEncode(
      _weightEntries.map((entry) => entry.toMap()).toList(),
    );
    await preferences.setString(weightEntriesKey, serializedEntries);
  }

  List<DateTime> _collectRecordedWeightMonths() {
    final monthsByKey = <String, DateTime>{};
    for (final entry in _weightEntries) {
      final month = _monthStart(entry.date);
      monthsByKey['${month.year}-${month.month}'] = month;
    }

    final months = monthsByKey.values.toList()..sort((a, b) => b.compareTo(a));
    return months;
  }

  DateTime? _resolveSelectedWeightMonth([DateTime? preferredMonth]) {
    final recordedMonths = _collectRecordedWeightMonths();
    if (recordedMonths.isEmpty) {
      return null;
    }

    if (preferredMonth != null) {
      final normalizedPreferred = _monthStart(preferredMonth);
      for (final month in recordedMonths) {
        if (_isSameYearMonth(month, normalizedPreferred)) {
          return month;
        }
      }
    }

    return recordedMonths.first;
  }

  List<WeightEntry> _entriesForMonth(DateTime month) {
    return _weightEntries
        .where((entry) => _isSameYearMonth(entry.date, month))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userProfileStore.loadProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _userProfile = profile;
    });
  }

  Future<void> _refreshOverview() async {
    try {
      final today = DatabaseService.getTodayDateString();
      final totalCalories = await DatabaseService.getTotalCaloriesByDate(today);
      final mealRecords = await DatabaseService.getMealFoodRecordsByDate(today);
      final totalCarbs = mealRecords.fold<double>(
        0,
        (sum, record) => sum + record.actualCarbs,
      );
      final totalProtein = mealRecords.fold<double>(
        0,
        (sum, record) => sum + record.actualProtein,
      );
      final totalFat = mealRecords.fold<double>(
        0,
        (sum, record) => sum + record.actualFat,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _todayCalories = _sanitizeNonNegativeValue(totalCalories);
        _todayCarbs = _sanitizeNonNegativeValue(totalCarbs);
        _todayProtein = _sanitizeNonNegativeValue(totalProtein);
        _todayFat = _sanitizeNonNegativeValue(totalFat);
        _overviewError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _todayCalories = 0;
        _todayCarbs = 0;
        _todayProtein = 0;
        _todayFat = 0;
        _overviewError =
            '\u52a0\u8f7d\u4eca\u65e5\u70ed\u91cf\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
      });
    }
  }

  void _setTargetsFromWeight(double weightKg) {
    setState(() {
      _targetWeightKg = weightKg;
    });
    _persistWeightData();
  }

  void _addWeightEntry(double weightKg) {
    final now = DateTime.now();
    setState(() {
      _weightEntries.removeWhere(
        (entry) =>
            entry.date.year == now.year &&
            entry.date.month == now.month &&
            entry.date.day == now.day,
      );
      _weightEntries.add(WeightEntry(date: now, weightKg: weightKg));
      _weightEntries.sort((a, b) => a.date.compareTo(b.date));
      _selectedWeightMonth = _monthStart(now);
    });
    _persistWeightData();
  }

  void _showWeightDialog({
    required String title,
    required ValueChanged<double> onConfirmed,
    double? initialValue,
  }) {
    final controller = TextEditingController(
      text: initialValue == null ? '' : initialValue.toStringAsFixed(1),
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '\u4f53\u91cd\uff08kg\uff09',
              hintText: '\u4f8b\u5982 70.5',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('\u53d6\u6d88'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u4f53\u91cd',
                      ),
                    ),
                  );
                  return;
                }
                onConfirmed(value);
                Navigator.of(context).pop();
              },
              child: const Text('\u4fdd\u5b58'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewPage() {
    final nutritionState = _nutritionTargetState;
    final targets = nutritionState.targets;
    final totalTargetCalories = nutritionState.targetCalories;
    final remainingCalories = totalTargetCalories == null
        ? null
        : math.max(0.0, totalTargetCalories - _todayCalories);
    final availableWeightMonths = _collectRecordedWeightMonths();
    final hasMultipleWeightYears =
        availableWeightMonths.map((month) => month.year).toSet().length > 1;
    final selectedWeightMonth = _resolveSelectedWeightMonth(
      _selectedWeightMonth,
    );
    final selectedWeightEntries = selectedWeightMonth == null
        ? <WeightEntry>[]
        : _entriesForMonth(selectedWeightMonth);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[_sunOrange, _sunApricot],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshOverview,
          color: _sunOrangeDeep,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _OverviewHeroCard(
                consumedCalories: _todayCalories,
                targetCalories: totalTargetCalories,
                remainingCalories: remainingCalories,
                subtitle: nutritionState.isReady
                    ? '\u5f53\u524d\u6309 ${_formatAmountText(nutritionState.weightKg!)} kg \u4e0e\u4e2a\u4eba\u4fe1\u606f\u8ba1\u7b97\u8425\u517b\u76ee\u6807'
                    : nutritionState.incompleteMessage,
                errorText: _overviewError,
              ),
              const SizedBox(height: 14),
              _DashboardMacroRow(
                targets: targets,
                targetCalories: totalTargetCalories,
                incompleteMessage: nutritionState.incompleteMessage,
                currentCarbs: _todayCarbs,
                currentProtein: _todayProtein,
                currentFat: _todayFat,
              ),
              const SizedBox(height: 14),
              _QuickSetupBar(
                targetWeightKg: _targetWeightKg,
                profileSummary: _userProfile.personalInfoSummary,
                remainingCalories: remainingCalories,
                onSetWeight: () => _showWeightDialog(
                  title:
                      '\u8bbe\u7f6e\u7528\u4e8e\u996e\u98df\u8ba1\u7b97\u7684\u4f53\u91cd',
                  initialValue: _targetWeightKg,
                  onConfirmed: _setTargetsFromWeight,
                ),
                onOpenProfile: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
              ),
              const SizedBox(height: 14),
              _WeightRecordDashboardCard(
                entries: _weightEntries,
                selectedEntries: selectedWeightEntries,
                availableMonths: availableWeightMonths,
                selectedMonth: selectedWeightMonth,
                hasMultipleYears: hasMultipleWeightYears,
                onMonthChanged: (value) {
                  setState(() {
                    _selectedWeightMonth = value;
                  });
                },
                onAddRecord: () => _showWeightDialog(
                  title: '\u8bb0\u5f55\u4eca\u65e5\u4f53\u91cd',
                  onConfirmed: _addWeightEntry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildOverviewPage(),
      AutoMealDietPage(
        onRecordsChanged: _refreshOverview,
        nutritionTargetState: _nutritionTargetState,
      ),
      const TrainingPage(),
      ProfilePage(
        initialProfile: _userProfile,
        onProfileChanged: (profile) {
          setState(() {
            _userProfile = profile;
          });
        },
      ),
    ];

    const titles = <String>[
      'My Fitness',
      '\u996E\u98DF',
      '\u8BAD\u7EC3',
      '\u6211\u7684',
    ];

    final showCustomPageChrome =
        _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2;

    return Scaffold(
      appBar: showCustomPageChrome
          ? null
          : AppBar(title: Text(titles[_currentIndex])),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _refreshOverview();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: '\u603b\u89c8',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            label: '\u996e\u98df',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: '\u8bad\u7ec3',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: '\u6211\u7684',
          ),
        ],
      ),
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  const _OverviewHeroCard({
    required this.consumedCalories,
    required this.targetCalories,
    required this.remainingCalories,
    required this.subtitle,
    this.errorText,
  });

  final double consumedCalories;
  final double? targetCalories;
  final double? remainingCalories;
  final String subtitle;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _sunIvory,
        borderRadius: BorderRadius.circular(36),
        boxShadow: _sunnyShadow(_sunOrange),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: _sunnyPillRadius,
                        ),
                        child: const Text(
                          'My Fitness',
                          style: TextStyle(
                            color: _sunOrangeDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '\u4eca\u65e5\u6982\u89c8',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: _sunInk.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _CalorieProgressRing(
                  consumedCalories: consumedCalories,
                  targetCalories: targetCalories,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroStatPill(
                    label: '\u5df2\u6444\u5165',
                    value: '${consumedCalories.toStringAsFixed(0)} kcal',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroStatPill(
                    label: '\u5269\u4f59',
                    value: remainingCalories == null
                        ? '--'
                        : '${remainingCalories!.toStringAsFixed(0)} kcal',
                  ),
                ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DC),
        borderRadius: _sunnyPillRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _sunInk.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DashboardMacroRow extends StatelessWidget {
  const _DashboardMacroRow({
    required this.targets,
    required this.targetCalories,
    required this.incompleteMessage,
    required this.currentCarbs,
    required this.currentProtein,
    required this.currentFat,
  });

  final MacroTargets? targets;
  final double? targetCalories;
  final String incompleteMessage;
  final double currentCarbs;
  final double currentProtein;
  final double currentFat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final targets = this.targets;

    if (targets == null || targetCalories == null || targetCalories! <= 0) {
      return DecoratedBox(
        decoration: _sunnySurfaceDecoration(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              const _ClayIcon(
                icon: Icons.restaurant_menu_rounded,
                color: _sunOrange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  incompleteMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _sunInk.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = <_DashboardMacroItemData>[
      _DashboardMacroItemData(
        label: '\u78b3\u6c34',
        grams: currentCarbs,
        progress: (currentCarbs * 4) / targetCalories!,
        color: _sunOrange,
        icon: Icons.rice_bowl_rounded,
      ),
      _DashboardMacroItemData(
        label: '\u86cb\u767d\u8d28',
        grams: currentProtein,
        progress: (currentProtein * 4) / targetCalories!,
        color: _sunCoral,
        icon: Icons.egg_alt_rounded,
      ),
      _DashboardMacroItemData(
        label: '\u8102\u80aa',
        grams: currentFat,
        progress: (currentFat * 9) / targetCalories!,
        color: _sunLemon,
        icon: Icons.water_drop_rounded,
      ),
    ];

    return DecoratedBox(
      decoration: _sunnySurfaceDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 340 ? 6.0 : 10.0;
            final cellWidth = (constraints.maxWidth - gap * 2) / 3;
            final ringSize = math
                .max(66.0, math.min(92.0, cellWidth - 8))
                .toDouble();

            return Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(
                    child: _DashboardMacroItem(
                      data: items[index],
                      ringSize: ringSize,
                    ),
                  ),
                  if (index != items.length - 1) SizedBox(width: gap),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardMacroItemData {
  const _DashboardMacroItemData({
    required this.label,
    required this.grams,
    required this.progress,
    required this.color,
    required this.icon,
  });

  final String label;
  final double grams;
  final double progress;
  final Color color;
  final IconData icon;
}

class _DashboardMacroItem extends StatelessWidget {
  const _DashboardMacroItem({required this.data, required this.ringSize});

  final _DashboardMacroItemData data;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: ringSize,
                child: CircularProgressIndicator(
                  value: data.progress.clamp(0.0, 1.0),
                  strokeWidth: math.max(8.0, ringSize * 0.12),
                  strokeCap: StrokeCap.round,
                  backgroundColor: data.color.withValues(alpha: 0.16),
                  valueColor: AlwaysStoppedAnimation<Color>(data.color),
                ),
              ),
              _ClayIcon(icon: data.icon, color: data.color, size: 36),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            data.label,
            style: textTheme.labelLarge?.copyWith(
              color: _sunInk.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${_formatAmountText(data.grams)}g',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: _sunInk,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickSetupBar extends StatelessWidget {
  const _QuickSetupBar({
    required this.targetWeightKg,
    required this.profileSummary,
    required this.remainingCalories,
    required this.onSetWeight,
    required this.onOpenProfile,
  });

  final double? targetWeightKg;
  final String profileSummary;
  final double? remainingCalories;
  final VoidCallback onSetWeight;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: _sunnySurfaceDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const _ClayIcon(
              icon: Icons.tune_rounded,
              color: _sunCoral,
              size: 42,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onSetWeight,
                borderRadius: _sunnyPillRadius,
                child: _QuickSetupMetric(
                  label: '\u4f53\u91cd',
                  value: targetWeightKg == null
                      ? '\u672a\u8bbe\u7f6e'
                      : '${targetWeightKg!.toStringAsFixed(1)} kg',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: onOpenProfile,
                borderRadius: _sunnyPillRadius,
                child: _QuickSetupMetric(
                  label: '\u57fa\u7840\u4fe1\u606f',
                  value: profileSummary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 86),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  remainingCalories == null
                      ? '-- kcal'
                      : '${remainingCalories!.toStringAsFixed(0)} kcal',
                  style: textTheme.titleSmall?.copyWith(
                    color: _sunOrangeDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSetupMetric extends StatelessWidget {
  const _QuickSetupMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DC),
        borderRadius: _sunnyPillRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: _sunInk.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: _sunInk,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightRecordDashboardCard extends StatelessWidget {
  const _WeightRecordDashboardCard({
    required this.entries,
    required this.selectedEntries,
    required this.availableMonths,
    required this.selectedMonth,
    required this.hasMultipleYears,
    required this.onMonthChanged,
    required this.onAddRecord,
  });

  final List<WeightEntry> entries;
  final List<WeightEntry> selectedEntries;
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final bool hasMultipleYears;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: _sunnySurfaceDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _ClayIcon(
                  icon: Icons.show_chart_rounded,
                  color: _sunOrange,
                  size: 44,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '\u4f53\u91cd\u8bb0\u5f55',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (availableMonths.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _MonthSelectorPill(
                    months: availableMonths,
                    selectedMonth: selectedMonth,
                    hasMultipleYears: hasMultipleYears,
                    onChanged: onMonthChanged,
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onAddRecord,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('\u8bb0\u5f55'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 204,
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        '\u8fd8\u6ca1\u6709\u4f53\u91cd\u8bb0\u5f55',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _sunInk.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : WeightChart(entries: selectedEntries),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelectorPill extends StatelessWidget {
  const _MonthSelectorPill({
    required this.months,
    required this.selectedMonth,
    required this.hasMultipleYears,
    required this.onChanged,
  });

  final List<DateTime> months;
  final DateTime? selectedMonth;
  final bool hasMultipleYears;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DC),
        borderRadius: _sunnyPillRadius,
        border: Border.all(color: _sunWarmGrey.withValues(alpha: 0.75)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: selectedMonth,
          isDense: true,
          borderRadius: BorderRadius.circular(24),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _sunOrangeDeep,
            size: 20,
          ),
          items: months
              .map(
                (month) => DropdownMenuItem<DateTime>(
                  value: month,
                  child: Text(
                    _formatWeightMonthLabel(
                      month,
                      includeYear: hasMultipleYears,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _ClayIcon extends StatelessWidget {
  const _ClayIcon({required this.icon, required this.color, this.size = 48});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            color.withValues(alpha: 0.26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            blurRadius: 8,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.54),
    );
  }
}

class _MealVisualStyle {
  const _MealVisualStyle({required this.icon, required this.gradient});

  final IconData icon;
  final List<Color> gradient;
}

_MealVisualStyle _mealVisualForLabel(String mealLabel) {
  switch (mealLabel) {
    case '\u7b2c\u4e00\u9910':
      return const _MealVisualStyle(
        icon: Icons.wb_sunny_rounded,
        gradient: <Color>[_sunLemon, _sunOrange],
      );
    case '\u7b2c\u4e8c\u9910':
      return const _MealVisualStyle(
        icon: Icons.lunch_dining_rounded,
        gradient: <Color>[_sunApricot, _sunOrangeDeep],
      );
    case '\u7b2c\u4e09\u9910':
      return const _MealVisualStyle(
        icon: Icons.ramen_dining_rounded,
        gradient: <Color>[_sunCoral, _sunOrange],
      );
    case '\u7b2c\u56db\u9910':
      return const _MealVisualStyle(
        icon: Icons.local_cafe_rounded,
        gradient: <Color>[_sunLemon, _sunCoral],
      );
    case '\u7b2c\u4e94\u9910':
      return const _MealVisualStyle(
        icon: Icons.emoji_food_beverage_rounded,
        gradient: <Color>[_sunApricot, _sunCoral],
      );
    default:
      return const _MealVisualStyle(
        icon: Icons.nightlight_round,
        gradient: <Color>[_sunOrange, _sunOrangeDeep],
      );
  }
}

class _CalorieProgressRing extends StatelessWidget {
  const _CalorieProgressRing({
    required this.consumedCalories,
    required this.targetCalories,
  });

  final double consumedCalories;
  final double? targetCalories;

  double get _progress {
    if (targetCalories == null || targetCalories! <= 0) {
      return 0;
    }
    return (consumedCalories / targetCalories!).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(120),
            painter: _SunnyProgressRingPainter(progress: _progress),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Colors.white, Color(0xFFFFE4B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: _sunnyShadow(_sunOrange),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatAmountText(consumedCalories),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  targetCalories == null
                      ? '请先完善\n基础信息'
                      : '/${_formatAmountText(targetCalories!)} kcal',
                  style: textTheme.labelSmall?.copyWith(
                    color: _sunInk.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SunnyProgressRingPainter extends CustomPainter {
  const _SunnyProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedProgress = progress.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = const Color(0xFFFFE4B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    if (clampedProgress <= 0) {
      return;
    }

    final ringPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: <Color>[_sunLemon, _sunOrange, _sunCoral],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * clampedProgress,
      false,
      ringPaint,
    );

    final angle = -math.pi / 2 + math.pi * 2 * clampedProgress;
    final tipCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    canvas.drawCircle(
      tipCenter,
      10,
      Paint()..color = _sunOrange.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      tipCenter,
      6.5,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFEFF9FF), _sunOrangeDeep],
        ).createShader(Rect.fromCircle(center: tipCenter, radius: 7)),
    );
  }

  @override
  bool shouldRepaint(covariant _SunnyProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.entries});

  final List<WeightEntry> entries;
  static const double _leftPadding = 36;
  static const double _rightPadding = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final visiblePlotWidth = math.max(
          0.0,
          viewportWidth - _leftPadding - _rightPadding,
        );
        final segmentWidth = visiblePlotWidth / 6;
        final contentWidth = entries.length <= 7
            ? viewportWidth
            : _leftPadding +
                  _rightPadding +
                  segmentWidth * (entries.length - 1);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(viewportWidth, contentWidth),
            height: constraints.maxHeight,
            child: CustomPaint(painter: _WeightChartPainter(entries)),
          ),
        );
      },
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.entries);

  final List<WeightEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFFFE0AD)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[_sunOrangeDeep, _sunCoral],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = _sunOrangeDeep;
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0x33FF8F00), Color(0x00FF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    const left = 36.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 28.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(left + chartWidth, top + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      const Offset(left, top),
      Offset(left, top + chartHeight),
      axisPaint,
    );

    if (entries.isEmpty) {
      return;
    }

    final minWeight = entries
        .map((entry) => entry.weightKg)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = entries
        .map((entry) => entry.weightKg)
        .reduce((a, b) => a > b ? a : b);
    final safeMin = (minWeight - 2).clamp(0, double.infinity).toDouble();
    final safeMax = (maxWeight + 2).toDouble();
    final span = safeMax - safeMin == 0 ? 1.0 : safeMax - safeMin;

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final x = entries.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (entries.length - 1);
      final normalized = (entry.weightKg - safeMin) / span;
      final y = top + chartHeight - normalized * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, top + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()..color = _sunOrange.withValues(alpha: 0.14),
      );
      canvas.drawCircle(Offset(x, y), 4.2, pointPaint);

      _paintText(
        canvas,
        entry.weightKg.toStringAsFixed(1),
        Offset(x - 12, y - 18),
        const TextStyle(fontSize: 10, color: Colors.black87),
      );
      _paintText(
        canvas,
        '${entry.date.month}/${entry.date.day}',
        Offset(x - 12, top + chartHeight + 6),
        const TextStyle(fontSize: 10, color: Colors.grey),
      );
    }

    if (entries.length > 1) {
      final lastX = entries.length == 1
          ? left + chartWidth / 2
          : left + chartWidth;
      fillPath
        ..lineTo(lastX, top + chartHeight)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    for (var i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;
      final value = safeMax - span * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), axisPaint);
      _paintText(
        canvas,
        value.toStringAsFixed(1),
        Offset(0, y - 7),
        const TextStyle(fontSize: 10, color: Colors.grey),
      );
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class DietPage extends StatefulWidget {
  const DietPage({super.key, this.onRecordsChanged, this.repository});

  final Future<void> Function()? onRecordsChanged;
  final DietRecordRepository? repository;

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _mealTypes = const [
    '\u65E9\u9910',
    '\u5348\u9910',
    '\u665A\u9910',
    '\u52A0\u9910',
  ];
  String _selectedMealType = '\u65E9\u9910';
  bool _isLoading = true;
  DateTime _selectedDate = _normalizeDate(DateTime.now());
  List<DietRecord> _recordsForSelectedDate = <DietRecord>[];
  DietRecordRepository get _repository =>
      widget.repository ?? DatabaseDietRecordRepository.instance;

  String get _selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _selectedDateLabel => _formatDateLabel(_selectedDate);
  @override
  void initState() {
    super.initState();
    _loadRecordsForDate(_selectedDate);
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRecordsForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    setState(() {
      _selectedDate = normalizedDate;
      _recordsForSelectedDate = <DietRecord>[];
      _selectedMealType = _mealTypes.first;
      _foodNameController.clear();
      _caloriesController.clear();
      _notesController.clear();
      _isLoading = true;
    });

    try {
      final records = await _repository.getByDate(
        DateFormat('yyyy-MM-dd').format(normalizedDate),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recordsForSelectedDate = records;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recordsForSelectedDate = <DietRecord>[];
        _isLoading = false;
      });
    }
  }

  Future<void> _changeDate(DateTime date) async {
    await _loadRecordsForDate(date);
  }

  Future<void> _pickDate() async {
    final now = _normalizeDate(DateTime.now());
    final result = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TrainingDatePickerPage(
          initialDate: _selectedDate,
          minDate: DateTime(now.year - 1, now.month, now.day),
          maxDate: DateTime(now.year + 1, now.month, now.day),
        ),
      ),
    );

    if (result != null) {
      await _changeDate(result);
    }
  }

  Future<void> _saveRecord() async {
    final foodName = _foodNameController.text.trim();
    final calories = double.tryParse(_caloriesController.text.trim());

    if (foodName.isEmpty) {
      _showMessage(
        '闂傚倸鍊搁崐鎼佸磹瀹勬噴褰掑炊瑜忛弳锕傛煕椤垵浜濋柛娆忕箻閺屸剝寰勭€ｎ亝顔呭┑鐐叉▕娴滄粍鍎梻浣哥枃濡椼劌霉閸ヮ剙绠洪柡鍥╁枔缁♀偓闂侀潧楠忕徊鍓ф兜妤ｅ啯鐓涢柛顐亜婢у瓨銇勯姀鈩冪闁瑰磭鍋ゆ俊鐑芥晲閸曨厾娉块梻鍌欐祰椤宕曢崘鑼殾妞ゆ帒瀚崐鍫曟煃閸濆嫬鏆熺痪鎯с偢閺屽秷顧侀柛鎾跺枎閻ｇ兘骞掑Δ浣糕偓鐑芥倵閻㈡鐒鹃悽顖涘劤閳规垿鎮╅鑲╀紘濠电偛顦扮粙鎴ｇ亱濠电偛妫楃换鍡涘几瀹ュ鐓欓柛鎾楀懐鐦堢紓浣筋嚙濡瑩濡甸崟顖氱疀妞ゆ柨銇欓姀鐘斀妞ゆ梻鍘ч埀顒€娼″濠氬灳瀹曞洦娈曢柣搴秵閸撴瑩宕虹仦绛嬫富闁靛牆绨肩花濠氭煕閻旂顥嬫俊鍙夊姍楠炴帡骞婂畷鍥ф灈闁圭绻濇俊鍫曞川椤栨艾鐓傞梻鍌氬€搁崐鎼佸磹瀹勬噴褰掑炊椤掑鏅梺鍝勭▉閸樿偐绮ｅΔ浣风箚闁靛牆鍊告禍楣冩煟閹惧崬鈧牜鎹㈠┑鍥╃瘈闁稿本绋戝▍锝夋⒑閹肩偛濡界紒璇茬墦瀵鏁撻悩鑼槰闂侀潧臎閸愮偓婢戦梻鍌欑劍閹爼宕愰弴銏╂晞闁糕剝绋戞闂佸憡娲﹂崹鎵不閿濆鐓ユ繝闈涙閿涘秵淇婇銏狀仾缂?',
      );
      return;
    }
    if (calories == null || calories < 0) {
      _showMessage(
        '闂傚倸鍊搁崐鎼佸磹瀹勬噴褰掑炊瑜忛弳锕傛煕椤垵浜濋柛娆忕箻閺屸剝寰勭€ｎ亝顔呭┑鐐叉▕娴滄粍鍎梻浣哥枃濡椼劌霉閸ヮ剙绠洪柡鍥╁枔缁♀偓闂侀潧楠忕徊鍓ф兜妤ｅ啯鐓涢柛顐亜婢у瓨銇勯姀鈩冪闁瑰磭鍋ゆ俊鐑芥晲閸曨厾娉块梻鍌欐祰椤宕曢崘鑼殾妞ゆ帒瀚崐鍫曟煃閸濆嫬鏆熺痪鎯с偢閺屽秷顧侀柛鎾跺枎閻ｇ兘骞掑Δ浣糕偓鐑芥倵閻㈡鐒鹃悽顖涘劤閳规垿鎮╅鑲╀紘闂佺硶鏅滈悧鐘诲箚閸曨垼鏁嶆慨妯垮亹閳ь剝鍩栭妵鍕棘閸喒鎸冪紒鐐劤閵堟悂寮婚敐鍛傜喖宕崟顒佺槪婵犵數鍋為幆宀勫闯閿濆钃熼柨娑樺濞岊亞绱掔€ｎ亞浠㈤柍宄邦樀濮婃椽鎮烽弶鎸幮╅梺纭呮珪閿氶柣锝囧厴椤㈡洟鏁冮埀顒€鏁梻渚€娼чˇ顓㈠垂绾懌浜规繛鍡樻尰閳锋帡鏌涚仦鍓ф噯闁稿繐鏈妵鍕敇閻愰潧顤€濡炪們鍔婇崕闈涚暦椤愶箑唯鐟滃繘藝椤栨稓绡€闁汇垽娼у瓭濠电偛鐪伴崐婵嬪箯閹达附鍋勯悶娑掆偓鍏呭闂佺绻愰ˇ顖涚妤ｅ啯鈷戦柛娑橈工婵箑霉濠婂懎浠辩€殿喖鐖奸獮鏍ㄦ媴閸忓瀚奸梻渚€娼荤€靛矂宕ｉ埀顒佷繆閻愵剚鍊愰柡灞剧洴婵℃瓕顦叉い锝堝亹缁辨帡宕掑姣櫻呪偓瑙勬礃缁繘藝鐎靛摜妫柟顖嗗啯鍊繛锝呮搐閿曨亝淇婇崼鏇炲窛妞ゆ挆鍌涙▕闂傚倷绶氶埀顒傚仜閼活垶宕㈤幘顔界厱閻庯綆鍋呭畷灞炬叏?',
      );
      return;
    }

    final record = DietRecord(
      date: _selectedDateKey,
      mealType: _selectedMealType,
      foodName: foodName,
      calories: calories,
      notes: _notesController.text.trim(),
      createdAt: DatabaseService.getCurrentTimestamp(),
    );

    await _repository.addRecord(record);
    _selectedMealType = _mealTypes.first;
    _foodNameController.clear();
    _caloriesController.clear();
    _notesController.clear();
    await _loadRecordsForDate(_selectedDate);
    await widget.onRecordsChanged?.call();
    if (!mounted) {
      return;
    }
    _showCenteredFloatingMessage(
      context,
      '婵犵數濮烽弫鍛婃叏閹绢喗鍎夊鑸靛姇缁狙囧箹鐎涙ɑ灏ù婊堢畺閺屸€愁吋鎼粹€崇闂侀€炲苯澧柛鐔风－缁鈽夊Ο閿嬵潔濠殿喗銇涢崑鎾翠繆椤愩倕鍘存慨濠冩そ楠炴劖鎯旈敐鍥╂殼闂備焦瀵х粙鎴澪涘▎蹇ｅ殫闁告洦鍨扮粻娑欍亜閹存梹鏆橀柛銉ｅ妿閸橀亶姊洪棃娑辨缂佽尪濮ゆ穱濠囧礂缁楄桨绨婚柟鍏肩暘閸ㄨ煤鐎涙ɑ鍙忓┑鐘插暞閵囨繄鈧娲﹂崑濠傜暦閻旂厧鍨傛い鎰▉娴滄粓鍩為幋锔藉€风€瑰壊鍠楁晥婵犵數鍋涘鍓佸垝鎼淬劌绀嗛柟鐑橆殔缁秹鏌涚仦鍓р槈缁剧虎鍨跺娲濞戣京鍔搁梺鎼炲姀椤绮嬪鍡愬亝闁告劏鏅涙禒顓炩攽閻愬弶顥滅紒缁樺姍椤㈡棃顢曢敂鐣屽幍闂佽姤锚椤︻垶寮抽悢鍏肩厓鐟滄粓宕滃棰濇晩闁哄稁鍘肩粣妤佷繆閵堝懏鍣圭紒鐘虫緲铻栭柨婵嗘噹閺嗘瑧绱掗悩宕囧弨闁哄本娲濈粻娑㈠即閻戝棌鍋撶仦鍓х閻忓繑鐗楀▍濠囨煛瀹€鈧崰鏍х暦濡ゅ懎浼犻柕澶樺枟琚︽繝?',
    );
  }

  Future<void> _deleteRecord(int id) async {
    await _repository.deleteRecord(id);
    await _loadRecordsForDate(_selectedDate);
    await widget.onRecordsChanged?.call();
    if (!mounted) {
      return;
    }
    _showCenteredFloatingMessage(
      context,
      '婵犵數濮烽弫鍛婃叏閹绢喗鍎夊鑸靛姇缁狙囧箹鐎涙ɑ灏ù婊堢畺閺屸€愁吋鎼粹€崇闂侀€炲苯澧柛鐔风－缁鈽夊Ο閿嬵潔濠殿喗銇涢崑鎾翠繆椤愩倕鍘存慨濠冩そ楠炴劖鎯旈敐鍥╂殼闂備焦瀵х粙鎴澪涘▎蹇ｅ殫闁告洦鍨扮粻娑欍亜閹存梹鏆橀柛銉ｅ妿閸橀亶姊洪棃娑辨缂佽尪濮ゆ穱濠囧礂缁楄桨绨婚柟鍏肩暘閸ㄨ煤鐎涙ɑ鍙忓┑鐘插暞閵囨繄鈧娲﹂崑濠傜暦閻旂厧鍨傛い鎰▉娴滄粓鍩為幋锔藉€风€瑰壊鍠楁晥婵犵數鍋涘鍓佸垝鎼淬劌绀嗛柟鐑橆殔缁秹鏌涚仦鍓р槈缁剧虎鍨跺娲濞戣京鍔搁梺鎼炲姀椤绮嬪鍡愬亝闁告劏鏅濋崢浠嬫⒑缂佹ɑ鐓ラ柟纰卞亰閵嗗倹绺介崨濠勫幈闂佺粯鏌ㄩ幖顐ｇ瑜旈弻鐔煎矗婢跺鈧劗鈧鍠栭悥鐓庣暦瑜版帩鏁婇柤鎭掑労閸熷姊虹拠鍙夊攭妞ゎ偄顦叅婵犲﹤鐗勯埀顑跨劍缁绘繈宕堕‖顒婄畵閺岀喖鎮ч崼鐔哄嚒缂備胶濮垫繛濠囧蓟閻旇櫣纾奸柕蹇曞Х娴狀參鏌?',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _recordsForSelectedDate.fold<double>(
      0,
      (sum, record) => sum + record.calories,
    );

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => _loadRecordsForDate(_selectedDate),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _TrainingDateNavigator(
              title: '\u5065\u8eab\u8bb0\u5f55',
              dateLabel: _selectedDateLabel,
              onPreviousDay: () =>
                  _changeDate(_selectedDate.subtract(const Duration(days: 1))),
              onNextDay: () =>
                  _changeDate(_selectedDate.add(const Duration(days: 1))),
              onPickDate: _pickDate,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '闂傚倸鍊搁崐鎼佸磹瀹勬噴褰掑炊瑜忛弳锕傛煕椤垵浜濋柛娆忕箻閺岀喖骞嗛弶鍟冩捇鏌涙繝鍌涘仴闁哄被鍔戝鏉懳旈埀顒佺閹屾富闁靛牆楠搁獮鏍煟韫囨梻绠氶柣蹇斿浮濮婃椽宕楅懖鈹垮仦闂佸搫鎳忕换鍫ｆ濡炪倖鐗滈崑鐐哄磹閸偒娈介柣鎰皺娴犮垽鏌涢弮鈧喊宥嗙┍婵犲浂鏁冩い鎰╁灩缁犲綊姊哄畷鍥╁笡闁圭懓娲獮鍐樄鐎规洜鍘ч埥澶娢旈崘顏呮櫒闂傚倸鍊风粈渚€骞栭鈷氭椽鏁冮崒妯峰亾閸愵喖宸濇い鏃傝檸濞叉悂姊虹拠鈥崇€婚悘鐐村劤閻?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMealType,
                      borderRadius: BorderRadius.circular(16),
                      decoration: InputDecoration(
                        labelText:
                            '婵犵數濮烽弫鍛婃叏閻戝鈧倿顢欓悙顒夋綗闂佸搫娲㈤崹鍦缂佹ɑ鍙忔俊鐐额嚙娴滈箖姊虹拠鈥虫灓闁稿鍊濆顐﹀礃椤旇偐锛滃┑顔斤耿绾危閻戣姤鈷掑ù锝呮啞閹牊绻涚仦鍌氱伈鐎规洜顢婇妵鎰板箳閹存繂鎸?',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _mealTypes
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedMealType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _foodNameController,
                      decoration: const InputDecoration(
                        labelText:
                            '婵犵數濮烽弫鍛婃叏閻戝鈧倿顢欓悙顒夋綗闂佸搫娲㈤崹鍦缂佹绠鹃柟瀛樼懃閻掓椽鏌℃担绋款伃闁哄本鐩俊鐑筋敊閻撳寒娼荤紓鍌欑劍閸旀牠銆冩繝鍥ц摕闁绘梻鍘х粻姘辨喐韫囨稑绠洪柣妯虹－缁犻箖鏌涘☉鍗炵仩闁宠鐗撻弻锛勪沪閸撗岀伇濡炪倧绠掑▍鏇㈠Φ閸曨垰惟闁靛绠戝▍褔姊洪悷鏉跨骇闁瑰憡濞婂顐﹀磼閻愬鍙嗗銈嗙墬閻喗绔熼弴鐐嶆棃鎮╅棃娑楃捕闂佽绻戠换鍫濈暦濠靛棭娼╂い鎾跺Х椤?',
                        hintText:
                            '婵犵數濮烽弫鍛婃叏閻戣棄鏋侀柟闂寸绾惧鏌ｉ幇顒佹儓缂佺姵婢橀埞鎴︽偐瀹曞浂鏆￠梺鎼炲€曢懟顖濈亙闂佹寧绻傞幊搴ㄥ几閵堝鐓涘ù锝囶焾椤忣參鏌＄仦鍓р槈闁宠棄顦埢搴ㄥ箣閻愭惌鍞梻?婵犵數濮烽弫鍛婃叏閹绢喗鍎夊璺侯儜缁憋絽霉閿濆牊顏犻柨娑氬枛濮婅櫣鎷犻懠顒傤唺闂佺顑嗛惄顖氱暦閹版澘绠瑰ù锝呮憸閸旓箑顪冮妶鍡楃瑐闁绘帪濡囩划鍫⑩偓锝庡厴閸嬫挾鎲撮崟顒傦紭闂佹悶鍔嬬划娆撳Υ娓氣偓瀵噣宕煎┑瀣暪闂備胶绮弻銊╁箹椤愶妇宓?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText:
                            '闂傚倸鍊搁崐鎼佸磹閹间礁纾归柣鎴ｅГ閸ゅ嫰鏌涢幘鑼槮闁搞劍绻冮妵鍕冀椤愵澀绮堕梺鍝勫閸庣敻寮诲☉銏╂晝闁绘ɑ褰冩慨搴ㄦ⒑濞茶骞楁い銊ワ躬瀵鈽夐姀鐘电杸闂傚倸鐗婄粙鎺楁倶閸儲鈷?',
                        hintText:
                            '婵犵數濮烽弫鍛婃叏閻戣棄鏋侀柟闂寸绾惧鏌ｉ幇顒佹儓缂佺姵婢橀埞鎴︽偐瀹曞浂鏆￠梺鎼炲€曢懟顖濈亙闂佹寧绻傞幊搴ㄥ几閵堝鐓涘ù锝囶焾椤忣參鏌＄仦鍓р槈闁宠棄顦埢搴ㄥ箣閻愭惌鍞梻?165',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText:
                            '婵犵數濮烽弫鍛婃叏閻戣棄鏋侀柛娑橈攻閸欏繐霉閸忓吋缍戦柛銊ュ€块弻锝夊箻瀹曞洤鍝洪梺鍝勵儐閻楁鎹㈠☉銏犵闁绘劏鏅滈敍鍫濃攽閻愬弶鈻曞ù婊勭箞瀵彃鈹戠€ｎ偆鍘遍柣蹇曞仜婢т粙銆傞弻銉︾厽?',
                        hintText:
                            '闂傚倸鍊搁崐鎼佸磹閹间礁纾瑰瀣捣閻棗銆掑锝呬壕濡ょ姷鍋涢ˇ鐢稿极閹剧粯鍋愰柛鎰紦閻㈢粯淇婇悙顏勨偓鏍偋濠婂牆纾绘繛鎴欏灩閸ㄥ倿鏌涘畝鈧崑鐐烘偂閺囩喆浜滈柟鏉垮缁嬭崵绱掗埀顒勫焵椤掑嫭鈷?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveRecord,
                        child: const Text('濞ｅ洦绻傞悺銊︻殰椤曗偓椤ャ倗鎷嬮弶璺ㄧЭ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\u603B\u70ED\u91CF ${totalCalories.toStringAsFixed(1)} kcal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._recordsForSelectedDate.map(
              (record) => Card(
                child: ListTile(
                  title: Text('${record.mealType} - ${record.foodName}'),
                  subtitle: Text(
                    '${record.calories.toStringAsFixed(1)} 闂傚倸鍊搁崐鎼佸磹閹间礁纾瑰瀣捣閻棗銆掑锝呬壕濡ょ姷鍋涢ˇ鐢稿极閹剧粯鍋愭い鏃傛嚀娴滈箖鏌涢幇闈涙灈鐎瑰憡绻堥弻鈩冨緞鐎ｎ亞浠奸梺鍝勮嫰閻楀棝鈥旈崘顔嘉ч柛鈩冾殔椤洭姊洪幖鐐插妞ゎ厼鍢查?'
                    '${record.notes.isEmpty ? '' : '\n${record.notes}'}',
                  ),
                  isThreeLine: record.notes.isNotEmpty,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteRecord(record.id ?? 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutoMealDietPage extends StatefulWidget {
  const AutoMealDietPage({
    super.key,
    this.onRecordsChanged,
    this.repository,
    required this.nutritionTargetState,
  });

  final Future<void> Function()? onRecordsChanged;
  final MealFoodRecordRepository? repository;
  final NutritionTargetState nutritionTargetState;

  @override
  State<AutoMealDietPage> createState() => _AutoMealDietPageState();
}

class _AutoMealDietPageState extends State<AutoMealDietPage> {
  bool _isLoading = true;
  DateTime _selectedDate = _normalizeDate(DateTime.now());
  List<MealFoodRecord> _recordsForSelectedDate = <MealFoodRecord>[];

  static const List<String> _mealLabels = <String>[
    '\u7b2c\u4e00\u9910',
    '\u7b2c\u4e8c\u9910',
    '\u7b2c\u4e09\u9910',
    '\u7b2c\u56db\u9910',
    '\u7b2c\u4e94\u9910',
    '\u7b2c\u516d\u9910',
  ];

  MealFoodRecordRepository get _repository =>
      widget.repository ?? DatabaseMealFoodRecordRepository.instance;

  String get _selectedDateLabel => _formatDateLabel(_selectedDate);

  double get _totalCarbs => _recordsForSelectedDate.fold<double>(
    0,
    (sum, record) => sum + record.actualCarbs,
  );
  double get _totalProtein => _recordsForSelectedDate.fold<double>(
    0,
    (sum, record) => sum + record.actualProtein,
  );
  double get _totalFat => _recordsForSelectedDate.fold<double>(
    0,
    (sum, record) => sum + record.actualFat,
  );

  @override
  void initState() {
    super.initState();
    _loadRecordsForDate(_selectedDate);
  }

  Future<void> _loadRecordsForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    setState(() {
      _selectedDate = normalizedDate;
      _recordsForSelectedDate = <MealFoodRecord>[];
      _isLoading = true;
    });

    try {
      final dynamic result = await _repository.getByDate(
        DateFormat('yyyy-MM-dd').format(normalizedDate),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recordsForSelectedDate = _normalizeMealFoodRecords(result);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recordsForSelectedDate = <MealFoodRecord>[];
        _isLoading = false;
      });
    }
  }

  List<MealFoodRecord> _normalizeMealFoodRecords(dynamic result) {
    if (result is List<MealFoodRecord>) {
      return result;
    }

    if (result is List<DietRecord>) {
      final legacyRecords = result.cast<DietRecord>();
      return legacyRecords
          .map(
            (dietRecord) => MealFoodRecord(
              id: dietRecord.id,
              dateKey: dietRecord.date,
              mealIndex: dietRecord.mealIndex,
              mealLabel: dietRecord.mealLabel,
              foodName: dietRecord.foodName,
              baseUnitType: FoodUnitType.perServing,
              baseCarbs: dietRecord.carbs,
              baseProtein: dietRecord.protein,
              baseFat: dietRecord.fat,
              consumedAmount: 1,
              consumedUnit: FoodUnitType.perServing.consumedUnitLabel,
              actualCarbs: dietRecord.carbs,
              actualProtein: dietRecord.protein,
              actualFat: dietRecord.fat,
              createdAt: dietRecord.createdAt,
            ),
          )
          .toList();
    }

    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map((map) => MealFoodRecord.fromMap(map))
          .toList();
    }

    return <MealFoodRecord>[];
  }

  Future<void> _changeDate(DateTime date) async {
    await _loadRecordsForDate(date);
  }

  Future<void> _pickDate() async {
    final now = _normalizeDate(DateTime.now());
    final result = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TrainingDatePickerPage(
          initialDate: _selectedDate,
          minDate: DateTime(now.year - 1, now.month, now.day),
          maxDate: DateTime(now.year + 1, now.month, now.day),
        ),
      ),
    );

    if (result != null) {
      await _changeDate(result);
    }
  }

  Future<void> _openFoodSelection({
    required int mealIndex,
    required String mealLabel,
  }) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodSelectionPage(
          mealIndex: mealIndex,
          mealLabel: mealLabel,
          selectedDate: _selectedDate,
        ),
      ),
    );

    if (added == true) {
      await _loadRecordsForDate(_selectedDate);
      await widget.onRecordsChanged?.call();
      if (!mounted) {
        return;
      }
      _showCenteredFloatingMessage(
        context,
        '$mealLabel \u5df2\u6dfb\u52a0\u98df\u7269',
      );
    }
  }

  Future<void> _handleMealRecordTap(MealFoodRecord record) async {
    final result = await showDialog<_FoodAmountDialogResult>(
      context: context,
      builder: (_) => _FoodAmountEditorDialog(
        foodName: record.foodName,
        unitType: record.baseUnitType,
        initialAmount: record.consumedAmount,
        deleteConfirmationTitle: '\u5220\u9664\u8bb0\u5f55',
        deleteConfirmationMessage:
            '\u786e\u5b9a\u5220\u9664\u8fd9\u6761\u5df2\u6dfb\u52a0\u8bb0\u5f55\u5417\uff1f',
      ),
    );

    if (result == null || record.id == null) {
      return;
    }

    if (result.deleteRequested) {
      await _repository.deleteRecord(record.id!);
      await _loadRecordsForDate(_selectedDate);
      await widget.onRecordsChanged?.call();
      if (!mounted) {
        return;
      }
      _showCenteredFloatingMessage(context, '\u8bb0\u5f55\u5df2\u5220\u9664');
      return;
    }

    final amount = result.amount;
    if (amount == null) {
      return;
    }

    final multiplier = _mealFoodAmountMultiplier(record.baseUnitType, amount);
    final updatedRecord = record.copyWith(
      consumedAmount: amount,
      consumedUnit: record.baseUnitType.consumedUnitLabel,
      actualCarbs: record.baseCarbs * multiplier,
      actualProtein: record.baseProtein * multiplier,
      actualFat: record.baseFat * multiplier,
    );

    await _repository.updateRecord(updatedRecord);
    await _loadRecordsForDate(_selectedDate);
    await widget.onRecordsChanged?.call();
    if (!mounted) {
      return;
    }
    _showCenteredFloatingMessage(context, '\u8bb0\u5f55\u5df2\u66f4\u65b0');
  }

  List<MealFoodRecord> _recordsForMeal(int mealIndex) {
    return _recordsForSelectedDate
        .where((record) => record.mealIndex == mealIndex)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _TrainingDateNavigator(
              title: '\u996e\u98df',
              dateLabel: _selectedDateLabel,
              onPreviousDay: () =>
                  _changeDate(_selectedDate.subtract(const Duration(days: 1))),
              onNextDay: () =>
                  _changeDate(_selectedDate.add(const Duration(days: 1))),
              onPickDate: _pickDate,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _DietNutritionSummaryCard(
              carbs: _totalCarbs,
              protein: _totalProtein,
              fat: _totalFat,
              nutritionTargetState: widget.nutritionTargetState,
              titleLabel: '营养目标',
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadRecordsForDate(_selectedDate),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: _mealLabels.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final mealIndex = index + 1;
                  final mealLabel = _mealLabels[index];
                  final mealRecords = _recordsForMeal(mealIndex);

                  return _MealEntryCard(
                    mealLabel: mealLabel,
                    mealRecords: mealRecords,
                    onAddPressed: () => _openFoodSelection(
                      mealIndex: mealIndex,
                      mealLabel: mealLabel,
                    ),
                    onRecordTap: _handleMealRecordTap,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietNutritionSummaryCard extends StatelessWidget {
  const _DietNutritionSummaryCard({
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.nutritionTargetState,
    required this.titleLabel,
  });

  final double carbs;
  final double protein;
  final double fat;
  final NutritionTargetState nutritionTargetState;
  final String titleLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final targets = nutritionTargetState.targets;

    if (targets == null) {
      return DecoratedBox(
        decoration: _sunnySurfaceDecoration(context, color: _sunIvory),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nutritionTargetState.incompleteMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = <_MacroProgressData>[
      _MacroProgressData(
        label: '\u78b3\u6c34(g)',
        currentValue: carbs,
        targetValue: targets.carbs,
        unit: 'g',
        color: colorScheme.primary,
      ),
      _MacroProgressData(
        label: '\u86cb\u767d\u8d28(g)',
        currentValue: protein,
        targetValue: targets.protein,
        unit: 'g',
        color: colorScheme.secondary,
      ),
      _MacroProgressData(
        label: '\u8102\u80aa(g)',
        currentValue: fat,
        targetValue: targets.fat,
        unit: 'g',
        color: colorScheme.tertiary,
      ),
    ];

    return DecoratedBox(
      decoration: _sunnySurfaceDecoration(context, color: _sunIvory),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleLabel,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final ringSize = math
                    .max(82.0, math.min(96.0, (constraints.maxWidth - 24) / 3))
                    .toDouble();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      Expanded(
                        child: _MacroProgressRing(
                          data: items[index],
                          size: ringSize,
                        ),
                      ),
                      if (index != items.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroProgressRing extends StatelessWidget {
  const _MacroProgressRing({required this.data, required this.size});

  final _MacroProgressData data;
  final double size;

  double get _progress {
    if (data.targetValue <= 0) {
      return 0;
    }
    return (data.currentValue / data.targetValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final targetText = _formatAmountText(data.targetValue);
    final currentText = _formatAmountText(data.currentValue);
    final progressColor = data.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: progressColor.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentText,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/$targetText${data.unit}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({
    required this.mealLabel,
    required this.mealRecords,
    required this.onAddPressed,
    required this.onRecordTap,
  });

  final String mealLabel;
  final List<MealFoodRecord> mealRecords;
  final VoidCallback onAddPressed;
  final ValueChanged<MealFoodRecord> onRecordTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visual = _mealVisualForLabel(mealLabel);

    return DecoratedBox(
      decoration: _sunnySurfaceDecoration(context),
      child: ClipRRect(
        borderRadius: _sunnyCardRadius,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              color: _sunIvory,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: visual.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: _sunnyShadow(visual.gradient.last),
                    ),
                    child: Icon(visual.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      mealLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('\u6dfb\u52a0'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _sunOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (mealRecords.isNotEmpty)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF7EA),
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mealRecords.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final record = mealRecords[index];
                    return _MealFoodRecordCard(
                      record: record,
                      onTap: () => onRecordTap(record),
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '\u8fd8\u6ca1\u6709\u6dfb\u52a0\u98df\u7269\uff0c\u70b9\u51fb\u53f3\u4fa7\u6309\u94ae\u8865\u5145\u4eca\u5929\u7684\u8fd9\u4e00\u9910',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MealFoodRecordCard extends StatelessWidget {
  const _MealFoodRecordCard({required this.record, required this.onTap});

  final MealFoodRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _sunIvory,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.34),
            ),
            boxShadow: _sunnyShadow(_sunOrange),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${record.foodName} ${_formatAmountText(record.consumedAmount)}${record.consumedUnit}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FF),
                    borderRadius: _sunnyPillRadius,
                  ),
                  child: Text(
                    '\u78B3 ${_formatAmountText(record.actualCarbs)}g  \u86CB ${_formatAmountText(record.actualProtein)}g  \u8102 ${_formatAmountText(record.actualFat)}g',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodSelectionPage extends StatefulWidget {
  const FoodSelectionPage({
    super.key,
    required this.mealIndex,
    required this.mealLabel,
    required this.selectedDate,
    this.templateRepository,
    this.recordRepository,
  });

  final int mealIndex;
  final String mealLabel;
  final DateTime selectedDate;
  final FoodTemplateRepository? templateRepository;
  final MealFoodRecordRepository? recordRepository;

  @override
  State<FoodSelectionPage> createState() => _FoodSelectionPageState();
}

class _FoodSelectionPageState extends State<FoodSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _hasAddedFood = false;
  List<FoodTemplate> _templates = <FoodTemplate>[];
  late final int _currentMealIndex;
  late final String _currentMealLabel;
  late final String _currentDateKey;

  FoodTemplateRepository get _templateRepository =>
      widget.templateRepository ?? DatabaseFoodTemplateRepository.instance;
  MealFoodRecordRepository get _recordRepository =>
      widget.recordRepository ?? DatabaseMealFoodRecordRepository.instance;

  List<FoodTemplate> get _filteredTemplates {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _templates;
    }

    return _templates.where((template) {
      return template.name.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _currentMealIndex = widget.mealIndex;
    _currentMealLabel = widget.mealLabel;
    _currentDateKey = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    _searchController.addListener(_handleSearchChanged);
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  void _closePage() {
    Navigator.of(context).pop(_hasAddedFood);
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final templates = await _templateRepository.getAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _templates = <FoodTemplate>[];
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateFoodDialog() async {
    final template = await showDialog<FoodTemplate>(
      context: context,
      builder: (_) => const _CreateFoodTemplateDialog(),
    );

    if (template == null) {
      return;
    }

    await _templateRepository.addTemplate(template);
    await _loadTemplates();
    if (!mounted) {
      return;
    }
    _showCenteredFloatingMessage(context, '食物已创建');
  }

  Future<void> _handleTemplateTap(FoodTemplate template) async {
    final result = await showDialog<_FoodAmountDialogResult>(
      context: context,
      builder: (_) => _FoodAmountEditorDialog(
        foodName: template.name,
        unitType: template.unitType,
        deleteConfirmationTitle: '删除食物',
        deleteConfirmationMessage: '确定删除这个已保存食物吗？',
      ),
    );

    if (result == null) {
      return;
    }

    if (result.deleteRequested) {
      final templateId = template.id;
      if (templateId == null) {
        return;
      }
      await _templateRepository.deleteTemplate(templateId);
      await _loadTemplates();
      if (!mounted) {
        return;
      }
      _showCenteredFloatingMessage(context, '食物已删除');
      return;
    }

    final amount = result.amount;
    if (amount == null) {
      return;
    }

    final multiplier = _mealFoodAmountMultiplier(template.unitType, amount);
    final actualCarbs = template.carbs * multiplier;
    final actualProtein = template.protein * multiplier;
    final actualFat = template.fat * multiplier;

    final record = MealFoodRecord(
      dateKey: _currentDateKey,
      mealIndex: _currentMealIndex,
      mealLabel: _currentMealLabel,
      foodTemplateId: template.id,
      foodName: template.name,
      baseUnitType: template.unitType,
      baseCarbs: template.carbs,
      baseProtein: template.protein,
      baseFat: template.fat,
      consumedAmount: amount,
      consumedUnit: template.unitType.consumedUnitLabel,
      actualCarbs: actualCarbs,
      actualProtein: actualProtein,
      actualFat: actualFat,
      createdAt: DatabaseService.getCurrentTimestamp(),
    );

    await _recordRepository.addRecord(record);
    if (!mounted) {
      return;
    }
    _hasAddedFood = true;
    _showCenteredFloatingMessage(
      context,
      '$_currentMealLabel 已添加 ${template.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _filteredTemplates;
    final hasSearchKeyword = _searchController.text.trim().isNotEmpty;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _closePage();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _closePage,
            icon: const BackButtonIcon(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          title: const Text('选择食物'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _FoodSearchField(controller: _searchController),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _CreateFoodEntryCard(onTap: _showCreateFoodDialog),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: filteredTemplates.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = filteredTemplates[index];
                    return _FoodTemplateCard(
                      template: template,
                      onTap: () => _handleTemplateTap(template),
                    );
                  },
                ),
              ),
              if (!_isLoading && filteredTemplates.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Text(
                    hasSearchKeyword ? '没有找到相关食物' : '还没有已保存食物',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodSearchField extends StatelessWidget {
  const _FoodSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索食物',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
                tooltip: '清空搜索',
              ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _CreateFoodEntryCard extends StatelessWidget {
  const _CreateFoodEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '\u521b\u5efa\u98df\u7269',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.add_circle_outline_rounded,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodTemplateCard extends StatelessWidget {
  const _FoodTemplateCard({required this.template, required this.onTap});

  final FoodTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.unitType.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodDialogFrame extends StatelessWidget {
  const _FoodDialogFrame({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _showDeleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '删除',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

class _CreateFoodTemplateDialog extends StatefulWidget {
  const _CreateFoodTemplateDialog();

  @override
  State<_CreateFoodTemplateDialog> createState() =>
      _CreateFoodTemplateDialogState();
}

class _CreateFoodTemplateDialogState extends State<_CreateFoodTemplateDialog> {
  final _nameController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  FoodUnitType _unitType = FoodUnitType.per100g;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  double? _parseValue(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  void _save() {
    final name = _nameController.text.trim();
    final carbs = _parseValue(_carbsController);
    final protein = _parseValue(_proteinController);
    final fat = _parseValue(_fatController);

    if (name.isEmpty) {
      setState(() {
        _errorText = '请输入食物名称';
      });
      return;
    }
    if (carbs == null || protein == null || fat == null) {
      setState(() {
        _errorText = '请填写完整的营养信息';
      });
      return;
    }
    if (carbs < 0 || protein < 0 || fat < 0) {
      setState(() {
        _errorText = '营养数值不能小于 0';
      });
      return;
    }

    Navigator.of(context).pop(
      FoodTemplate(
        name: name,
        unitType: _unitType,
        carbs: carbs,
        protein: protein,
        fat: fat,
        createdAt: DatabaseService.getCurrentTimestamp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FoodDialogFrame(
      title: '创建食物',
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '食物名称'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '营养信息',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Flexible(
                child: CupertinoSlidingSegmentedControl<FoodUnitType>(
                  groupValue: _unitType,
                  children: const {
                    FoodUnitType.per100g: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text('每100g'),
                    ),
                    FoodUnitType.perServing: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text('每1份'),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _unitType = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DialogNutritionInputRow(
            label: '碳水',
            controller: _carbsController,
            unit: 'g',
          ),
          const SizedBox(height: 12),
          _DialogNutritionInputRow(
            label: '蛋白质',
            controller: _proteinController,
            unit: 'g',
          ),
          const SizedBox(height: 12),
          _DialogNutritionInputRow(
            label: '脂肪',
            controller: _fatController,
            unit: 'g',
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodAmountDialogResult {
  const _FoodAmountDialogResult.save(this.amount) : deleteRequested = false;
  const _FoodAmountDialogResult.delete()
    : amount = null,
      deleteRequested = true;

  final double? amount;
  final bool deleteRequested;
}

class _FoodAmountEditorDialog extends StatefulWidget {
  const _FoodAmountEditorDialog({
    required this.foodName,
    required this.unitType,
    required this.deleteConfirmationTitle,
    required this.deleteConfirmationMessage,
    this.initialAmount,
  });

  final String foodName;
  final FoodUnitType unitType;
  final double? initialAmount;
  final String deleteConfirmationTitle;
  final String deleteConfirmationMessage;

  @override
  State<_FoodAmountEditorDialog> createState() =>
      _FoodAmountEditorDialogState();
}

class _FoodAmountEditorDialogState extends State<_FoodAmountEditorDialog> {
  late final TextEditingController _amountController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : _formatAmountText(widget.initialAmount!),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);

    if (text.isEmpty) {
      setState(() {
        _errorText = '请输入数量';
      });
      return;
    }
    if (amount == null) {
      setState(() {
        _errorText = '请输入正确的数字';
      });
      return;
    }
    if (amount <= 0) {
      setState(() {
        _errorText = '数量必须大于 0';
      });
      return;
    }

    Navigator.of(context).pop(_FoodAmountDialogResult.save(amount));
  }

  Future<void> _delete() async {
    final confirmed = await _showDeleteConfirmationDialog(
      context,
      title: widget.deleteConfirmationTitle,
      message: widget.deleteConfirmationMessage,
    );

    if (!mounted || !confirmed) {
      return;
    }

    Navigator.of(context).pop(const _FoodAmountDialogResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    return _FoodDialogFrame(
      title: widget.foodName,
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '吃了多少',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                _DialogCompactNumberField(
                  controller: _amountController,
                  autofocus: true,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.unitType.consumedUnitLabel,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text('删除'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(onPressed: _save, child: const Text('保存')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogNutritionInputRow extends StatelessWidget {
  const _DialogNutritionInputRow({
    required this.label,
    required this.controller,
    required this.unit,
  });

  final String label;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _DialogCompactNumberField(
          controller: controller,
          width: 88,
          textAlign: TextAlign.center,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 16,
          child: Text(
            unit,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogCompactNumberField extends StatelessWidget {
  const _DialogCompactNumberField({
    required this.controller,
    this.width = 88,
    this.autofocus = false,
    this.textAlign = TextAlign.center,
  });

  final TextEditingController controller;
  final double width;
  final bool autofocus;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: textAlign,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key, this.repository});

  final TrainingRecordRepository? repository;

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final _aerobicDurationController = TextEditingController();
  final List<String> _muscleGroups = const ['胸', '背', '肩', '腿', '二头', '三头'];
  final Set<String> _selectedMuscles = <String>{};
  late final TrainingRecordRepository _repository;
  bool _isAerobicDay = false;
  bool _isLoading = true;
  DateTime _selectedDate = _startOfDay(DateTime.now());
  TrainingRecord? _currentRecord;
  OverlayEntry? _messageOverlayEntry;

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  List<String> _normalizeMuscleGroups(String muscleGroups) {
    final normalized = <String>{};

    for (final value in muscleGroups.split(',')) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed == '手臂') {
        normalized
          ..add('二头')
          ..add('三头');
        continue;
      }
      if (_muscleGroups.contains(trimmed)) {
        normalized.add(trimmed);
      }
    }

    return _muscleGroups.where(normalized.contains).toList();
  }

  String get _selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  String get _selectedDateLabel => _formatDateLabel(_selectedDate);

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? DatabaseTrainingRecordRepository.instance;
    _loadTrainingRecordForDate(_selectedDate);
  }

  @override
  void dispose() {
    _messageOverlayEntry?.remove();
    _aerobicDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainingRecordForDate(DateTime date) async {
    final normalizedDate = _startOfDay(date);
    setState(() {
      _selectedDate = normalizedDate;
      _currentRecord = null;
      _selectedMuscles.clear();
      _isAerobicDay = false;
      _aerobicDurationController.clear();
      _isLoading = true;
    });

    try {
      final record = await _repository.getByDate(
        DateFormat('yyyy-MM-dd').format(normalizedDate),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentRecord = record;
        _selectedMuscles
          ..clear()
          ..addAll(
            record == null
                ? <String>[]
                : _normalizeMuscleGroups(record.muscleGroups),
          );
        _isAerobicDay = record?.isAerobic ?? false;
        _aerobicDurationController.text =
            record != null && record.isAerobic && record.aerobicDuration > 0
            ? record.aerobicDuration.toString()
            : '';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentRecord = null;
        _selectedMuscles.clear();
        _isAerobicDay = false;
        _aerobicDurationController.clear();
        _isLoading = false;
      });
      _showMessage('加载训练记录失败');
    }
  }

  Future<void> _changeDate(DateTime date) async {
    await _loadTrainingRecordForDate(date);
  }

  Future<void> _pickDate() async {
    final now = _startOfDay(DateTime.now());
    final result = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TrainingDatePickerPage(
          initialDate: _selectedDate,
          minDate: DateTime(now.year - 1, now.month, now.day),
          maxDate: DateTime(now.year + 1, now.month, now.day),
        ),
      ),
    );

    if (result != null) {
      await _changeDate(result);
    }
  }

  int? _validateAerobicDuration() {
    if (!_isAerobicDay) {
      return 0;
    }

    final durationText = _aerobicDurationController.text.trim();
    if (durationText.isEmpty) {
      _showMessage('请输入有氧时长');
      return null;
    }

    final duration = int.tryParse(durationText);
    if (duration == null) {
      _showMessage('请输入合法的有氧时长');
      return null;
    }

    if (duration <= 0) {
      _showMessage('有氧时长必须大于 0');
      return null;
    }

    return duration;
  }

  Future<void> _saveTrainingRecord() async {
    final aerobicDuration = _validateAerobicDuration();
    if (aerobicDuration == null) {
      return;
    }
    final record = TrainingRecord(
      id: _currentRecord?.id,
      date: _selectedDateKey,
      muscleGroups: _selectedMuscles.join(', '),
      isAerobic: _isAerobicDay,
      aerobicDuration: _isAerobicDay ? aerobicDuration : 0,
      notes: '',
      createdAt:
          _currentRecord?.createdAt ?? DatabaseService.getCurrentTimestamp(),
    );

    final savedRecord = await _repository.saveForDate(record);
    if (!mounted) {
      return;
    }
    setState(() {
      _currentRecord = savedRecord;
    });
    _showCenteredMessage('训练记录已保存');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCenteredMessage(String message) {
    if (!mounted) {
      return;
    }

    _messageOverlayEntry?.remove();

    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CenteredFloatingMessage(
        message: message,
        onDismissed: () {
          if (_messageOverlayEntry == entry) {
            _messageOverlayEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _messageOverlayEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _TrainingDateNavigator(
            title: '训练',
            dateLabel: _selectedDateLabel,
            onPreviousDay: () =>
                _changeDate(_selectedDate.subtract(const Duration(days: 1))),
            onNextDay: () =>
                _changeDate(_selectedDate.add(const Duration(days: 1))),
            onPickDate: _pickDate,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          DecoratedBox(
            decoration: _sunnySurfaceDecoration(context, color: _sunIvory),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今天练了哪些部位',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _muscleGroups.map((group) {
                      final isSelected = _selectedMuscles.contains(group);
                      return _MuscleToggleChip(
                        label: group,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMuscles.remove(group);
                            } else {
                              _selectedMuscles.add(group);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2DC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('今天做了有氧'),
                      value: _isAerobicDay,
                      activeThumbColor: Colors.white,
                      activeTrackColor: _sunOrange,
                      inactiveThumbColor: _sunWarmGrey,
                      inactiveTrackColor: _sunWarmGrey.withValues(alpha: 0.35),
                      onChanged: (value) {
                        setState(() {
                          _isAerobicDay = value;
                          if (!value) {
                            _aerobicDurationController.clear();
                          }
                        });
                      },
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _isAerobicDay
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextField(
                              controller: _aerobicDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '有氧时长（分钟）',
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.18),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: _selectedMuscles.isNotEmpty
                        ? Column(
                            key: ValueKey(_selectedMuscles.join('、')),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Text('已选部位：${_selectedMuscles.join('、')}'),
                            ],
                          )
                        : SizedBox.shrink(
                            key: const ValueKey('empty_selected_parts'),
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveTrainingRecord,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleToggleChip extends StatefulWidget {
  const _MuscleToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MuscleToggleChip> createState() => _MuscleToggleChipState();
}

class _MuscleToggleChipState extends State<_MuscleToggleChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fillController;
  late final Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      value: widget.selected ? 1 : 0,
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _MuscleToggleChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) {
      return;
    }

    if (widget.selected) {
      _fillController.forward(from: 0);
    } else {
      _fillController.value = 0;
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        Theme.of(context).textTheme.titleSmall ?? const TextStyle();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: _sunnyPillRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: _sunnyPillRadius,
            border: Border.all(
              color: widget.selected ? _sunOrangeDeep : _sunWarmGrey,
            ),
            boxShadow: widget.selected
                ? _sunnyShadow(_sunOrange)
                : _sunnyShadow(const Color(0xFFCBEAFF)),
          ),
          child: ClipRRect(
            borderRadius: _sunnyPillRadius,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _MuscleLiquidFillPainter(
                          progress: _fillAnimation.value,
                          color: _sunOrange,
                        ),
                      );
                    },
                  ),
                ),
                if (widget.selected)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.08 * _fillAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    style: textStyle.copyWith(
                      color: widget.selected ? Colors.white : _sunInk,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(widget.label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuscleLiquidFillPainter extends CustomPainter {
  const _MuscleLiquidFillPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final baseRadius = maxRadius * progress;
    final waveStrength = (1 - progress).clamp(0.0, 1.0);
    final waveAmplitude =
        math.max(1.6, size.shortestSide * 0.045) * (0.35 + waveStrength * 0.65);
    final phase = progress * math.pi * 3.0;
    const pointCount = 56;

    final path = Path();
    for (var index = 0; index < pointCount; index += 1) {
      final angle = (math.pi * 2 * index) / pointCount;
      final wave =
          math.sin(angle * 4 + phase) * 0.65 +
          math.sin(angle * 7 - phase * 0.7) * 0.35;
      final radius = baseRadius + wave * waveAmplitude;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MuscleLiquidFillPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _TrainingDateNavigator extends StatelessWidget {
  const _TrainingDateNavigator({
    required this.title,
    required this.dateLabel,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDate,
  });

  final String title;
  final String dateLabel;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: _sunnySurfaceDecoration(
        context,
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF1F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            _DateArrowButton(
              icon: Icons.chevron_left_rounded,
              onPressed: onPreviousDay,
            ),
            const SizedBox(width: 6),
            Material(
              color: const Color(0xFFEAF7FF),
              borderRadius: _sunnyPillRadius,
              child: InkWell(
                onTap: onPickDate,
                borderRadius: _sunnyPillRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _DateArrowButton(
              icon: Icons.chevron_right_rounded,
              onPressed: onNextDay,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateArrowButton extends StatelessWidget {
  const _DateArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: _sunnyPillRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: _sunnyPillRadius,
        hoverColor: _sunOrange.withValues(alpha: 0.12),
        highlightColor: _sunOrange.withValues(alpha: 0.08),
        splashColor: _sunOrange.withValues(alpha: 0.22),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, color: _sunOrangeDeep, size: 20)),
        ),
      ),
    );
  }
}

class _CenteredFloatingMessage extends StatefulWidget {
  const _CenteredFloatingMessage({
    required this.message,
    required this.onDismissed,
  });

  final String message;
  final VoidCallback onDismissed;

  @override
  State<_CenteredFloatingMessage> createState() =>
      _CenteredFloatingMessageState();
}

class _CenteredFloatingMessageState extends State<_CenteredFloatingMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();
    _scheduleDismiss();
  }

  Future<void> _scheduleDismiss() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted || _dismissed) {
      return;
    }
    await _controller.reverse();
    _dismiss();
  }

  void _dismiss() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(_opacity),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TrainingDatePickerPage extends StatefulWidget {
  const TrainingDatePickerPage({
    super.key,
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
  });

  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<TrainingDatePickerPage> createState() => _TrainingDatePickerPageState();
}

class _TrainingDatePickerPageState extends State<TrainingDatePickerPage> {
  late DateTime _selectedDate;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  List<int> get _years => <int>[
    for (var year = widget.minDate.year; year <= widget.maxDate.year; year++)
      year,
  ];

  int get _daysInSelectedMonth =>
      DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);

  @override
  void initState() {
    super.initState();
    _selectedDate = _clampDate(widget.initialDate);
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedDate.year),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedDate.month - 1,
    );
    _dayController = FixedExtentScrollController(
      initialItem: _selectedDate.day - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  DateTime _clampDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    if (normalized.isBefore(widget.minDate)) {
      return widget.minDate;
    }
    if (normalized.isAfter(widget.maxDate)) {
      return widget.maxDate;
    }
    return normalized;
  }

  void _jumpControllersToSelectedDate() {
    _yearController.jumpToItem(_years.indexOf(_selectedDate.year));
    _monthController.jumpToItem(_selectedDate.month - 1);
    _dayController.jumpToItem(_selectedDate.day - 1);
  }

  void _updateDate({int? year, int? month, int? day}) {
    final nextYear = year ?? _selectedDate.year;
    final nextMonth = month ?? _selectedDate.month;
    final safeDay = (day ?? _selectedDate.day).clamp(
      1,
      DateUtils.getDaysInMonth(nextYear, nextMonth),
    );
    final nextDate = _clampDate(DateTime(nextYear, nextMonth, safeDay));

    setState(() {
      _selectedDate = nextDate;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _jumpControllersToSelectedDate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('\u53d6\u6d88'),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '\u9009\u62e9\u65e5\u671f',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selectedDate),
                    child: const Text('\u5b8c\u6210'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _clampDate(DateTime.now());
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _jumpControllersToSelectedDate();
                      }
                    });
                  },
                  icon: const Icon(Icons.today_rounded),
                  label: const Text('\u56de\u5230\u4eca\u5929'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  _DateWheelColumn(
                    label: '\u5E74',
                    controller: _yearController,
                    items: _years.map((year) => '$year\u5E74').toList(),
                    onSelectedItemChanged: (index) {
                      _updateDate(year: _years[index]);
                    },
                  ),
                  _DateWheelColumn(
                    label: '\u6708',
                    controller: _monthController,
                    items: [
                      for (var month = 1; month <= 12; month++) '$month\u6708',
                    ],
                    onSelectedItemChanged: (index) {
                      _updateDate(month: index + 1);
                    },
                  ),
                  _DateWheelColumn(
                    label: '\u65E5',
                    controller: _dayController,
                    items: [
                      for (var day = 1; day <= _daysInSelectedMonth; day++)
                        '$day\u65E5',
                    ],
                    onSelectedItemChanged: (index) {
                      _updateDate(day: index + 1);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                '\u53EF\u9009\u62E9\u8303\u56F4\uFF1A${DateFormat('yyyy/M/d').format(widget.minDate)} - ${DateFormat('yyyy/M/d').format(widget.maxDate)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateWheelColumn extends StatelessWidget {
  const _DateWheelColumn({
    required this.label,
    required this.controller,
    required this.items,
    required this.onSelectedItemChanged,
  });

  final String label;
  final FixedExtentScrollController controller;
  final List<String> items;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 44,
              useMagnifier: true,
              magnification: 1.05,
              squeeze: 1.1,
              onSelectedItemChanged: onSelectedItemChanged,
              children: items.map((item) => Center(child: Text(item))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LegacyProfilePage extends StatelessWidget {
  // ignore: unused_element_parameter
  const _LegacyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '个人页开发中',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.initialProfile = const UserProfile(),
    this.profileStore,
    this.imagePicker,
    this.authStore = const LocalAuthStore(),
    this.onProfileChanged,
  });

  final UserProfile initialProfile;
  final UserProfileStore? profileStore;
  final ImagePicker? imagePicker;
  final LocalAuthStore authStore;
  final ValueChanged<UserProfile>? onProfileChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const MethodChannel _avatarPickerChannel = MethodChannel(
    'fitness_app/avatar_picker',
  );

  late final UserProfileStore _profileStore;
  late final ImagePicker _imagePicker;
  late final LocalAuthStore _authStore;

  late UserProfile _profile;
  String? _lastPersistedAvatarPath;
  bool _isLoading = true;
  bool _isSavingAvatar = false;
  bool _isGuestUser = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _profileStore =
        widget.profileStore ?? SharedPreferencesUserProfileStore.instance;
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _authStore = widget.authStore;
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await _loadProfile();
    if (!_isGuestUser && !Platform.isAndroid) {
      await _recoverLostAvatarPick();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final isGuestUser = await _authStore.isGuestSession();
      final profile = await _loadProfileWithValidAvatar(
        isGuestUser: isGuestUser,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _lastPersistedAvatarPath = profile.avatarPath;
        _isGuestUser = isGuestUser;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = const UserProfile();
        _isLoading = false;
      });
      _showProfileMessage('加载个人资料失败，请稍后重试');
    }
  }

  Future<UserProfile> _loadProfileWithValidAvatar({
    required bool isGuestUser,
  }) async {
    if (isGuestUser) {
      return const UserProfile();
    }

    final currentUser = await _authStore.loadCurrentUser();
    var profile = await _profileStore.loadProfile();
    if (profile.nickname.trim().isEmpty &&
        currentUser != null &&
        currentUser.username.trim().isNotEmpty) {
      profile = profile.copyWith(nickname: currentUser.username);
    }
    if ((profile.avatarPath == null || profile.avatarPath!.trim().isEmpty) &&
        currentUser?.avatarPath != null &&
        currentUser!.avatarPath!.trim().isNotEmpty) {
      profile = profile.copyWith(
        avatarPath: await AvatarFileStore.resolveStoredPath(
          currentUser.avatarPath,
        ),
      );
    }
    final avatarPath = profile.avatarPath?.trim();
    if (avatarPath == null || avatarPath.isEmpty) {
      return profile;
    }

    try {
      final avatarFile = File(avatarPath);
      if (avatarFile.existsSync()) {
        return profile.copyWith(avatarPath: avatarPath);
      }
    } catch (_) {
      // Invalid or unreadable local paths are treated as stale avatars.
    }

    final clearedProfile = await _profileStore.saveAvatarPath(null);
    await _authStore.updateCurrentAvatarPath(null);
    return clearedProfile;
  }

  Future<void> _recoverLostAvatarPick() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) {
        return;
      }

      final files = response.files;
      final pickedFile = files != null && files.isNotEmpty
          ? files.first
          : response.file;

      if (pickedFile == null) {
        if (response.exception != null) {
          _showProfileMessage('恢复头像选择失败，请重新选择');
        }
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingAvatar = true;
        _profile = _profile.copyWith(
          avatarPath: pickedFile.path,
          clearAvatar: pickedFile.path.trim().isEmpty,
        );
      });

      await _savePickedAvatar(pickedFile, successMessage: '头像已更新');
    } on MissingPluginException {
      return;
    } on PlatformException {
      _showProfileMessage('无法读取已选择的头像，请重新选择');
    } catch (_) {
      _showProfileMessage('恢复头像选择失败，请重新选择');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleAvatarTap() async {
    if (_isLoading || _isSavingAvatar) {
      return;
    }
    if (_isGuestUser) {
      _showProfileMessage('游客模式下请先注册或登录后设置头像');
      return;
    }

    setState(() {
      _isSavingAvatar = true;
    });

    try {
      final pickedFile = await _pickAvatarImage();

      if (pickedFile == null) {
        return;
      }

      // Make the avatar feel responsive immediately on physical devices.
      // The final persisted path will be applied after _persistAvatar finishes.
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = _profile.copyWith(
          avatarPath: pickedFile.path,
          clearAvatar: pickedFile.path.trim().isEmpty,
        );
      });

      await _savePickedAvatar(pickedFile, successMessage: '头像已更新');
    } on PlatformException {
      if (!mounted) {
        return;
      }
      _showProfileMessage('无法打开相册或读取图片，请检查权限后重试');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showProfileMessage('更新头像失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAvatar = false;
        });
      }
    }
  }

  Future<XFile?> _pickAvatarImage() async {
    if (Platform.isAndroid) {
      final path = await _avatarPickerChannel.invokeMethod<String>(
        'pickAvatarImage',
      );
      final normalizedPath = path?.trim();
      if (normalizedPath == null || normalizedPath.isEmpty) {
        return null;
      }
      return XFile(normalizedPath);
    }

    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 88,
    );
  }

  Future<void> _savePickedAvatar(
    XFile pickedFile, {
    required String successMessage,
  }) async {
    final storedPath = await _persistAvatar(
      pickedFile,
      previousAvatarPath: _lastPersistedAvatarPath,
    );
    if (storedPath.trim().isEmpty) {
      throw const FileSystemException('Avatar path is empty.');
    }

    final updatedProfile = await _profileStore.saveAvatarPath(storedPath);
    await _authStore.updateCurrentAvatarPath(storedPath);
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = updatedProfile;
      _lastPersistedAvatarPath = updatedProfile.avatarPath;
    });
    widget.onProfileChanged?.call(updatedProfile);
    _showProfileMessage(successMessage);
  }

  Future<String> _persistAvatar(
    XFile pickedFile, {
    required String? previousAvatarPath,
  }) async {
    final avatarDirectory = await AvatarFileStore.managedDirectory();
    if (!await avatarDirectory.exists()) {
      await avatarDirectory.create(recursive: true);
    }

    final extension = _avatarFileExtension(pickedFile);
    final targetPath = p.join(
      avatarDirectory.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}$extension',
    );

    final bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) {
      throw const FileSystemException('Picked avatar file is empty.');
    }

    final savedFile = File(targetPath);
    await savedFile.writeAsBytes(bytes, flush: true);
    final previousPath = previousAvatarPath;
    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != savedFile.path) {
      await _deletePreviousManagedAvatar(
        previousPath: previousPath,
        avatarDirectoryPath: avatarDirectory.path,
        currentPath: savedFile.path,
      );
    }

    return savedFile.path;
  }

  String _avatarFileExtension(XFile pickedFile) {
    const supportedExtensions = <String>{
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
    };

    for (final candidate in <String>[pickedFile.name, pickedFile.path]) {
      final extension = p.extension(candidate).toLowerCase();
      if (supportedExtensions.contains(extension)) {
        return extension;
      }
    }

    return '.jpg';
  }

  Future<void> _deletePreviousManagedAvatar({
    required String previousPath,
    required String avatarDirectoryPath,
    required String currentPath,
  }) async {
    final normalizedPreviousPath = p.normalize(previousPath);
    final normalizedAvatarDirectoryPath = p.normalize(avatarDirectoryPath);
    final normalizedCurrentPath = p.normalize(currentPath);
    final isPreviousManagedAvatar =
        p.equals(
          p.dirname(normalizedPreviousPath),
          normalizedAvatarDirectoryPath,
        ) ||
        p.isWithin(normalizedAvatarDirectoryPath, normalizedPreviousPath);

    if (!isPreviousManagedAvatar ||
        p.equals(normalizedPreviousPath, normalizedCurrentPath)) {
      return;
    }

    try {
      final previousFile = File(previousPath);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    } catch (_) {
      // A stale old avatar should not block the new avatar from being saved.
    }
  }

  // ignore: unused_element
  Future<void> _handleNicknameTap() async {
    if (_isLoading) {
      return;
    }

    final controller = TextEditingController(text: _profile.nickname);
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑用户名'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: const InputDecoration(hintText: '请输入用户名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (nickname == null) {
      return;
    }

    try {
      final updatedProfile = await _profileStore.saveNickname(nickname);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updatedProfile;
      });
      widget.onProfileChanged?.call(updatedProfile);
      _showProfileMessage(nickname.isEmpty ? '已恢复默认昵称' : '昵称已更新');
    } catch (_) {
      _showProfileMessage('保存昵称失败，请稍后重试');
    }
  }

  // ignore: unused_element
  Future<void> _openNicknameEditor() async {
    if (_isLoading) {
      return;
    }
    if (_isGuestUser) {
      _showProfileMessage('游客模式不能修改用户名');
      return;
    }

    final nickname = await showDialog<String>(
      context: context,
      builder: (context) =>
          _NicknameEditDialog(initialNickname: _profile.nickname),
    );

    if (nickname == null) {
      return;
    }

    try {
      final updatedProfile = await _profileStore.saveNickname(nickname);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updatedProfile;
      });
      widget.onProfileChanged?.call(updatedProfile);
      _showProfileMessage(nickname.isEmpty ? '已恢复默认昵称' : '昵称已更新');
    } catch (_) {
      _showProfileMessage('保存昵称失败，请稍后重试');
    }
  }

  Future<void> _openUsernameEditor() async {
    if (_isLoading) {
      return;
    }
    if (_isGuestUser) {
      _showProfileMessage('游客模式不能修改用户名');
      return;
    }

    final username = await showDialog<String>(
      context: context,
      builder: (context) =>
          _NicknameEditDialog(initialNickname: _profile.nickname),
    );

    if (username == null) {
      return;
    }

    try {
      final updatedUser = await _authStore.updateCurrentUsername(username);
      final updatedProfile = await _profileStore.saveNickname(
        updatedUser.username,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = updatedProfile.copyWith(nickname: updatedUser.username);
      });
      widget.onProfileChanged?.call(_profile);
      _showProfileMessage('用户名已更新');
    } on LocalAuthException catch (error) {
      _showProfileMessage(error.message);
    } catch (_) {
      _showProfileMessage('保存用户名失败，请稍后重试');
    }
  }

  Future<void> _openPersonalInfoPage() async {
    if (_isLoading) {
      return;
    }

    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute(
        builder: (_) => PersonalInfoPage(
          initialProfile: _profile,
          profileStore: _profileStore,
        ),
      ),
    );

    if (updatedProfile == null || !mounted) {
      return;
    }

    setState(() {
      _profile = updatedProfile;
    });
    widget.onProfileChanged?.call(updatedProfile);
  }

  Future<void> _openSettingsPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => SettingsPage(authStore: _authStore)),
    );
  }

  void _showProfileMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          _ProfileHeaderCard(
            profile: _profile,
            isLoading: _isLoading,
            isSavingAvatar: _isSavingAvatar,
            isGuestUser: _isGuestUser,
            onAvatarTap: _handleAvatarTap,
            onNicknameTap: _openUsernameEditor,
          ),
          const SizedBox(height: 16),
          _ProfileStatsCard(
            profile: _profile,
            onTap: _isLoading ? null : _openPersonalInfoPage,
          ),
          const SizedBox(height: 16),
          _ProfileSettingsCard(onTap: _openSettingsPage),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.authStore = const LocalAuthStore()});

  final LocalAuthStore authStore;

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    await authStore.logout();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              color: _sunIvory,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: InkWell(
                onTap: () => _confirmLogout(context),
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: _SettingsListRow(
                    icon: Icons.logout_rounded,
                    label: '退出登录',
                    showChevron: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSettingsCard extends StatelessWidget {
  const _ProfileSettingsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _sunIvory,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: _SettingsListRow(icon: Icons.settings_outlined, label: '设置'),
        ),
      ),
    );
  }
}

class _SettingsListRow extends StatelessWidget {
  const _SettingsListRow({
    required this.icon,
    required this.label,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (showChevron)
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.isLoading,
    required this.isSavingAvatar,
    required this.isGuestUser,
    required this.onAvatarTap,
    required this.onNicknameTap,
  });

  final UserProfile profile;
  final bool isLoading;
  final bool isSavingAvatar;
  final bool isGuestUser;
  final VoidCallback onAvatarTap;
  final VoidCallback onNicknameTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarFile = profile.avatarPath == null || profile.avatarPath!.isEmpty
        ? null
        : File(profile.avatarPath!);
    final hasAvatar = avatarFile?.existsSync() ?? false;
    final defaultAvatar = Icon(
      Icons.person_rounded,
      size: 34,
      color: colorScheme.onSurfaceVariant,
    );

    return Card(
      color: _sunIvory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            InkWell(
              onTap: isLoading ? null : onAvatarTap,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: hasAvatar
                            ? Image(
                                key: ValueKey(avatarFile!.path),
                                image: FileImage(avatarFile),
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                                errorBuilder: (context, error, stackTrace) {
                                  return defaultAvatar;
                                },
                              )
                            : defaultAvatar,
                      ),
                    ),
                    if (isSavingAvatar)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: isLoading || isGuestUser ? null : onNicknameTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isLoading
                              ? UserProfile.guestName
                              : profile.displayName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                      if (!isGuestUser)
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({required this.profile, this.onTap});

  final UserProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final genderText = profile.gender?.label ?? '未填写';
    final ageText = profile.age == null ? '未填写' : '${profile.age} 岁';
    final heightText = profile.heightCm == null
        ? '未填写'
        : '${_formatAmountText(profile.heightCm!)} cm';

    return Card(
      color: _sunIvory,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '个人信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              _ProfileInfoRow(label: '性别', value: genderText),
              _ProfileInfoRow(label: '年龄', value: ageText),
              _ProfileInfoRow(label: '身高', value: heightText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({
    super.key,
    required this.initialProfile,
    required this.profileStore,
  });

  final UserProfile initialProfile;
  final UserProfileStore profileStore;

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  UserGender? _selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialProfile.gender;
    _ageController = TextEditingController(
      text: widget.initialProfile.age?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.initialProfile.heightCm == null
          ? ''
          : _formatAmountText(widget.initialProfile.heightCm!),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final age = int.tryParse(_ageController.text.trim());
    final heightCm = double.tryParse(_heightController.text.trim());

    if (_selectedGender == null) {
      _showMessage('请选择性别');
      return;
    }
    if (age == null || age <= 0) {
      _showMessage('请输入正确的年龄');
      return;
    }
    if (heightCm == null || heightCm <= 0) {
      _showMessage('请输入正确的身高');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = await widget.profileStore.savePersonalInfo(
        gender: _selectedGender!,
        age: age,
        heightCm: heightCm,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updatedProfile);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      _showMessage('保存个人信息失败，请稍后重试');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '基础资料',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '性别',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<UserGender>(
                    segments: const <ButtonSegment<UserGender>>[
                      ButtonSegment<UserGender>(
                        value: UserGender.male,
                        label: Text('男'),
                      ),
                      ButtonSegment<UserGender>(
                        value: UserGender.female,
                        label: Text('女'),
                      ),
                    ],
                    selected: _selectedGender == null
                        ? <UserGender>{}
                        : <UserGender>{_selectedGender!},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedGender = selection.isEmpty
                            ? null
                            : selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '年龄',
                      hintText: '请输入年龄',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '身高',
                      hintText: '请输入身高',
                      suffixText: 'cm',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? '保存中...' : '保存'),
          ),
        ],
      ),
    );
  }
}

class _NicknameEditDialog extends StatefulWidget {
  const _NicknameEditDialog({required this.initialNickname});

  final String initialNickname;

  @override
  State<_NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<_NicknameEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑用户名'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(hintText: '请输入用户名'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
