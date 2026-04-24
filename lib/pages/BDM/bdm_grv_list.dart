import 'dart:convert';
import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class bdm_GrvList extends StatefulWidget {
  var status;
  var family;
  bdm_GrvList({super.key,required this.status,required this.family});

  @override
  State<bdm_GrvList> createState() => _bdm_GrvListState();
}

class _bdm_GrvListState extends State<bdm_GrvList> {
  List<Map<String, dynamic>> grvlist = [];
  List<String> remarkOptions = ["return", "refund"];
  List<String> statusOptions = ["pending", "approved", "rejected"];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  String selectedStatus = ""; // Default selected status

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getprofiledata();
  }

  // Get token from SharedPreferences
  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
   var family='';

Future<void> getprofiledata() async {
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        

        setState(() {
         
          family = productsData['family'].toString() ?? '';
          
        
        });
    getGrvList();

      }
    } catch (error) {
      
    }
  }
  Future<void> getGrvList() async {
    setState(() {
      isLoading = true;
    });
    try {
      final token = await getTokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/api/grv/data/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        List<Map<String, dynamic>> grvDataList = [];
        for (var productData in productsData) {
          if(widget.status==null){

          if(family==productData['family']){
          grvDataList.add({
            'id': productData['id'],
            'product': productData['product'],
            'returnreason': productData['returnreason'],
            'invoice': productData['invoice'],
            'customer': productData['customer'],
            'staff': productData['staff'],
            'remark': productData['remark'],
            'status': productData['status'] ?? statusOptions[0],
            'order_date': productData['order_date'],
          });}}
          else if(widget.status==productData['status']){
            if(family.toString()==productData['family'].toString())
                   {
                    
             grvDataList.add({
            'id': productData['id'],
            'product': productData['product'],
            'returnreason': productData['returnreason'],
            'invoice': productData['invoice'],
            'customer': productData['customer'],
            'staff': productData['staff'],
            'remark': productData['remark'],
            'status': productData['status'] ?? statusOptions[0],
            'order_date': productData['order_date'],
          });
          }
          }
        }
        setState(() {
          grvlist = grvDataList;
          filteredProducts = grvDataList; // Initially show all items
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch GRV data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching GRV data'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update GRV item data
  Future<void> updateGrvItem(int id, String status, String remark) async {
    try {
      final token = await getTokenFromPrefs();

      // Get current time and format it correctly
      String formattedTime = DateFormat("HH:mm").format(DateTime.now());

      

      var response = await http.put(
        Uri.parse('$api/api/grv/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'remark': remark,
          'updated_at': DateTime.now().toIso8601String().split('T')[0],
          'time': formattedTime,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          grvlist = grvlist.map((item) {
            if (item['id'] == id) {
              item['status'] = status;
              item['remark'] = remark;
            }
            return item;
          }).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GRV updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update GRV'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating GRV'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Filter GRV list based on status and search query
  void _filterProducts(String query) {
    setState(() {
      filteredProducts = grvlist.where((product) {
        final matchesStatus =
            selectedStatus.isEmpty || product['status'] == selectedStatus;
        final matchesSearch = query.isEmpty ||
            product['product'].toLowerCase().contains(query.toLowerCase()) ||
            product['invoice'].toLowerCase().contains(query.toLowerCase()) ||
            product['customer'].toLowerCase().contains(query.toLowerCase()) ||
            product['staff'].toLowerCase().contains(query.toLowerCase());

        return matchesStatus && matchesSearch; // Both filters must match
      }).toList();
    });
  }


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
            d.navigateToSelectedPage(
                context, option); // Navigate to selected page
          },
        );
      }).toList(),
    );
  }
Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  Future<void> _navigateBack() async {
    final dep = await getdepFromPrefs();
   if(dep=="BDO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
            );

}
else if(dep=="BDM" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
            );
}
else if(dep=="warehouse" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="CEO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}
else if(dep=="COO" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ceo_dashboard()), // Replace AnotherPage with your target page
            );
}


else if(dep=="Warehouse Admin" ){
   Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
            );
}else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent the swipe-back gesture (and back button)
        _navigateBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: Text(
            "GRV List",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Custom back arrow
            onPressed: () async{
                      final dep= await getdepFromPrefs();
      if(dep=="BDO" ){
         Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdo_dashbord()), // Replace AnotherPage with your target page
              );
      
      }
      else if(dep=="BDM" ){
         Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => bdm_dashbord()), // Replace AnotherPage with your target page
              );
      }
      
      else if(dep=="warehouse" ){
         Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseDashboard()), // Replace AnotherPage with your target page
              );
      }
      else if(dep=="Warehouse Admin" ){
         Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehouseAdmin()), // Replace AnotherPage with your target page
              );
      }
      else {
      Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => dashboard()), // Replace AnotherPage with your target page
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
         
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search GRV...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (query) =>
                          _filterProducts(query), // Pass the query here
                    ),
                  ),
                  Padding(
  padding: const EdgeInsets.all(8.0),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.blue),
      borderRadius: BorderRadius.circular(30.0),
    ),
    child: DropdownButton<String>(
      value: selectedStatus.isEmpty ? null : selectedStatus,
      items: statusOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            selectedStatus = newValue;
          });
          _filterProducts(searchController.text); // Re-filter based on the selected status
        }
      },
      isExpanded: true,
      underline: const SizedBox(), // Removes default underline
      hint: const Text("Search by Status"),
    ),
  ),
),

                 Expanded(
  child: filteredProducts.isEmpty
      ? const Center(
          child: Text(
            "No GRV present",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final item = filteredProducts[index];

            return Card(
              elevation: 4,
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product: ${item['product']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text("Invoice: ${item['invoice']}"),
                    Text("Customer: ${item['customer']}"),
                    Text("Staff: ${item['staff']}"),
                    const Divider(color: Colors.blue, thickness: 1),
                    Text("Return Reason: ${item['returnreason']}"),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Remark:"),
                        DropdownButton<String>(
                          key: Key("remark-${item['id']}"),
                          value: item['remark'],
                          hint: const Text("Select Remark"),
                          items: remarkOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                item['remark'] = newValue;
                              });
                              updateGrvItem(item['id'], item['status'], newValue);
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Status:"),
                        DropdownButton<String>(
                          key: Key("status-${item['id']}"),
                          value: item['status'],
                          items: statusOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                item['status'] = newValue;
                              });
                              updateGrvItem(item['id'], newValue, item['remark'] ?? "");
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.blue, thickness: 1),
                    Text("Created At: ${item['order_date']}"),
                  ],
                ),
              ),
            );
          },
        ),
),

                ],
              ),
      ),
    );
  }
}
