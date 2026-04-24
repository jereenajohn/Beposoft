import 'dart:convert';

import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/update_supplier.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class add_supplier extends StatefulWidget {
  const add_supplier({super.key});

  @override
  State<add_supplier> createState() => _add_supplierState();
}

class _add_supplierState extends State<add_supplier> {
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
  TextEditingController company_name = TextEditingController();
  TextEditingController gstin = TextEditingController();
  TextEditingController register_no = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController alt_phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController zipcode = TextEditingController();

  List<Map<String, dynamic>> country = [];
  List<Map<String, dynamic>> stat = [];

  List<Map<String, dynamic>> supplierList = [];

  int? selectedStateId;
  int? selectedCountryId;

  bool loading = false;
  bool loadingSupplier = false;

  Future<String?> gettoken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  @override
  void initState() {
    super.initState();
    getcountry();
    getstate();
    getSuppliers();
  }

  // ===================== GET COUNTRY =====================
  Future<void> getcountry() async {
    final token = await gettoken();
    try {
      final response =
          await http.get(Uri.parse('$api/api/country/codes/'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      List<Map<String, dynamic>> countrylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          countrylist.add({
            'id': productData['id'],
            'country_code': productData['country_code'],
          });
        }

        setState(() {
          country = countrylist;
        });
      } else {
        // print("❌ Country API error: ${response.statusCode}");
      }
    } catch (e) {
      // print("❌ Country Fetch Error: $e");
    }
  }

