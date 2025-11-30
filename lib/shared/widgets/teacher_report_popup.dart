import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/config/api_config.dart';

class TeacherReportPopup extends StatefulWidget {
  final Map<String, dynamic> classData;
  final bool readOnly;
  final VoidCallback? onReportSaved;
  const TeacherReportPopup({
    super.key,
    required this.classData,
    this.readOnly = false,
    this.onReportSaved,
  });

  @override
  State<TeacherReportPopup> createState() => _TeacherReportPopupState();
}

class _TeacherReportPopupState extends State<TeacherReportPopup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = true;
  bool _hasReport = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_report.php?session_id=${widget.classData['session_id']}&student_id=${widget.classData['student_id']}",
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && data['data'] != null) {
          if (!mounted) return;
          setState(() {
            _titleController.text = data['data']['title'] ?? '';
            _descriptionController.text = data['data']['description'] ?? '';
            _hasReport = true;
            String? picture = data['data']['picture'];
            if (picture != null && !picture.startsWith('http')) {
              picture = '${ApiConfig.baseUrl}/uploads/$picture';
            }
            widget.classData['picture'] = picture;
          });
        }
      }
    } catch (e) {}
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    if (widget.readOnly) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveReport() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _imageFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and attach a picture'),
        ),
      );
      return;
    }

    final sessionId = widget.classData['session_id'];
    final studentId = widget.classData['student_id'];

    if (sessionId == null || studentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing student or session data")),
      );
      return;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/save_report.php");
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['session_id'] = sessionId.toString();
      request.fields['student_id'] = studentId.toString();
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);
      if (!mounted) return;

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Report saved successfully")),
        );
        Navigator.pop(context);
        widget.onReportSaved?.call();
      } else {
        final msg = data['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ $msg")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to save report")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8E24AA)),
      );
    }
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        height: 580,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.readOnly
                      ? 'View Report'
                      : _hasReport
                      ? 'Edit Report'
                      : 'Create Report',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${widget.classData['courseName']} • ${widget.classData['courseDate']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Title',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                readOnly: widget.readOnly,
                decoration: InputDecoration(
                  hintText: 'e.g., Coding Progress - Week 4',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                readOnly: widget.readOnly,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g., Students showed improvement...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6A1B9A)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Picture (Required)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : widget.readOnly && widget.classData['picture'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.classData['picture'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to attach picture',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!widget.readOnly)
                    ElevatedButton(
                      onPressed: _saveReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
