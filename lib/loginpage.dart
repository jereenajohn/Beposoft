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

import 'dart:convert';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  var url = "$api/api/login/";

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  bool isLoading = false;

  Future<void> storeUserData(String token, String department, String username,
      dynamic warehouse) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save the data into SharedPreferences
    await prefs.setString('token', token);
    await prefs.setString('department', department);
    await prefs.setString('username', username);

    // Handle warehouse based on its type
    if (warehouse is int) {
      await prefs.setInt('warehouse', warehouse);
    } else if (warehouse is String) {
      await prefs.setString('warehouse', warehouse);
    } else {}
  }

  final LocalAuthentication auth = LocalAuthentication();

Future<void> biometricLogin() async {
  try {
    final token = await getFingerprintTokenFromPrefs();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please login with username and password first to enable fingerprint login",
          ),
        ),
      );
      return;
    }

    final bool isSupported = await auth.isDeviceSupported();
    final bool canCheck = await auth.canCheckBiometrics;
    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();

    if (!isSupported || !canCheck || availableBiometrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Fingerprint/biometric is not available on this device"),
        ),
      );
      return;
    }

    final bool authenticated = await auth.authenticate(
      localizedReason: "Use fingerprint to login to Beposoft",
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (authenticated) {
      await addfingerprint();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text("Fingerprint login failed: $e"),
      ),
    );
  }
}
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

 Future<void> addfingerprint() async {
  final savedFingerprintToken = await getFingerprintTokenFromPrefs();

  if (savedFingerprintToken == null || savedFingerprintToken.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.orange,
        content: Text("Please login first"),
      ),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('$api/api/login/$savedFingerprintToken/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $savedFingerprintToken',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      /*
        Some APIs return a new token.
        Some APIs only validate the old token.
        So we safely use new token if available, otherwise old fingerprint token.
      */
      final String token =
          responseData['token']?.toString() ?? savedFingerprintToken;

      final userData = responseData['user'];

      String active = "";
      String name = "";
      int warehouseId = 0;
      int userId = 0;

      try {
        final jwt = JWT.decode(token);

        active = jwt.payload['active']?.toString() ??
            userData?['department']?.toString() ??
            responseData['active']?.toString() ??
            "";

        userId = jwt.payload['id'] is int
            ? jwt.payload['id']
            : int.tryParse(jwt.payload['id']?.toString() ?? "0") ?? 0;
      } catch (e) {
        active = userData?['department']?.toString() ??
            responseData['active']?.toString() ??
            "";
      }

      name = userData?['name']?.toString() ??
          responseData['name']?.toString() ??
          "";

      warehouseId = userData?['warehouse_id'] is int
          ? userData['warehouse_id']
          : int.tryParse(userData?['warehouse_id']?.toString() ?? "0") ?? 0;

      /*
        IMPORTANT:
        Restore the same SharedPreferences values saved during normal login.
        Otherwise dashboard pages may treat the user as guest/default.
      */
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('fingerprint_token', token);
      await prefs.setString('department', active);
      await prefs.setString('username', name);
      await prefs.setInt('warehouse_id', warehouseId);

      if (warehouseId != 0) {
        await prefs.setInt('warehouse', warehouseId);
      }

      if (userId != 0) {
        await prefs.setInt('user_id', userId);
      }

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
          targetPage = ceo_dashboard();
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
        case 'CSO':
          targetPage = cso_dashboard();
          break;
        default:
          targetPage = dashboard();
      }

      Navigator.pushReplacement(
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('fingerprint_token');
      await prefs.remove('token');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Saved login expired. Please login again."),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text("Fingerprint login failed: $e"),
      ),
    );
  }
}

Future<String?> getFingerprintTokenFromPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('fingerprint_token');
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
          var warehouse =
              responseData['warehouse_id'] ?? 0; // Default to 0 if null

          try {
            final jwt = JWT.decode(token);
            var id = jwt.payload['id']; // Expected to be an int
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', id); // Store user ID as an int
            await prefs.setString('token', token); // Store token
            await prefs.setString('username', name); // Store user name
            await prefs.setInt('warehouse_id', warehouse); // Store warehouse ID
            await storeUserData(token, active, name, warehouse);
            await prefs.setString('fingerprint_token', token);
          } catch (e) {}

          // Handle navigation based on active role
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
              context, MaterialPageRoute(builder: (context) => targetPage));

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: Colors.green,
                content: Text('Successfully logged in.')),
          );
        } else {
          // Show backend error message if available
          String errorMessage = responseData['message'] ?? 'Login failed.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
          );
        }
      } else {
        // Try to show backend error message if available
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
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Image.asset("lib/assets/beposoft_logo.png", height: 50),
                const SizedBox(height: 30),
                Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Login to your account",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading
                      ? null // Disable button if loading
                      : () async {
                          setState(() {
                            isLoading = true;
                          });

                          await login(email.text, password.text, context);

                          setState(() {
                            isLoading = false;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 3, 201, 219),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const Text('Signing in...',
                          style: TextStyle(fontSize: 16, color: Colors.white))
                      : const Text('Sign In',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 15),
                // DividerWithText(text: "OR"),
                // const SizedBox(height: 50),
                // InkWell(
                //   onTap: biometricLogin,
                //   borderRadius: BorderRadius.circular(50),
                //   child: Container(
                //     padding: const EdgeInsets.all(20),
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       color: Colors.grey[200],
                //       boxShadow: [
                //         BoxShadow(
                //             color: Colors.grey.withOpacity(0.4),
                //             blurRadius: 6,
                //             offset: Offset(0, 2)),
                //       ],
                //     ),
                //     child: Icon(Icons.fingerprint,
                //         size: 36,
                //         color: const Color.fromARGB(255, 3, 201, 219)),
                //   ),
                // ),
                // const SizedBox(height: 10),
                // Text("Login with Biometrics",
                //     style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                // const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(text, style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }
}