  // ===================== GET STATE =====================
  Future<void> getstate() async {
    try {
      final token = await gettoken();

      var response = await http.get(
        Uri.parse('$api/api/states/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> statelist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          statelist.add({
            'id': productData['id'],
            'name': productData['name'],
          });
        }

        setState(() {
          stat = statelist;
        });
      } else {
        // print("❌ State API error: ${response.statusCode}");
      }
    } catch (error) {
      // print("❌ State Fetch Error: $error");
    }
  }

  // ===================== GET SUPPLIERS =====================
  Future<void> getSuppliers() async {
    setState(() {
      loadingSupplier = true;
    });

    try {
      final token = await gettoken();

      final response = await http.get(
        Uri.parse("$api/api/product/sellers/details/add/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // print("Supplier List Status: ${response.statusCode}");
      // print("Supplier List Body: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List data = parsed["data"] ?? [];

        List<Map<String, dynamic>> temp = [];

        for (var item in data) {
          temp.add({
            "id": item["id"],
            "name": item["name"] ?? "",
            "company_name": item["company_name"] ?? "",
            "gstin": item["gstin"] ?? "",
            "reg_no": item["reg_no"] ?? "",
            "phone": item["phone"] ?? "",
            "alt_phone": item["alt_phone"] ?? "",
            "email": item["email"] ?? "",
            "address": item["address"] ?? "",
            "zipcode": item["zipcode"] ?? "",
            "state": item["state"] ?? "",
            "country": item["country"] ?? "",
          });
        }

        setState(() {
          supplierList = temp;
        });
      }
    } catch (e) {
      // print("Error fetching suppliers: $e");
    }

    setState(() {
      loadingSupplier = false;
    });
  }

  // ===================== ADD SUPPLIER POST =====================
  Future<void> addSupplier() async {
    final token = await gettoken();

    if (name.text.isEmpty || phone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Name and Phone are required")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$api/api/product/sellers/details/add/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name.text,
          "company_name": company_name.text,
          "gstin": gstin.text,
          "reg_no": register_no.text,
          "phone": phone.text,
          "alt_phone": alt_phone.text,
          "email": email.text,
          "address": address.text,
          "zipcode": zipcode.text,
          "state": selectedStateId,
          "country": selectedCountryId,
        }),
      );

      // print("Add Supplier Status: ${response.statusCode}");
      // print("Add Supplier Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Supplier Added Successfully")),
        );

        name.clear();
        company_name.clear();
        gstin.clear();
        register_no.clear();
        phone.clear();
        alt_phone.clear();
        email.clear();
        address.clear();
        zipcode.clear();

        setState(() {
          selectedStateId = null;
          selectedCountryId = null;
        });

        getSuppliers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(" Failed to Add Supplier")),
        );
      }
    } catch (e) {
      // print(" Error adding supplier: $e");
    }

    setState(() {
      loading = false;
    });
  }

  // ===================== LOGOUT =====================
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

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Add Supplier",
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
                MaterialPageRoute(builder: (context) => ceo_dashboard()),
              );
            } else if (dep == "COO") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ceo_dashboard()),
              );
            } else if (dep == "ADMIN") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => admin_dashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => dashboard()),
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
        child: Column(
          children: [
            SizedBox(height: 15),

            // ================= HEADER =================
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
                    SizedBox(height: 10),
                    Text(
                      " Add Suppliers ",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 13),
                  ],
                ),
              ),
            ),

            // ================= FORM =================
            Padding(
              padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Color.fromARGB(255, 202, 202, 202)),
                ),
                width: 700,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),

                      // Name
                      Text("Name",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: name,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Company Name
                      Text("Company Name",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: company_name,
                          decoration: InputDecoration(
                            labelText: 'Company Name',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // GST
                      Text("Gst Number",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: gstin,
                          decoration: InputDecoration(
                            labelText: 'Gst Number',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Register No
                      Text("Register Number",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: register_no,
                          decoration: InputDecoration(
                            labelText: 'Register Number',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Phone
                      Text("Phone Number",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Alternate Phone
                      Text("Alternate Number",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: alt_phone,
                          decoration: InputDecoration(
                            labelText: 'Alternate Number',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Email
                      Text("Email",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: email,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Address
                      Text("Address",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: address,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            alignLabelWithHint: true, // ✅ Label stays top
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 12.0),
                          ),
                        ),
                      ),

                      SizedBox(height: 10),

                      // Zipcode
                      Text("Zipcode",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TextField(
                          controller: zipcode,
                          decoration: InputDecoration(
                            labelText: 'Zipcode',
                            labelStyle: TextStyle(fontSize: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // State Dropdown
                      Text("State",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: DropdownButtonFormField<int>(
                          value: selectedStateId,
                          decoration: InputDecoration(
                            labelText: "Select State",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: stat.map((item) {
                            return DropdownMenuItem<int>(
                              value: item["id"],
                              child: Text(item["name"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStateId = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 10),

                      // Country Dropdown
                      Text("Country",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: DropdownButtonFormField<int>(
                          value: selectedCountryId,
                          decoration: InputDecoration(
                            labelText: "Select Country",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: country.map((item) {
                            return DropdownMenuItem<int>(
                              value: item["id"],
                              child: Text(item["country_code"]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCountryId = value;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      // Submit Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 270,
                            child: ElevatedButton(
                              onPressed: loading ? null : addSupplier,
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                  Color.fromARGB(255, 64, 176, 251),
                                ),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              child: loading
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text("Submit",
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 15),

            // ================= TABLE TITLE =================
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Available Suppliers",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            // ================= SUPPLIER TABLE =================
            Padding(
              padding: const EdgeInsets.only(right: 15, left: 15, bottom: 55),
              child: Container(
                color: Colors.white,
                child: loadingSupplier
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Table(
                        border: TableBorder.all(
                            color: Color.fromARGB(255, 214, 213, 213)),
                        columnWidths: {
                          0: FixedColumnWidth(40.0),
                          1: FlexColumnWidth(2),
                          2: FixedColumnWidth(50.0),
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
                                  "Supplier Name",
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
                          for (int i = 0; i < supplierList.length; i++)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text((i + 1).toString()),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(supplierList[i]['name']),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => update_supplier(
                                            id: supplierList[i]["id"]),
                                      ),
                                    );

                                    if (updated == true) {
                                      getSuppliers();
                                    }
                                  },
                                  child: Image.asset(
                                    "lib/assets/edit.jpg",
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
