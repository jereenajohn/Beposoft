import 'dart:convert';
import 'dart:math';

import 'package:beposoft/loginpage.dart';

import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/emireport.dart';
import 'package:beposoft/pages/ACCOUNTS/update_department.dart';
import 'package:beposoft/pages/ADMIN/admin_dashboard.dart';
import 'package:beposoft/pages/ADMIN/ceo_dashboard.dart';
import 'package:beposoft/pages/BDM/bdm_dshboard.dart';
import 'package:beposoft/pages/BDO/bdo_dashboard.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_admin.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:beposoft/pages/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class add_Emi extends StatefulWidget {
  const add_Emi({super.key});

  @override
  State<add_Emi> createState() => _add_EmiState();
}

class _add_EmiState extends State<add_Emi> {
  double calculatedEmi = 0.0;
  double totalInterestAmount = 0.0;
  double totalAmountWithInterest = 0.0;
  List<Map<String, dynamic>> emiList = [];

  @override
  void initState() {
    super.initState();
    getemi();

    price.addListener(calculateEmi);
    interst.addListener(calculateEmi);
    year.addListener(calculateEmi);
    downpay.addListener(calculateEmi);
  }

  @override
  void dispose() {
    price.removeListener(calculateEmi);
    interst.removeListener(calculateEmi);
    year.removeListener(calculateEmi);
    downpay.removeListener(calculateEmi);

    price.dispose();
    interst.dispose();
    year.dispose();
    downpay.dispose();
    super.dispose();
  }

  var url = "$api/api/add/department/";

