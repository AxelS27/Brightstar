import 'package:flutter/material.dart';
import 'teacher_report_popup.dart';

class SessionDetailPopup extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final String type;
  final String userId;
  final bool isTeacher;

  const SessionDetailPopup({
    super.key,
    required this.sessionData,
    required this.type,
    required this.userId,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                sessionData['courseName'] ?? 'Class Detail',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.date_range,
              "Date",
              sessionData['courseDate'] ?? '-',
            ),
            _buildInfoRow(
              Icons.access_time,
              "Time",
              "${sessionData['startTime'] ?? '-'} - ${sessionData['endTime'] ?? '-'}",
            ),
            _buildInfoRow(
              Icons.location_on,
              "Room",
              sessionData['room'] ?? '-',
            ),
            _buildInfoRow(
              Icons.person,
              "Teacher",
              sessionData['teacherName'] ?? '-',
            ),
            if (type == "past" && isTeacher)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => TeacherReportPopup(
                        classData: sessionData,
                        readOnly: sessionData['hasReport'] == '1',
                        onReportSaved: () {},
                      ),
                    );
                  },
                  icon: const Icon(Icons.description),
                  label: const Text("View/Edit Report"),
                ),
              ),
            if (type == "past" && !isTeacher)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("View Report"),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: Navigator.of(context).pop,
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E24AA)),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
