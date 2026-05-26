import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentProgram;
  final String currentSection;
  final String currentImageUrl;
  final String displayName;
  final String studentId;

  const EditProfileScreen({
    super.key,
    required this.currentProgram,
    required this.currentSection,
    required this.currentImageUrl,
    required this.displayName,
    required this.studentId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  late TextEditingController _sectionController;

  String? _selectedProgram;
  bool _showDropdown = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final Map<String, List<String>> _programs = {
    'School of Education, Arts, and Sciences (SEAS)': [
      'BACHELOR OF ARTS IN COMMUNICATION (ABComm)',
      'BACHELOR OF ARTS IN POLITICAL SCIENCE (BAPolSci)',
      'BACHELOR OF SCIENCE IN MEDICAL TECHNOLOGY (BSMT)',
      'BACHELOR OF SCIENCE IN PSYCHOLOGY (BSPsy)',
      'DOCTOR OF DENTAL MEDICINE (DMD)',
    ],
    'School of Accountancy, Business and Management (SABM)': [
      'BACHELOR OF SCIENCE IN ACCOUNTANCY (BSAccountancy)',
      'BACHELOR OF SCIENCE IN BUSINESS ADMINISTRATION MAJOR IN MARKETING MANAGEMENT (BSBA-MktgMgmt-MNL)',
      'BACHELOR OF SCIENCE IN MANAGEMENT ACCOUNTING (BSMA)',
      'BACHELOR OF SCIENCE IN TOURISM MANAGEMENT (BSTM)',
    ],
    'School of Engineering, Architecture and Technology (SEAT)': [
      'BACHELOR OF SCIENCE IN ARCHITECTURE (BSArch-MNL)',
      'BACHELOR OF SCIENCE IN CIVIL ENGINEERING (BSCE)',
      'BACHELOR OF SCIENCE IN COMPUTER ENGINEERING (BSCpE-MNL)',
      'BACHELOR OF SCIENCE IN COMPUTER SCIENCE WITH SPECIALIZATION IN ARTIFICIAL INTELLIGENCE (BSCS)',
      'BACHELOR OF SCIENCE IN INFORMATION TECHNOLOGY WITH SPECIALIZATION IN MOBILE AND WEB APPLICATION (BSIT-MNL)',
    ],
  };

  @override
  void initState() {
    super.initState();
    _sectionController = TextEditingController(text: widget.currentSection);
    _selectedProgram = widget.currentProgram;
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  void _showImageSourceMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF232d74), size: 28),
                    title: Text('Take a Photo', style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF232d74), size: 28),
                    title: Text('Choose from Gallery', style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _formInputStyle(bool isLocked) {
    return InputDecoration(
      filled: true,
      fillColor: isLocked ? const Color(0xFFe2e8f0) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isLocked ? BorderSide.none : const BorderSide(color: Color(0xFF232d74), width: 1.5),
      ),
    );
  }

  Widget _buildLabel(String text, {bool showLock = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: Row(
        children: [
          Text(text, style: GoogleFonts.firaSans(fontSize: 14, color: const Color(0xFF0f172a))),
          if (showLock) ...[
            const SizedBox(width: 5),
            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94a3b8)),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff6ff),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0f172a), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Edit Profile", style: GoogleFonts.firaSans(color: const Color(0xFF0f172a), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceMenu,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFcbd5e1),
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : (widget.currentImageUrl.isNotEmpty
                              ? DecorationImage(image: CachedNetworkImageProvider(widget.currentImageUrl), fit: BoxFit.cover)
                              : null),
                        ),
                        child: (_selectedImage == null && widget.currentImageUrl.isEmpty)
                            ? Center(
                          child: Text(
                              widget.displayName[0].toUpperCase(),
                              style: GoogleFonts.firaSans(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                        )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFeff6ff), shape: BoxShape.circle),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF232d74), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("Full Name", showLock: true),
              TextFormField(
                initialValue: widget.displayName,
                readOnly: true,
                style: const TextStyle(color: Color(0xFF64748b)),
                decoration: _formInputStyle(true),
              ),
              const SizedBox(height: 15),

              _buildLabel("Student ID", showLock: true),
              TextFormField(
                initialValue: widget.studentId,
                readOnly: true,
                style: const TextStyle(color: Color(0xFF64748b)),
                decoration: _formInputStyle(true),
              ),
              const SizedBox(height: 15),

              _buildLabel("Academic Program"),

              GestureDetector(
                onTap: () => setState(() => _showDropdown = !_showDropdown),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedProgram ?? "Select Academic Program",
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedProgram == null ? const Color(0xFF94a3b8) : const Color(0xFF0f172a),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(_showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: const Color(0xFF94a3b8)),
                    ],
                  ),
                ),
              ),

              if (_showDropdown)
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: _programs.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              color: const Color(0xFFf1f5f9),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              child: Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748b))),
                            ),
                            ...entry.value.map((course) => InkWell(
                              onTap: () => setState(() {
                                _selectedProgram = course;
                                _showDropdown = false;
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9)))),
                                child: Text(course, style: const TextStyle(fontSize: 13, color: Color(0xFF0f172a))),
                              ),
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 15),

              _buildLabel("Section"),
              TextFormField(
                controller: _sectionController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                decoration: _formInputStyle(false).copyWith(hintText: "e.g. POLSCI302"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Required field";
                  int digitCount = value.replaceAll(RegExp(r'[^0-9]'), '').length;
                  if (digitCount != 3) {
                    return "Must contain exactly 3 numbers (e.g. POLSCI302)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF232d74),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {

                      if (_selectedProgram == null || _selectedProgram!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a Program!"), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);

                      String result = await _firestoreService.updateUserProfile(
                        imageFile: _selectedImage,
                        college: _selectedProgram!,
                        section: _sectionController.text.trim().toUpperCase(),
                      );

                      setState(() => _isLoading = false);

                      if (result == "Success") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,),
                        );
                        if (mounted) Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,),
                        );
                      }
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Save Changes", style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}