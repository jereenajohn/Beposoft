import 'dart:convert';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:beposoft/pages/api.dart';

class update_supplier extends StatefulWidget {
  final int id;

  const update_supplier({super.key, required this.id});

  @override
  State<update_supplier> createState() => _update_supplierState();
}

class _update_supplierState extends State<update_supplier> {
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

  int? selectedStateId;
  int? selectedCountryId;

  bool loading = false;
  bool loadingPage = false;

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
    getSupplierDetails();
  }

  // ===================== GET COUNTRY =====================
  Future<void> getcountry() async {
    final token = await gettoken();
    try {
      final response =
          await http.get(Uri.parse('$api/api/country/codes/'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      List<Map<String, dynamic>> countrylist = [];

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var data = parsed['data'];

        for (var item in data) {
          countrylist.add({
            'id': item['id'],
            'country_code': item['country_code'],
          });
        }

        setState(() {
          country = countrylist;
        });
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
        var data = parsed['data'];

        for (var item in data) {
          statelist.add({
            'id': item['id'],
            'name': item['name'],
          });
        }

        setState(() {
          stat = statelist;
        });
      }
    } catch (error) {
      // print("❌ State Fetch Error: $error");
    }
  }

  // ===================== GET SUPPLIER DETAILS =====================
  Future<void> getSupplierDetails() async {
    setState(() {
      loadingPage = true;
    });

    try {
      final token = await gettoken();

      final response = await http.get(
        Uri.parse("$api/api/product/sellers/details/edit/${widget.id}/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // print("📌 Supplier Detail Status: ${response.statusCode}");
      // print("📌 Supplier Detail Body: ${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        var data = parsed["data"];

        setState(() {
          name.text = data["name"] ?? "";
          company_name.text = data["company_name"] ?? "";
          gstin.text = data["gstin"] ?? "";
          register_no.text = data["reg_no"] ?? "";
          phone.text = data["phone"] ?? "";
          alt_phone.text = data["alt_phone"] ?? "";
          email.text = data["email"] ?? "";
          address.text = data["address"] ?? "";
          zipcode.text = data["zipcode"] ?? "";

          selectedStateId = data["state"];
          selectedCountryId = data["country"];
        });
      }
    } catch (e) {
      // print("❌ Supplier Detail Fetch Error: $e");
    }

    setState(() {
      loadingPage = false;
    });
  }

  // ===================== UPDATE SUPPLIER PUT =====================
  Future<void> updateSupplier() async {
    final token = await gettoken();

    if (name.text.isEmpty || phone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Name and Phone are required")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.put(
        Uri.parse("$api/api/product/sellers/details/edit/${widget.id}/"),
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

      // print("📌 Update Supplier Status: ${response.statusCode}");
      // print("📌 Update Supplier Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Supplier Updated Successfully")),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to Update Supplier")),
        );
      }
    } catch (e) {
      // print("❌ Update Supplier Error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Update Supplier",
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
      body: loadingPage
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 15),

                  Padding(
                    padding:
                        const EdgeInsets.only(right: 10, top: 10, left: 10),
                    child: Container(
                      width: 600,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 34, 165, 246),
                        border: Border.all(
                            color: Color.fromARGB(255, 202, 202, 202)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Text(
                            " Update Supplier ",
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

                  Padding(
                    padding:
                        const EdgeInsets.only(top: 25, left: 15, right: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 202, 202, 202)),
                      ),
                      width: 700,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),

                            Text("Name",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Company Name",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Gst Number",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Register Number",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Phone Number",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Alternate Number",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Email",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("Address",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: TextField(
                                controller: address,
                                maxLines: 4,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  alignLabelWithHint: true,
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

                            Text("Zipcode",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            Text("State",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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

                            Text("Country",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 270,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : updateSupplier,
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        Color.fromARGB(255, 64, 176, 251),
                                      ),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    child: loading
                                        ? CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text("Update",
                                            style:
                                                TextStyle(color: Colors.white)),
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
                ],
              ),
            ),
    );
  }
}
