import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/ASD_dashborad.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/registerationpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/pages/api.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:local_auth/local_auth.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  var url = "$api/api/login/";

  static const Color logoBlue1 = Color(0xFF3F82F6);
  static const Color logoBlue2 = Color(0xFF20B8F6);
  static const Color logoCyan = Color(0xFF05C7E8);

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isLoading = false;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
  }

  Future<void> storeUserData(String token, String department, String username,
      dynamic warehouse) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('department', department);
    await prefs.setString('username', username);

    if (warehouse is int) {
      await prefs.setInt('warehouse', warehouse);
    } else if (warehouse is String) {
      await prefs.setString('warehouse', warehouse);
    } else {}
  }

  Future<void> biometricLogin() async {
    try {
      bool isSupported = await auth.isDeviceSupported();
      bool canCheck = await auth.canCheckBiometrics;

      if (!isSupported || !canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Biometric not available"),
          ),
        );
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: "Login with fingerprint or face",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        final token = await getTokenFromPrefs();
        if (token != null && token.isNotEmpty) {
          await addfingerprint();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please login with username and password first to enable biometric login",
              ),
            ),
          );
        }
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Biometric login failed: $e"),
        ),
      );
    }
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> addfingerprint() async {
    final token = await getTokenFromPrefs();
    try {
      final response = await http.post(
        Uri.parse('$api/api/login/$token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      var active = jsonDecode(response.body)['user']['department'];

      if (response.statusCode == 200) {
        Widget targetPage;

        switch (active) {
          case 'Information Technology':
          case 'Accounts / Accounting':
            targetPage = dashboard();
            break;
          case 'warehouse':
            targetPage = WarehouseDashboard();
            break;
          case 'BDO':
            targetPage = bdo_dashbord();
            break;
          case 'COO':
            targetPage = admin_dashboard();
            break;
          case 'CEO':
            targetPage = ceo_dashboard();
            break;
          case 'SD':
            targetPage = SdDashboard();
            break;
          case 'ADMIN':
            targetPage = admin_dashboard();
            break;
          case 'BDM':
            targetPage = bdm_dashbord();
            break;
          case 'Warehouse Admin':
            targetPage = WarehouseAdmin();
            break;
          case 'Marketing':
            targetPage = marketing_dashboard();
            break;
          case 'ASD':
            targetPage = asd_dashbord();
            break;
          case 'HR':
            targetPage = HrDashboard();
            break;
          default:
            targetPage = dashboard();
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Successfully logged in.'),
          ),
        );
      } else {}
    } catch (e) {}
  }

  Future login(String email, String password, BuildContext context) async {
    try {
      var response = await http.post(
        Uri.parse(url),
        body: {"username": email, "password": password},
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var status = responseData['status'];

        if (status == 'success') {
          var token = responseData['token'];
          var active = responseData['active'];
          var name = responseData['name'];
          var warehouse = responseData['warehouse_id'] ?? 0;

          try {
            final jwt = JWT.decode(token);
            var id = jwt.payload['id'];

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', id);
            await prefs.setString('token', token);
            await prefs.setString('username', name);
            await prefs.setInt('warehouse_id', warehouse);
            await storeUserData(token, active, name, warehouse);
          } catch (e) {}

          Widget targetPage;

          switch (active) {
            case 'Information Technology':
            case 'Accounts / Accounting':
              targetPage = dashboard();
              break;
            case 'warehouse':
              targetPage = WarehouseDashboard();
              break;
            case 'BDO':
              targetPage = bdo_dashbord();
              break;
            case 'SD':
              targetPage = SdDashboard();
              break;
            case 'COO':
              targetPage = ceo_dashboard();
              break;
            case 'CEO':
              targetPage = ceo_dashboard();
              break;
            case 'ADMIN':
              targetPage = admin_dashboard();
              break;
            case 'BDM':
              targetPage = bdm_dashbord();
              break;
            case 'Warehouse Admin':
              targetPage = WarehouseAdmin();
              break;
            case 'CSO':
              targetPage = cso_dashboard();
              break;
            case 'Marketing':
              targetPage = marketing_dashboard();
              break;
            case 'HR':
              targetPage = HrDashboard();
              break;
            default:
              targetPage = dashboard();
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Successfully logged in.'),
            ),
          );
        } else {
          String errorMessage = responseData['message'] ?? 'Login failed.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
          );
        }
      } else {
        String errorMessage = 'An error occurred. Please try again.';
        try {
          var responseData = jsonDecode(response.body);
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      floatingLabelStyle: const TextStyle(
        color: logoCyan,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: logoCyan),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: logoCyan.withOpacity(0.35),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: logoCyan,
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.7,
        ),
      ),
    );
  }

  Widget _gradientSignInButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            logoBlue1,
            logoBlue2,
            logoCyan,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: logoCyan.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                setState(() {
                  isLoading = true;
                });

                await login(email.text, password.text, context);

                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isLoading ? 'Signing in...' : 'Sign In',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _gradientFingerprintIcon() {
    return InkWell(
      onTap: biometricLogin,
      borderRadius: BorderRadius.circular(50),
      child: Container(
padding: const EdgeInsets.all(0),
       decoration: BoxDecoration(
  shape: BoxShape.circle,
  color: Colors.white,
  boxShadow: [
    BoxShadow(
color: Colors.black.withOpacity(0.12),      blurRadius: 12,
      offset: const Offset(0, 5),
    ),
  ],
),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [
                  logoBlue1,
                  logoBlue2,
                  logoCyan,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Icon(
              Icons.fingerprint,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: logoCyan,
          selectionColor: Color(0x5520B8F6),
          selectionHandleColor: logoCyan,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      "lib/assets/appstore.png",
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Login to your account",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: email,
                    cursorColor: logoCyan,
                    decoration: _inputDecoration(
                      label: 'Username',
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: password,
                    cursorColor: logoCyan,
                    obscureText: true,
                    decoration: _inputDecoration(
                      label: 'Password',
                      icon: Icons.lock,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _gradientSignInButton(),
                  const SizedBox(height: 15),
                  const DividerWithText(text: "OR"),
                  const SizedBox(height: 50),
                  _gradientFingerprintIcon(),
                  const SizedBox(height: 10),
                  const Text(
                    "Login with Biometrics",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 59, 165, 240),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.grey.withOpacity(0.35),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.grey.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}