  TextEditingController price = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController interst = TextEditingController();
  TextEditingController year = TextEditingController();
  TextEditingController downpay = TextEditingController();
  Future<String?> gettokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  DateTime selectedDate = DateTime.now();
  DateTime selectedDate2 = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectDate2(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate2) {
      setState(() {
        selectedDate2 = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  var departments;
  List<Map<String, dynamic>> dep = [];

  Future<void> getemi() async {
    try {
      final token = await gettokenFromPrefs();

      var response = await http.get(
        Uri.parse('$api/apis/emi/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      List<Map<String, dynamic>> emiDataList = [];
      
      ;
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        var productsData = parsed['data'];

        for (var productData in productsData) {
          emiDataList.add({
            'id': productData['id'],
            'emi_name': productData['emi_name'],
            'emi': productData['emi'],
            'principal': productData['principal'],
            'annual_interest_rate': productData['annual_interest_rate'],
            'tenure_months': productData['tenure_months'],
            'down_payment': productData['down_payment'],
            "startdate": productData['startdate'],
            'enddate': productData['enddate'],
            'emi_amount': productData['emi_amount'],
            'total_interest': productData['total_interest'],
            'total_payment': productData['total_payment'],
          });
        }
        setState(() {
          emiList = emiDataList;
        });
      }
    } catch (error) {
      // Handle error
    }
  }
void adddepartment(BuildContext context) async {
  final token = await gettokenFromPrefs();

  try {
    var response = await http.post(
      Uri.parse('$api/apis/emi/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'emi_name': name.text,
        "principal": price.text,
        "down_payment": downpay.text,
        "annual_interest_rate": interst.text,
        "tenure_months": year.text,
        "startdate": formatDate(selectedDate).toString(),
        "enddate": formatDate(selectedDate2).toString(),
        "emi_amount": double.parse(calculatedEmi.toStringAsFixed(2)).toString(),
        "total_interest": double.parse(totalInterestAmount.toStringAsFixed(2)).toString(),
        "total_payment": double.parse(totalAmountWithInterest.toStringAsFixed(2)).toString(),
      },
    );

    ;

    if (response.statusCode == 201) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => add_Emi()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 49, 212, 4),
          content: Text('Success'),
        ),
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


  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');

    // Use a post-frame callback to show the SnackBar after the current frame
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

    // Wait for the SnackBar to disappear before navigating
    await Future.delayed(Duration(seconds: 2));

    // Navigate to the HomePage after the snackbar is shown
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login()),
    );
  }

  void removeProduct(int index) {
    setState(() {
      dep.removeAt(index);
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

  //searchable dropdown

  String? selectedValue;
  final TextEditingController textEditingController = TextEditingController();

  Future<String?> getdepFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('department');
  }

  // Method to calculate EMI
  void calculateEmi() {
    double principal = double.tryParse(price.text) ?? 0.0;
    double downPayment = double.tryParse(downpay.text) ?? 0.0;
    double annualInterestRate = double.tryParse(interst.text) ?? 0.0;
    int tenureMonths = int.tryParse(year.text) ?? 0;

    double P = principal - downPayment;
    double R = (annualInterestRate / 12) / 100;
    int N = tenureMonths;

    double emi;
    if (R == 0) {
      emi = P / N;
    } else {
      emi = (P * R * pow(1 + R, N)) / (pow(1 + R, N) - 1);
    }

    double totalInterest = emi * N - P;
    double totalAmount = P + totalInterest;

    setState(() {
      calculatedEmi = emi.isNaN ? 0.0 : emi;
      totalInterestAmount = totalInterest.isNaN ? 0.0 : totalInterest;
      totalAmountWithInterest = totalAmount.isNaN ? 0.0 : totalAmount;
    });
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
    double screenWidth = MediaQuery.of(context).size.width; // Get screen width
    double containerWidth = screenWidth * 0.9; // Set width to 90% of screen
    double iconSpacing = screenWidth * 0.4; // Adjust icon spacing dynamically
    return Scaffold(
      backgroundColor: Color.fromARGB(242, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          "Add Emi",
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Color.fromARGB(255, 202, 202, 202)),
                      ),
                      width: constraints.maxWidth * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: constraints.maxWidth * 0.9,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 2, 65, 96),
                                border: Border.all(
                                    color: Color.fromARGB(255, 202, 202, 202)),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 10),
                                  Text(
                                    " EMI",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 13),
                                ],
                              ),
                            ),
    
                            SizedBox(height: 10),
    
                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: TextField(
                                controller: name,
                                decoration: InputDecoration(
                                  labelText: 'EMI Name',
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
                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: TextField(
                                controller: price,
                                decoration: InputDecoration(
                                  labelText: 'Principle Amount',
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
                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: TextField(
                                controller: downpay,
                                decoration: InputDecoration(
                                  labelText: 'Down Payment',
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
                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: TextField(
                                controller: interst,
                                decoration: InputDecoration(
                                  labelText: 'Interest',
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
                            Container(
                              width: constraints.maxWidth * 0.9,
                              child: TextField(
                                controller: year,
                                decoration: InputDecoration(
                                  labelText: 'Time Period',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "Start Date",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
    
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: containerWidth, // Use dynamic width
                                  height: 46,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // Align properly
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 16), // Add some padding
                                        child: Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color.fromARGB(
                                                255, 116, 116, 116),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _selectDate(context);
                                        },
                                        icon: Icon(Icons.date_range),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
    
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              "End Date",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
    
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: containerWidth, // Use dynamic width
                                  height: 46,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // Align properly
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 16), // Add some padding
                                        child: Text(
                                          '${selectedDate2.day}/${selectedDate2.month}/${selectedDate2.year}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color.fromARGB(
                                                255, 116, 116, 116),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _selectDate2(context);
                                        },
                                        icon: Icon(Icons.date_range),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
    
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      adddepartment(context);
                                    });
                                  },
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.blue,
                                    ),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    fixedSize: MaterialStateProperty.all<Size>(
                                      Size(constraints.maxWidth * 0.4, 50),
                                    ),
                                  ),
                                  child: Text("Submit",
                                      style: TextStyle(color: Colors.white)),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${calculatedEmi.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 73, 54, 244)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
    
                            Text(
                              'Total Interest: ₹${totalInterestAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                            SizedBox(height: 10),
    
                            Text(
                              'Total Amount: ₹${totalAmountWithInterest.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                            // Displaying the list of departments as a table
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("EMI List",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ),
                  emiList.isNotEmpty
                      ? Padding(
                        padding: const EdgeInsets.only(bottom:55),
                        child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: emiList.length,
                            itemBuilder: (context, index) {
                              final emi = emiList[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => EmiReport(emid:emi['id'])));
                                },
                                child: Card(
                                  color: Colors.white,
                                  margin: EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          color: Colors.blueAccent.withOpacity(
                                              0.1), // Background color with some transparency
                                          padding: EdgeInsets.all(
                                              8.0), // Padding inside the container
                                          child: Text(
                                            '${emi['emi_name']}',
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(
                                          'Principal: ₹${emi['principal']}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Interest: ${emi['annual_interest_rate']}%',
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              ', ${emi['tenure_months']} months',
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Down Payment: ₹${emi['down_payment']}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black87,
                                          ),
                                        ),
                            
                                         Text(
                                          'Total Interest: ₹${emi['total_interest']}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black87,
                                          ),
                                        ),
                            
                                         Text(
                                          'Total Payment: ₹${emi['total_payment']}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Emi: ₹${emi['emi']}',
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            color: const Color.fromARGB(
                                                221, 252, 0, 0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      )
                      : Text('No EMI data available'),
                  SizedBox(height: 15),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
