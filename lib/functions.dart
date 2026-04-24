import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

 

class Functions {


   Future<String?> gettokenFromPrefs() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      return prefs.getString('token');
      
    }
     Future<int?> getidFromPrefs() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_id');
    }

 
}
