library moreld_apply_theme;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moreld_apply_theme/extensions/hex_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreldApplyTheme extends StatefulWidget {
  const MoreldApplyTheme({
    Key? key,
    this.url = 'https://theme.apply.no/theme.json',
    required this.appId,
    required this.child,
  }) : super(key: key);

  final String url;
  final String appId;
  final Widget child;

  @override
  State<MoreldApplyTheme> createState() => _MoreldApplyThemeState();
}

class _MoreldApplyThemeState extends State<MoreldApplyTheme> {
  ThemeData? _theme;

  Future<ThemeData> buildTheme(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final baseTheme = Theme.of(context);
    try {
      final theme = await fetchTheme(context);

      final primary = HexColor.fromHex(theme['primary'] as String);
      final secondary = HexColor.fromHex(theme['secondary'] as String);
      final accent = HexColor.fromHex(theme['accent'] as String);
      final onPrimary = theme['onPrimary'] as String;
      final onSecondary = theme['onSecondary'] as String;
      final logo = theme['logo'] as String;

      // TODO: Replace this with an InheritedWidget or use the Provider package
      prefs.setString('MORELD_APPLY_THEME_LOGO', logo);

      return baseTheme.copyWith(
        primaryColor: primary,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: primary,
          secondary: secondary,
          onPrimary: onPrimary == 'light' ? Colors.white : Colors.black87,
          onSecondary: onSecondary == 'light' ? Colors.white : Colors.black87,
        ),
      );
    } catch (e) {
      return baseTheme;
    }
  }

  Future<Map<String, dynamic>> fetchTheme(BuildContext context) async {
    final themeJson = await fetchThemeJson();
    if (themeJson == null) {
      return flattenTheme(null, null);
    }
    final theme = jsonDecode(themeJson);
    return flattenTheme(
      theme['base'],
      theme['apps']?[widget.appId],
    );
  }

  Future<String?> fetchThemeJson() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        prefs.setString('MORELD_APPLY_THEME', response.body);
        return response.body;
      }
    } catch (e) {
      // Use the cached value as fallback
    }
    return prefs.getString('MORELD_APPLY_THEME');
  }

  Map<String, dynamic> flattenTheme(
    Map<String, dynamic>? base,
    Map<String, dynamic>? app,
  ) {
    return <String, dynamic>{
      'primary': app?['primary'] ?? base?['primary'],
      'secondary': app?['secondary'] ?? base?['secondary'],
      'accent': app?['accent'] ?? base?['accent'],
      'onPrimary': app?['onPrimary'] ?? base?['onPrimary'],
      'onSecondary': app?['onSecondary'] ?? base?['onSecondary'],
      'logo': app?['logo'] ?? base?['logo'],
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_ts) async {
      if (mounted) {
        final theme = await buildTheme(context);
        if (mounted) {
          setState(() {
            _theme = theme;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _theme ??= Theme.of(context);
    return Theme(
      data: _theme!,
      child: widget.child,
    );
  }
}
