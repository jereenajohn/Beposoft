import 'package:beposoft/loginpage.dart';
import 'package:beposoft/pages/ACCOUNTS/add_attribute.dart';
import 'package:beposoft/pages/ACCOUNTS/add_bank.dart';
import 'package:beposoft/pages/ACCOUNTS/add_company.dart';
import 'package:beposoft/pages/ACCOUNTS/add_department.dart';
import 'package:beposoft/pages/ACCOUNTS/add_family.dart';
import 'package:beposoft/pages/ACCOUNTS/add_services.dart';
import 'package:beposoft/pages/ACCOUNTS/add_state.dart';
import 'package:beposoft/pages/ACCOUNTS/add_supervisor.dart';
import 'package:beposoft/pages/ACCOUNTS/customer.dart';
import 'package:beposoft/pages/ACCOUNTS/dashboard.dart';
import 'package:beposoft/pages/ACCOUNTS/dorwer.dart';
import 'package:beposoft/pages/ACCOUNTS/methods.dart';
import 'package:beposoft/pages/ACCOUNTS/order_request.dart';
import 'package:beposoft/pages/ACCOUNTS/performa_order_request.dart';
import 'package:beposoft/pages/WAREHOUSE/warehouse_order_view.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Performa_Cart extends StatefulWidget {
  const Performa_Cart({super.key});

  @override
  State<Performa_Cart> createState() => _Performa_CartState();
}

class _Performa_CartState extends State<Performa_Cart> {
  List<Map<String, dynamic>> cartdata = [];
  drower d = drower();

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  Future<String?> getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchCartData() async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.get(
        Uri.parse("$api/api/cart/products/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final List<dynamic> cartsData = parsed['data'];
        List<Map<String, dynamic>> cartList = [];

        for (var cartData in cartsData) {
          cartList.add({
            'id': cartData['id'],
            'name': cartData['name'],
            'image': cartData['image'],
            'slug': cartData['slug'],
            'size': cartData['size'],
            'quantity': cartData['quantity'],
            'price': cartData['price'],
            'note': cartData['note'] ?? '',
            'discount': cartData['discount'] ?? 0.0,
            'tax': cartData['tax']
          });
        }
        setState(() {
          cartdata = cartList;
          
        });
      } else {
        throw Exception('Failed to load cart data');
      }
    } catch (error) {
      
    }
  }

  double calculateTotalPrice() {
    double total = 0;
    for (var item in cartdata) {
      final discountPerQuantity = item['discount'] ?? 0.0;
      final quantity = int.tryParse(item['quantity'].toString()) ?? 0; // Ensure it's an integer
final price = double.tryParse(item['price'].toString()) ?? 0.0; // Ensure it's a double
      final totalItemPrice = quantity * price;
      final totalDiscount = quantity * discountPerQuantity;
      total += totalItemPrice - totalDiscount;
    }
    return total;
  }

  Future<void> updatecartdetails(
      int id, int quantity, String description, double discount, double price) async {
    try {
      final token = await getTokenFromPrefs();
      final response = await http.put(
        Uri.parse('$api/api/cart/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'quantity': quantity,
          'note': description,
          'discount': discount,
          'price': price,
        }),
      );

      

      if (response.statusCode == 200) {
        fetchCartData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cart item updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (error) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update cart item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deletecartitem(int id) async {
    final token = await getTokenFromPrefs();

    try {
      final response = await http.delete(
        Uri.parse('$api/api/cart/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          cartdata.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted from Cart Successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete cart ID: $id');
      }
    } catch (error) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete item from cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showPopupDialog(BuildContext context, Map<String, dynamic> item) {
    TextEditingController descriptionController =
        TextEditingController(text: item['note'] ?? '');
    TextEditingController quantityController =
        TextEditingController(text: item['quantity']?.toString() ?? '');
    TextEditingController discountController =
        TextEditingController(text: item['discount']?.toString() ?? '');
    TextEditingController pricee =
        TextEditingController(text: item['price']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Item Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                    controller: pricee,
                    decoration: InputDecoration(labelText: 'Edit Price'),
                    keyboardType: TextInputType.number,
                  ),
              TextField(
                controller: discountController,
                decoration: InputDecoration(labelText: 'Discount (in Rs for each product)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final description = descriptionController.text;
                final quantity = int.tryParse(quantityController.text) ?? item['quantity'];
                final discount = double.tryParse(discountController.text) ?? item['discount'];
                final upprice = double.tryParse(pricee.text) ?? item['price'];

                updatecartdetails(item['id'], quantity, description, discount, upprice);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cart",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back arrow
          onPressed: () async{
                Navigator.pop(context);
           
          },
        ),
      ),
         
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  cartdata.isEmpty
                      ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.6, // Take up space to center content
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_shopping_cart,
                          size: 80, color: Colors.grey[400]),
                      SizedBox(height: 10),
                      Text(
                        "Cart is empty",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                      : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cartdata.length,
                          itemBuilder: (context, index) {
                             final item = cartdata[index];
                             final discountPerQuantity = item['discount'] ?? 0.0;
                            final quantity = int.tryParse(item['quantity'].toString()) ?? 0; // Ensure it's an integer
final price = double.tryParse(item['price'].toString()) ?? 0.0; // Ensure it's a double
                              
                              
                             final totalItemPrice = quantity * price;
                           
                             
                           final totalDiscount = quantity * discountPerQuantity;
                             final discountedTotalPrice = totalItemPrice - totalDiscount;

                            return InkWell(
                              onTap: () => showPopupDialog(context, item),
                              child: Stack(
                                children: [
                                  Card(
                                    elevation: 4,
                                    color: Colors.white,
                                    margin: EdgeInsets.all(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Image.network(
                                                    "${item['image']}",
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(Icons
                                                          .image_not_supported); // Fallback image or icon
                                                    },
                                                  ),

                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                // Text("Tax: ${item['tax']} %"),
                                                if (item['note'] != null && item['note'].isNotEmpty)
                                                  Text(
                                                    "Description: ${item['note']}",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                if (quantity > 0)
                                                  Text("Quantity: $quantity"),
                                                if (discountPerQuantity > 0)
                                                  Text("Discount per item: ₹$discountPerQuantity"),
                                                Text("Price per item: ₹$price"),
                                                Text("Total price: ₹${totalItemPrice.toStringAsFixed(2)}"),
                                                Text(
                                                  "Total discount: -₹${totalDiscount.toStringAsFixed(2)}",
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                                Text(
                                                  "Final price after discount: ₹${discountedTotalPrice.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await deletecartitem(item['id']);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price: ₹${calculateTotalPrice().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>Performa_order_request()));
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
