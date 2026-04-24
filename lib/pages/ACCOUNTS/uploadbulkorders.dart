import 'dart:convert';
import 'dart:io';

import 'package:beposoft/pages/api.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UploadBulkProducts extends StatefulWidget {
  const UploadBulkProducts({super.key});

  @override
  State<UploadBulkProducts> createState() => _UploadBulkProductsState();
}

class _UploadBulkProductsState extends State<UploadBulkProducts> {
  String? fileName;
  String? filePath;

  @override
  void initState() {
    super.initState();
  }

  Future<String?> getToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString('token');
  }
Future<void> uploadExcel(BuildContext scaffoldContext) async {
  final token = await getToken();

  if (filePath == null) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('No file selected'),
      ),
    );
    return;
  }

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$api/api/bulk/upload/products/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('file', filePath!),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    ;
    ;

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('File uploaded successfully.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('File upload failed: ${response.body}'),
        ),
      );
    }
  } catch (e) {
    ;

    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text('Error: $e'),
      ),
    );
  }
}

  Future<void> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        fileName = result.files.single.name;
        filePath = result.files.single.path!;
      });
    }
  }

  void clearFile() {
    setState(() {
      fileName = null;
      filePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text(
        'Upload Excel File',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      )),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: pickExcelFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: fileName == null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.upload_file,
                                    size: 50, color: Colors.blueGrey),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap to upload an Excel file',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file,
                                    size: 50, color: Colors.green),
                                const SizedBox(height: 10),
                                Text(fileName!,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: clearFile,
                                  icon: const Icon(Icons.clear,
                                      color: Colors.red),
                                  label: const Text('Remove',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: fileName != null
                  ? () {
                      uploadExcel(context);
                    }
                  : null,
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label:
                  const Text('Upload', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Set button color to blue
                minimumSize: const Size(double.infinity, 50),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)), // Rounded edges
              ),
            ),
          ),
        ],
      ),
    );
  }
}
