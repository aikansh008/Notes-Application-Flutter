import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode mode;
  const ThemeState(this.mode);
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _key = 'theme_mode';
  ThemeCubit() : super(const ThemeState(ThemeMode.system));

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key);
    switch (v) {
      case 'light':
        emit(const ThemeState(ThemeMode.light));
        break;
      case 'dark':
        emit(const ThemeState(ThemeMode.dark));
        break;
      default:
        emit(const ThemeState(ThemeMode.system));
    }
  }

  Future<void> set(ThemeMode mode) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, mode.name);
    emit(ThemeState(mode));
  }
}
