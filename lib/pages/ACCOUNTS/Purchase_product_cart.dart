import 'dart:convert';
import 'package:beposoft/pages/ACCOUNTS/create_purchase_invoice_request.dart';
import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SellerCartPage extends StatefulWidget {
  const SellerCartPage({super.key});

  @override
  State<SellerCartPage> createState() => _SellerCartPageState();
}

class _SellerCartPageState extends State<SellerCartPage> {
  List<Map<String, dynamic>> cartItems = [];
  bool loading = false;
  double totalFinalPrice = 0;

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  // ✅ FETCH CART LIST
  Future<void> fetchCartItems() async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    setState(() {
      loading = true;
      totalFinalPrice = 0;
    });

    try {
      final response = await http.get(
        Uri.parse("$api/api/product/seller/cart/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // debugPrint("====================>${response.body}");

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        List<Map<String, dynamic>> list = [];

        if (parsed is List) {
          for (var item in parsed) {
            list.add(Map<String, dynamic>.from(item));
          }
        } else if (parsed is Map && parsed['data'] != null) {
          for (var item in parsed['data']) {
            list.add(Map<String, dynamic>.from(item));
          }
        }

        double total = 0;

        for (var item in list) {
          double price = double.tryParse(item["price"].toString()) ?? 0;
          int qty = int.tryParse(item["quantity"].toString()) ?? 0;
          double discount = double.tryParse(item["discount"].toString()) ?? 0;

          double totalPrice = price * qty;
          double finalPrice = totalPrice - discount;

          item["total_price"] = totalPrice;
          item["final_price"] = finalPrice;

          total += finalPrice;
        }

        setState(() {
          cartItems = list;
          totalFinalPrice = total;
        });
      }
    } catch (e) {
      // debugPrint("Cart Fetch Error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  // ✅ DELETE CART ITEM
  Future<void> deleteCartItem(int id) async {
    final token = await getTokenFromPrefs();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse("$api/api/product/seller/cart/delete/$id/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchCartItems();
      }
    } catch (e) {
      // debugPrint("Delete Cart Error: $e");
    }
  }

  // ✅ UPDATE CART ITEM API
  Future<void> updateCartItem(int id,
      {required int quantity,
      required double price,
      required double discount,
      required String note}) async {
    final token = await getTokenFromPrefs();
    if (token == null) return;
    // print("hellllloooooooo");
    try {
      final response = await http.put(
        Uri.parse("$api/api/product/seller/cart/update/$id/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "quantity": quantity,
          "price": price,
          "discount": discount,
          "note": note,
        }),
      );

      // debugPrint("UPDATE RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchCartItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update cart item")),
        );
      }
    } catch (e) {
      // debugPrint("Update Cart Error: $e");
    }
  }

  void showEditPopup(Map<String, dynamic> item) {
    TextEditingController descController =
        TextEditingController(text: item["note"]?.toString() ?? "");
    TextEditingController qtyController =
        TextEditingController(text: item["quantity"].toString());
    TextEditingController priceController =
        TextEditingController(text: item["price"].toString());
    TextEditingController discountController =
        TextEditingController(text: item["discount"].toString());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.65, // ✅ important
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEF5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Edit Item Details",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ✅ DESCRIPTION
                    const Text("Description",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextField(
                      controller: descController,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ QUANTITY
                    const Text("Quantity",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ EDIT PRICE
                    const Text("Edit Price",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ DISCOUNT
                    const Text("Discount (Rs per product)",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                                color: Colors.deepPurple, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            int qty = int.tryParse(qtyController.text) ?? 1;
                            double price =
                                double.tryParse(priceController.text) ?? 0;
                            double discount =
                                double.tryParse(discountController.text) ?? 0;
                            String note = descController.text;

                            if (qty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Quantity must be greater than 0"),
                                ),
                              );
                              return;
                            }

                            updateCartItem(
                              item["id"],
                              quantity: qty,
                              price: price,
                              discount: discount,
                              note: note,
                            );

                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ CART CARD DESIGN
  Widget cartCard(Map<String, dynamic> item) {
    int id = item['id'];

    String productName = item['product_name'] ?? "";
    String image = item['product_image'] ?? "";

    int quantity = int.tryParse(item['quantity'].toString()) ?? 0;
    double price = double.tryParse(item['price'].toString()) ?? 0;
    double discount = double.tryParse(item['discount'].toString()) ?? 0;

    double totalPrice = price * quantity;
    double finalPrice = totalPrice - discount;

    return GestureDetector(
      onTap: () {
        showEditPopup(item); // ✅ CLICK CARD OPEN EDIT POPUP
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.25),
                blurRadius: 6,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ PRODUCT IMAGE
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image.isNotEmpty
                      ? Image.network(
                          "$api$image",
                          width: 85,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 40),
                        )
                      : Container(
                          width: 85,
                          height: 100,
                          color: Colors.grey.shade200,
                          child:
                              const Icon(Icons.image_not_supported, size: 40),
                        ),
                ),
              ),

              // ✅ DETAILS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 12, right: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text("Quantity: $quantity",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black)),
                      Text("Price per item: ₹${price.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black)),
                      Text("Total price: ₹${totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text(
                        "Total discount: -₹${discount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Final price after discount: ₹${finalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ DELETE ICON
              Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: IconButton(
                    onPressed: () => deleteCartItem(id),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ BOTTOM TOTAL BAR DESIGN
  Widget bottomBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Total Price: ₹${totalFinalPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePurchaseInvoiceRequest(
                    cartItems: cartItems,
                    totalAmount: totalFinalPrice,
                  ),
                ),
              );
            },
            child: const Text(
              "Continue",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Product List",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text("No items in cart"))
              : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    return cartCard(cartItems[index]);
                  },
                ),
      bottomNavigationBar: cartItems.isEmpty ? null : bottomBar(),
    );
  }
}
