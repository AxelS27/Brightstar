import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../shared/widgets/report_detail_popup.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  DateTime? startDate, endDate;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllReports();
  }

  Future<void> _loadAllReports() async {
    String url = "${ApiConfig.baseUrl}/get_all_reports.php";
    if (startDate != null) {
      url +=
          "&start_date=${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}";
    }
    if (endDate != null) {
      url +=
          "&end_date=${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}";
    }
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _reports = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        _loadAllReports();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8E24AA)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("All Reports")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Start Date'),
                      subtitle: Text(
                        startDate?.toIso8601String().split('T')[0] ?? 'Not set',
                      ),
                      onTap: () => _selectDate(true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('End Date'),
                      subtitle: Text(
                        endDate?.toIso8601String().split('T')[0] ?? 'Not set',
                      ),
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text(
                      "No reports found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      return GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => ReportDetailPopup(
                            studentName: r['studentName'] ?? 'N/A',
                            title: r['title'] ?? '-',
                            course: r['courseName'] ?? '-',
                            meetingNumber: 1,
                            description: r['description'] ?? '-',
                            imageUrl: r['picture'] ?? '',
                            time: "${r['startTime']} - ${r['endTime']}",
                            place: r['room'] ?? '-',
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  r['picture'] ?? '',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['title'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      "${r['teacherName']} → ${r['studentName']}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "${r['courseName']} • ${r['courseDate']}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
