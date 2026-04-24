import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReportsFolderPage extends StatefulWidget {
  const ReportsFolderPage({super.key});

  @override
  State<ReportsFolderPage> createState() => _ReportsFolderPageState();
}

class _ReportsFolderPageState extends State<ReportsFolderPage> {
  List<FileSystemEntity> files = [];
  List<FileSystemEntity> filteredFiles = [];
  bool loading = true;
  String searchText = "";

  Future<void> loadFiles() async {
    try {
      setState(() {
        loading = true;
      });

      final dir = await getExternalStorageDirectory();
      if (dir == null) return;

      final reportsDir = Directory("${dir.path}/reports");

      if (!reportsDir.existsSync()) {
        reportsDir.createSync(recursive: true);
      }

      final allFiles = reportsDir.listSync();

      List<FileSystemEntity> excelFiles =
          allFiles.where((f) => f.path.endsWith(".xlsx")).toList();

      excelFiles.sort((a, b) {
        final aTime = File(a.path).lastModifiedSync();
        final bTime = File(b.path).lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      setState(() {
        files = excelFiles;
        filteredFiles = excelFiles;
        loading = false;
      });
    } catch (e) {
      print("ERROR LOADING FILES: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> openExcelFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);

      print("OPEN RESULT: ${result.type} | ${result.message}");

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Unable to open file: ${result.message}"),
          ),
        );
      }
    } catch (e) {
      print("OPEN FILE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Unable to open file: $e"),
        ),
      );
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("File deleted successfully"),
        ),
      );

      loadFiles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Delete failed: $e"),
        ),
      );
    }
  }

  void filterSearch(String value) {
    setState(() {
      searchText = value;
      filteredFiles = files
          .where((f) =>
              f.path.toLowerCase().contains(value.trim().toLowerCase()))
          .toList();
    });
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}  "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 247, 250),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 34, 165, 246),
        title: const Text(
          "Excel Reports",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ================= SEARCH BAR =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(30, 0, 0, 0),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: filterSearch,
                decoration: InputDecoration(
                  hintText: "Search Excel reports...",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              searchText = "";
                              filteredFiles = files;
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ================= FILE LIST =================
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.folder_off,
                                size: 70, color: Colors.grey),
                            SizedBox(height: 10),
                            Text(
                              "No Excel Reports Found",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Export reports to view them here",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          final fileName = file.path.split("/").last;

                          final f = File(file.path);
                          final modifiedDate = f.lastModifiedSync();
                          final fileSize = f.lengthSync();

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 230, 230, 230),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(25, 0, 0, 0),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: () async {
                                  await openExcelFile(file.path);
                                },
                                leading: Container(
                                  height: 45,
                                  width: 45,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 220, 245, 255),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.table_chart,
                                    color: Color.fromARGB(255, 34, 165, 246),
                                  ),
                                ),
                                title: Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "Modified: ${formatDate(modifiedDate)}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      "Size: ${formatFileSize(fileSize)}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text("Delete Report"),
                                          content: const Text(
                                              "Are you sure you want to delete this Excel file?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await deleteFile(file.path);
                                              },
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
