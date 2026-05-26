import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';

class ReportItemScreen extends StatefulWidget {
  const ReportItemScreen({super.key});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isReportingLost = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF232d74), size: 28),
                    title: Text('Choose from Gallery', style: GoogleFonts.firaSans(fontSize: 16, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
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

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  InputDecoration _formInputStyle(IconData? suffixIcon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF64748b)) : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF232d74), width: 1.5)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: Text(text, style: GoogleFonts.firaSans(fontSize: 14, color: const Color(0xFF0f172a))),
    );
  }

  // MAGIC UI FIX: Full-Screen Success Animation!
  // Gumawa tayo ng custom transition imbes na basic SnackBar para mas maganda ang User Experience (UX).
  void _showSuccessScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Para smooth yung transition over the current screen
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: const Color(0xFF16a34a), // Solid Green Background
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 100, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                      "Report Sent!",
                      style: GoogleFonts.firaSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const SizedBox(height: 10),
                  Text(
                      "Your item has been posted.",
                      style: GoogleFonts.firaSans(fontSize: 16, color: Colors.white70)
                  ),
                ],
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade In Animation
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // Auto-Close Logic: Hihintayin niya ng 2.5 seconds bago isara yung success screen at report screen.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pop(context); // Sinasara yung green success screen
        Navigator.pop(context); // Ibinabalik ang user sa Home Feed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff6ff),
      appBar: AppBar(
        backgroundColor: const Color(0xFFeef5fe),
        elevation: 0,
        toolbarHeight: 70,
        title: Text(
          "Report an Item",
          style: GoogleFonts.firaSans(
            color: const Color(0xFF232d74),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF232d74)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    setState(() => _isReportingLost = false);
                  } else if (details.primaryVelocity! < 0) {
                    setState(() => _isReportingLost = true);
                  }
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2e8f0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: _isReportingLost ? Alignment.centerLeft : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          heightFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),

                      // THE TEXT LABELS
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _isReportingLost = true),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: GoogleFonts.firaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _isReportingLost ? const Color(0xFF232d74) : const Color(0xFF64748b),
                                  ),
                                  child: const Text("Lost Item"),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _isReportingLost = false),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: GoogleFonts.firaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: !_isReportingLost ? const Color(0xFF232d74) : const Color(0xFF64748b),
                                  ),
                                  child: const Text("Found Item"),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              _buildLabel("Item Name"),
              TextFormField(
                controller: _itemNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _formInputStyle(null).copyWith(hintText: "e.g. Blue Hydroflask, ID Lanyard"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              _buildLabel("Image"),
              GestureDetector(
                onTap: _showImageSourceMenu,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFF64748b)),
                      const SizedBox(height: 10),
                      Text("Take a photo or Browse", style: GoogleFonts.firaSans(color: const Color(0xFF64748b), fontSize: 13)),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 15),

              _buildLabel(_isReportingLost ? "Where did you last see it?" : "Where did you find it?"),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: _formInputStyle(null).copyWith(hintText: "e.g. 3rd Floor Library, Main Canteen"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              _buildLabel("Description & Features"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _formInputStyle(null).copyWith(hintText: "Color, stickers, brand, or any unique marks..."),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0f172a),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {

                      setState(() => _isLoading = true);

                      String result = await _firestoreService.createItemPost(
                        itemName: _itemNameController.text.trim(),
                        location: _locationController.text.trim(),
                        description: _descriptionController.text.trim(),
                        isLost: _isReportingLost,
                        imageFile: _selectedImage,
                      );

                      setState(() => _isLoading = false);

                      if (result == "Success") {
                        // TINAWAG NA NATIN YUNG MAGIC FULL SCREEN SUCCESS NATIN DITO!
                        _showSuccessScreen();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,),
                        );
                      }
                    }
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF232d74))
                      : Text("Report Item", style: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}