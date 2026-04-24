import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/loginpage.dart';

Future<void> logoutUser(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.remove('token');
  await prefs.remove('department');
  await prefs.remove('username');
  await prefs.remove('warehouse');
  await prefs.remove('warehouse_id');
  await prefs.remove('user_id');

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const login()),
    (route) => false,
  );
}