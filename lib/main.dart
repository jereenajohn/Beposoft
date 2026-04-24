import 'dart:convert';

import 'package:beposoft/Sales%20Directors/SD_dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/ASD_dashborad.dart';
import 'package:beposoft/pages/ACCOUNTS/csodashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/provider.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/HR/hr_dashboard.dart';
import 'package:beposoft/pages/MARKETING/marketing_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const beposoftmain());
}

class beposoftmain extends StatefulWidget {
  const beposoftmain({super.key});

  @override
  State<beposoftmain> createState() => _beposoftmainState();
}

class _beposoftmainState extends State<beposoftmain> {
  bool tok = false;
  bool tokenn = true;
  bool isCheckingStartup = true;
  var department;

  @override
  void initState() {
    super.initState();
    startApp();
  }

  Future<void> startApp() async {
    await check();

    if (tokenn) {
      await getbank();
    }

    if (mounted) {
      setState(() {
        isCheckingStartup = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await checkAppUpdate(context);
    });
  }

  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> storeUserData(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> check() async {
    final token = await gettokenFromPrefs();

    if (token != null) {
      try {
        final jwt = JWT.decode(token);
        var dep = jwt.payload['active'];

        if (!mounted) return;
        setState(() {
          department = dep;
          tok = true;
        });
      } catch (e) {
        await clearToken();
        tokenn = false;
      }
    } else {
      tokenn = false;
    }
  }

  Future<void> getbank() async {
    final token = await gettokenFromPrefs();

    try {
      final response = await http.get(
        Uri.parse('$api/api/banks/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final parsed = jsonDecode(response.body);

      if (parsed['message'] == "Token has expired" ||
          parsed['message'] == "Invalid token") {
        await clearToken();
        if (!mounted) return;
        setState(() {
          tokenn = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        tokenn = false;
      });
    }
  }

  Future<void> clearToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('department');
    await prefs.remove('username');
    await prefs.remove('warehouse');
    await prefs.remove('warehouse_id');
    await prefs.remove('user_id');
  }

  void navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<bool> checkAppUpdate(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final response = await http.get(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
        ),
      );

      if (response.statusCode == 200) {
        final content = response.body;
        final versionRegex = RegExp(r'\[\[\["([0-9.]+)"\]\]');
        final match = versionRegex.firstMatch(content);

        if (match != null) {
          final storeVersion = match.group(1);
          if (storeVersion != null && storeVersion != currentVersion) {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Update Available'),
                content: Text(
                  'A new version ($storeVersion) is available. Please update the app.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Update Now'),
                    onPressed: () async {
                      final playStoreUrl = Uri.parse(
                        'https://play.google.com/store/apps/details?id=com.bepositive.beposoft',
                      );
                      if (await canLaunchUrl(playStoreUrl)) {
                        await launchUrl(
                          playStoreUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  TextButton(
                    child: const Text('Later'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            );
            return result == true;
          }
        }
      }
    } catch (e) {
      // log or ignore
    }

    return true;
  }

  Widget _getHomeScreen() {
    if (isCheckingStartup) {
      return const StartupShimmerScreen();
    }

    if (!tokenn) {
      return login();
    }

    return department == "BDM"
        ? bdm_dashbord()
        : department == "warehouse"
            ? WarehouseDashboard()
            : department == "SD"
                ? SdDashboard()
                : department == "BDO"
                    ? bdo_dashbord()
                    : department == "ADMIN"
                        ? admin_dashboard()
                        : department == "Accounts / Accounting"
                            ? admin_dashboard()
                            : department == "CEO"
                                ? ceo_dashboard()
                                : department == "CSO"
                                    ? cso_dashboard()
                                    : department == "ASD"
                                        ? asd_dashbord()
                                        : department == "Information Technology"
                                            ? admin_dashboard()
                                            : department == "HR"
                                                ? HrDashboard()
                                                : department ==
                                                        "Warehouse Admin"
                                                    ? WarehouseAdmin()
                                                    : department == "Marketing"
                                                        ? marketing_dashboard()
                                                        : department == "COO"
                                                            ? ceo_dashboard()
                                                            : dashboard();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final RenderBox? renderBoxNullable =
            context.findRenderObject() as RenderBox?;
        if (renderBoxNullable != null) {
          final RenderBox renderBox = renderBoxNullable;
        } else {}
      } catch (e) {}
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<counterModel>(create: (_) => counterModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _getHomeScreen(),
      ),
    );
  }
}

class StartupShimmerScreen extends StatefulWidget {
  const StartupShimmerScreen({super.key});

  @override
  State<StartupShimmerScreen> createState() => _StartupShimmerScreenState();
}

class _StartupShimmerScreenState extends State<StartupShimmerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _skeletonBox({
    required double height,
    required double width,
    double radius = 12,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xffE9EDF2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    Row(
                      children: [
                        _skeletonBox(height: 48, width: 48, radius: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _skeletonBox(height: 16, width: 140, radius: 8),
                              const SizedBox(height: 8),
                              _skeletonBox(height: 12, width: 90, radius: 8),
                            ],
                          ),
                        ),
                        _skeletonBox(height: 42, width: 42, radius: 12),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _skeletonBox(height: 24, width: 180, radius: 8),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _skeletonBox(
                            height: 110,
                            width: double.infinity,
                            radius: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _skeletonBox(
                            height: 110,
                            width: double.infinity,
                            radius: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _skeletonBox(
                            height: 110,
                            width: double.infinity,
                            radius: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _skeletonBox(
                            height: 110,
                            width: double.infinity,
                            radius: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _skeletonBox(height: 20, width: 120, radius: 8),
                    const SizedBox(height: 14),
                    _skeletonBox(
                      height: 78,
                      width: double.infinity,
                      radius: 16,
                    ),
                    const SizedBox(height: 12),
                    _skeletonBox(
                      height: 78,
                      width: double.infinity,
                      radius: 16,
                    ),
                    const SizedBox(height: 12),
                    _skeletonBox(
                      height: 78,
                      width: double.infinity,
                      radius: 16,
                    ),
                    const SizedBox(height: 12),
                    _skeletonBox(
                      height: 78,
                      width: double.infinity,
                      radius: 16,
                    ),
                    const SizedBox(height: 24),
                    _skeletonBox(height: 20, width: 150, radius: 8),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _skeletonBox(
                            height: 95,
                            width: double.infinity,
                            radius: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _skeletonBox(
                            height: 95,
                            width: double.infinity,
                            radius: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _skeletonBox(
                            height: 95,
                            width: double.infinity,
                            radius: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment(
                      -1.5 + (_controller.value * 3),
                      0,
                    ),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.55),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
