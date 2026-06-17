import 'dart:async';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthStatusChecker {
  static Timer? _timer;
  static bool _isLoggingOut = false;

  static void start(BuildContext context) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await check(context);
    });
  }

  static Future<void> check(BuildContext context) async {
    if (_isLoggingOut) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$api/api/auth/status/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404) {
        _isLoggingOut = true;
        _timer?.cancel();

        await prefs.clear();

        if (!context.mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const login()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Auth status check error: $e");
    }
  }

  static void stop() {
    _timer?.cancel();
  }
}