import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:beposoft/pages/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryWiseProductPage extends StatefulWidget {
  const CategoryWiseProductPage({super.key});

  @override
  State<CategoryWiseProductPage> createState() =>
      _CategoryWiseProductPageState();
}

class _CategoryWiseProductPageState extends State<CategoryWiseProductPage> {
  List<Map<String, dynamic>> categoryWiseProducts = [];
  String postOfficeDate = "";
  bool loadingCategoryWise = false;

  DateTime? selectedDate;

  Future<String?> getTokenFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // API format: yyyy-mm-dd
  String formatApiDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // UI format: dd-mm-yyyy
  String formatDisplayDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  Future<void> getCategoryWiseProducts({String? selectedDate}) async {
    DateTime now = DateTime.now();
    String todayDate = formatApiDate(now);

    String apiDate = selectedDate ?? todayDate;


    setState(() {
      loadingCategoryWise = true;
      categoryWiseProducts = [];
      postOfficeDate = "";
    });

    final token = await getTokenFromPrefs();

    if (token == null) {
      setState(() {
        loadingCategoryWise = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$api/api/category/wise/product/count/$apiDate/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

     
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          postOfficeDate = data["postoffice_date"] ?? apiDate;
          categoryWiseProducts = List<Map<String, dynamic>>.from(
              data["category_wise_products"] ?? []);
          loadingCategoryWise = false;
        });
      } else {
        setState(() {
          loadingCategoryWise = false;
        });
      }
    } catch (e) {
      setState(() {
        loadingCategoryWise = false;
      });
    }
  }

  Future<void> pickSingleDate() async {
    DateTime initial = selectedDate ?? DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });

      await getCategoryWiseProducts(selectedDate: formatApiDate(picked));
    }
  }

  @override
  void initState() {
    super.initState();
    getCategoryWiseProducts();
  }

  Widget buildTable() {
    if (loadingCategoryWise) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (categoryWiseProducts.isEmpty) {
      return const Center(
        child: Text(
          "No Data Found",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.white30, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Category",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Quantity",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        ...categoryWiseProducts.map((item) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  item["category"].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  item["total_quantity"].toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Category Wise Products",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickSingleDate,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "Selected Date: ${formatDisplayDate(selectedDate!)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                )
              else if (postOfficeDate.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "Date: $postOfficeDate",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF02347C),
                      Color(0xFF82E49D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: buildTable(),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
