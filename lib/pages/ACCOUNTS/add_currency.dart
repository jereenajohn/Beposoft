import 'dart:convert';

import 'package:beposoft/loginpage.dart';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_bank.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class add_currency extends StatefulWidget {
  const add_currency({super.key});

  @override
  State<add_currency> createState() => _add_currencyState();
}

class _add_currencyState extends State<add_currency> {
  drower d = drower();
  Widget _buildDropdownTile(
      BuildContext context, String title, List<String> options) {
    return ExpansionTile(
      title: Text(title),
      children: options.map((option) {
        return ListTile(
          title: Text(option),
          onTap: () {
            Navigator.pop(context);
            d.navigateToSelectedPage(context, option);
          },
        );
      }).toList(),
    );
  }

  TextEditingController name = TextEditingController();

  List<Map<String, dynamic>> currency = [];
  List<Map<String, dynamic>> country = [];
  String? selectedCountryId;

  bool isEdit = false;
  int? selectedCurrencyId;

  

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  @override
  void initState() {
    super.initState();
    getcurrency();
    getcountry();
  }

  Future<void> getcountry() async {
    final token = await gettoken();
    try {
      final response =
          await http.get(Uri.parse('$api/api/country/codes/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      List<Map<String, dynamic>> countrylist = [];

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          countrylist.add({
            'id': productData['id'].toString(),
            'country_code': productData['country_code'],
          });
        }

        print(countrylist);
        setState(() {
          country = countrylist;
        });
      }
    } catch (e) {}
  }

  Future<void> saveCurrency(BuildContext scaffoldContext) async {
    final token = await gettoken();
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Currency is required")),
      );
      return;
    }

    if (selectedCountryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select country")),
      );
      return;
    }
    try {
      final url = isEdit
          ? '$api/api/currency/edit/$selectedCurrencyId/'
          : '$api/api/currency/add/';
      final response = await (isEdit
          ? http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'currency': name.text,
                'country': selectedCountryId,
              }),
            )
          : http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'currency': name.text,
                'country': selectedCountryId,
              }),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(isEdit
                ? 'Currency updated successfully.'
                : 'Currency added successfully.'),
          ),
        );

        // reset form
        setState(() {
          isEdit = false;
          selectedCurrencyId = null;
          selectedCountryId = null;
          name.clear();
        });

        getcurrency(); // 🔁 refresh list
      } else {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Operation failed.'),
          ),
        );
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<void> getcurrency() async {
    final token = await gettoken();
    try {
      final response =
          await http.get(Uri.parse('$api/api/currency/add/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      print(response.statusCode);
      print(response.body);
      List<Map<String, dynamic>> currencylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          currencylist.add({
            'id': productData['id'],
            'name': productData['currency'],
            'country': productData['country'],
            'country_name': productData['country_name'],
          });
        }

        setState(() {
          currency = currencylist;
        });
      }
    } catch (e) {}
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    await Future.delayed(Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Add Currency",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final dep = await getdepFromPrefs();
            if (dep == "BDO") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdo_dashbord()),
              );
            } else if (dep == "BDM") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdm_dashbord()),
              );
            } else if (dep == "CEO") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ceo_dashboard()), // Replace AnotherPage with your target page
              );
            } else if (dep == "COO") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ceo_dashboard()), // Replace AnotherPage with your target page
              );
            } else if (dep == "ADMIN") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        admin_dashboard()), // Replace AnotherPage with your target page
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        dashboard()), // Replace AnotherPage with your target page
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: Image.asset('lib/assets/profile.png'),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
          child: Container(
        child: Column(
          children: [
            SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 10, left: 10),
              child: Container(
                width: 600,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 34, 165, 246),
                  border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      " CURRENCY DETAILS ",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(
                      height: 13,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border:
                        Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                  ),
                  width: 700,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(height: 10),

// ================= COUNTRY DROPDOWN =================
                        Text(
                          "Country",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: 5),

                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: DropdownButtonFormField<String>(
                            value: country.any((c) =>
                                    c['id'].toString() ==
                                    selectedCountryId.toString())
                                ? selectedCountryId?.toString()
                                : null,
                            hint: Text("Select Country"),
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                            ),
                            items: country.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['id'].toString(),
                                child: Text(
                                  c['country_code'], // 👉 OR "IN - India" if backend supports
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCountryId = value;
                              });
                            },
                          ),
                        ),

                        SizedBox(height: 10),

// ================= CURRENCY FIELD =================
                        Text(
                          "Currency Name",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Container(
                            child: TextField(
                              controller: name,
                              decoration: InputDecoration(
                                labelText: 'Currency Name',

                                labelStyle: TextStyle(
                                  fontSize: 12.0, // Set your desired font size
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0), // Set vertical padding
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                              ),
                              SizedBox(
                                width: 270,
                                child: ElevatedButton(
                                  onPressed: () {
                                    saveCurrency(context);
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Color.fromARGB(255, 64, 176, 251),
                                    ),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            10), // Set your desired border radius
                                      ),
                                    ),
                                    fixedSize: MaterialStateProperty.all<Size>(
                                      Size(95,
                                          15), // Set your desired width and heigh
                                    ),
                                  ),
                                  child: Text(
                                    isEdit ? "Update" : "Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ]),
                        SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  )),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Available Currency",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15, bottom: 55),
              child: Container(
                color: Colors.white,
                child: Table(
                  border: TableBorder.all(
                      color: Color.fromARGB(255, 214, 213, 213)),
                  columnWidths: {
                    0: FixedColumnWidth(40.0),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FixedColumnWidth(50.0),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 64, 176, 251),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "No.",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Country Name",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "symbol",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    for (int i = 0; i < currency.length; i++)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text((i + 1).toString()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(currency[i]['country_name'] ?? "N/A"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(currency[i]['name']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isEdit = true;
                                  selectedCurrencyId = currency[i]['id'];
                                  name.text = currency[i]['name'];

                                  selectedCountryId =
                                      currency[i]['country']?.toString();
                                });
                              },
                              child: Image.asset(
                                "lib/assets/edit.jpg",
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      )),
    );
  }
}
