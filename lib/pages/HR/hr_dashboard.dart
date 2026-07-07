import 'dart:convert';
import 'dart:io';
import 'package:beposoft/pages/ACCOUNTS/add_self_attendance.dart';
import 'package:beposoft/pages/ADMIN/add_attendance.dart';
import 'package:beposoft/pages/BDO/EmployeeLeaveFormPage%20.dart';
import 'package:beposoft/pages/auth_status_checker.dart';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/Staff_exit_form_page.dart';
import 'package:beposoft/pages/ACCOUNTS/add_staff.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/profilepage.dart';
import 'package:beposoft/pages/ACCOUNTS/staff_exit_form_list.dart';
import 'package:beposoft/pages/ACCOUNTS/view_staff.dart';
import 'package:beposoft/pages/HR/EmployeeLeaveListPage.dart';
import 'package:beposoft/pages/HR/add_teamlead.dart';
import 'package:beposoft/pages/HR/attendance.dart';
import 'package:beposoft/pages/HR/staff_attendance.dart';
import 'package:beposoft/pages/logout_hekper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class HrDashboard extends StatefulWidget {
  const HrDashboard({super.key});

  @override
  State<HrDashboard> createState() => _HrDashboardState();
}

class _HrDashboardState extends State<HrDashboard> {
  String? username = '';
  void initState() {
    super.initState();
    _getUsername(); // Get the username when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthStatusChecker.start(context);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppUpdate(context);
    });
  }

  Future<String?> getusernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // Retrieve the username from SharedPreferences
  Future<void> _getUsername() async {
    final name = await getusernameFromPrefs();
    setState(() {
      username = name ?? 'Guest'; // Default to 'Guest' if no username
    });
  }

  bool _isUpdateAvailable(String currentVersion, String storeVersion) {
    List<int> currentParts =
        currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    List<int> storeParts =
        storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    int maxLength = currentParts.length > storeParts.length
        ? currentParts.length
        : storeParts.length;

    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }
    while (storeParts.length < maxLength) {
      storeParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (storeParts[i] > currentParts[i]) {
        return true;
      } else if (storeParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  Future<bool> checkAppUpdate(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      String? storeVersion;
      Uri? storeUrl;

      if (Platform.isAndroid) {
        final response = await http.get(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.bepositive.beposoft&hl=en',
        ));

        if (response.statusCode == 200) {
          final content = response.body;
          final versionRegex = RegExp(r'\[\[\["([0-9.]+)"\]\]');
          final match = versionRegex.firstMatch(content);

          if (match != null) {
            storeVersion = match.group(1);
            storeUrl = Uri.parse(
              'https://play.google.com/store/apps/details?id=com.bepositive.beposoft',
            );
          }
        }
      } else if (Platform.isIOS) {
        final response = await http.get(
          Uri.parse('https://itunes.apple.com/lookup?id=6748010646&country=in'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['resultCount'] != null &&
              data['resultCount'] > 0 &&
              data['results'] != null &&
              data['results'] is List &&
              data['results'].isNotEmpty) {
            final appData = data['results'][0];
            storeVersion = appData['version']?.toString();
            storeUrl = Uri.parse(
              'https://apps.apple.com/in/app/beposoft/id6748010646',
            );
          }
        }
      }

      if (storeVersion != null &&
          _isUpdateAvailable(currentVersion, storeVersion)) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.only(top: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Column(
              children: [
                Icon(
                  Icons.system_update,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Update Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'A new version ($storeVersion) is available.\n\nYou are using $currentVersion.\n\nPlease update the app to continue enjoying the latest features and improvements.',
              style: const TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: const Text("Update Now"),
                onPressed: () async {
                  if (storeUrl != null && await canLaunchUrl(storeUrl)) {
                    await launchUrl(
                      storeUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text("Maybe Later"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        return result == true;
      }
    } catch (e) {
      // Optional: print(e);
    }

    return true;
  }

  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      iconColor: Colors.black,
      collapsedIconColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      children: options.map((option) {
        return ListTile(
          tileColor: Colors.white,
          title: Text(
            option,
            style: const TextStyle(color: Colors.black),
          ),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('userId');
    // await prefs.remove('token');

    // Show the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged out successfully'),
        duration: Duration(seconds: 2),
      ),
    );

    // Wait for the SnackBar to disappear before navigating
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  drower d = drower();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HR Dashboard',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        "lib/assets/appstore.png",
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HrDashboard()));
                },
              ),
                //   ListTile(
                //   leading: Icon(Icons.person),
                //   title: Text('Add Attendance'),
                //   onTap: () {
                //     Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //             builder: (context) => StaffSelfAttendanceScreen()));
                //     // Navigate to the Settings page or perform any other action
                //   },
                // ),
                //   ListTile(
                //     leading: const Icon(Icons.fact_check_outlined),
                //     title: const Text('Approve Team Attendance'),
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) =>
                //               const StaffMarkAttendanceScreen(),
                //         ),
                //       );
                //     },
                //   ),

               _buildDropdownTile(context, 'Attendance', [
                    'Add Your Attendance',
                    'Approve Your Team Attendance',
                    'Add Department & Managers',
                    'Add Dept-wise Staffs',
                    'Add & Approve All Attendance',
                    'View Attendance',
                    // 'Employee Leave Requests',
                    // 'View Leave List',
                  ]),
              // Divider(),
              ListTile(
                title: Text('Staffs'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => staff_list()));
                },
              ),
              ListTile(
                title: Text('Add Staff'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => add_staff()));
                },
              ),

              ListTile(
                title: Text('Add Staff Exit Form'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EmployeeExitFormPage()));
                },
              ),

              ListTile(
                title: Text('Staff Exit Form List'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EmployeeExitListPage()));
                },
              ),

              ListTile(
                title: Text('Employee Leave List'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EmployeeLeaveListPage()));
                },
              ),
              // ListTile(
              //   title: Text('Add Manager'),
              //   onTap: () {
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (context) => StaffAttendanceTeamScreen()));
              //   },
              // ),
              // ListTile(
              //   title: Text('Staff Attendance'),
              //   onTap: () {
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (context) => HrTeamAttendanceScreen()));
              //   },
              // ),

              ListTile(
                title: Text('Employee Leave Form'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EmployeeLeaveFormPage()));
                },
              ),

              // Divider(),
              // ListTile(
              //   leading: Icon(Icons.chat),
              //   title: Text('Chat'),
              //   onTap: () {
              //     Navigator.pop(context); // Close the drawer
              //   },
              // ),
              Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await logoutUser(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage(
                          'lib/assets/female.jpeg'), // Replace with your new image
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    '$username',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              SizedBox(height: 10),

              Expanded(
                child: ListView(
                  children: [
                    // Display the count of today's shipped orders in cards
                    // GestureDetector(
                    //   onTap: () {
                    //               Navigator.push(
                    //       context,
                    //       MaterialPageRoute(builder: (context) => AttendanceSheet()),
                    //     );
                    //   },
                    //   child: _buildCard(
                    //     Icons.calendar_today,
                    //     'Attendance  ',
                    //   ),
                    // ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => add_staff()),
                        );
                      },
                      child: _buildCard(
                        Icons.person,
                        'Staff',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCard(IconData icon, String title, [int count = 0]) {
  return Container(
    height: 120.0, // Set a fixed height for each card
    margin: EdgeInsets.symmetric(vertical: 8.0),
    child: Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 20,
              ),
              ListTile(
                leading: Icon(icon, size: 40, color: Colors.blue),
                title:
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  // Handle item tap if needed
                },
              ),
            ],
          ),
          if (count > 0)
            Positioned(
              top: 8.0,
              right: 8.0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
