import 'package:flutter/material.dart';

class OwnThemeFields {
  final kDefaultPadding = 20.0;
  final Color lightShadow;
  final Color darkShadow;

  // const OwnThemeFields({Color? errorShade, Color? textBaloon, Color? spanColor})
  OwnThemeFields({
    required this.lightShadow,
    required this.darkShadow,
  });
}

final _customTheme = OwnThemeFields(
  lightShadow: Colors.white.withOpacity(0.7),
  darkShadow: Colors.black.withOpacity(0.5),
);

final _customDarkTheme = OwnThemeFields(
  lightShadow: Colors.white.withOpacity(0.3),
  darkShadow: Colors.black.withOpacity(0.9),
);

extension ThemeDataExtensions on ThemeData {
  OwnThemeFields get custom =>
      brightness == Brightness.dark ? _customDarkTheme : _customTheme;
}

final ThemeData lightTheme = ThemeData.light().copyWith(
  dialogBackgroundColor: const Color(0xFFF2F4FC),
  scaffoldBackgroundColor: const Color(0xFFEBEDFA),
);

final ThemeData darkTheme = ThemeData.dark().copyWith(
  // primaryColor: Colors.blue,
  colorScheme: const ColorScheme.dark().copyWith(
      primary: Colors.blue,
      secondary: Colors.blue,
      tertiary: Colors.blue,
      primaryContainer: Colors.blue),
  floatingActionButtonTheme:
      const FloatingActionButtonThemeData(foregroundColor: Colors.white),
  checkboxTheme:
      CheckboxThemeData(fillColor: MaterialStateProperty.resolveWith((states) {
    return (states.contains(MaterialState.selected)) ? Colors.blue : null;
  })),
  elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith((states) =>
              (states.contains(MaterialState.disabled))
                  ? null
                  : Colors.white))),
);
