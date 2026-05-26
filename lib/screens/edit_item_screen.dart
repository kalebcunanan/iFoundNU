import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_post.dart';

class EditItemScreen extends StatefulWidget {
  final ItemPost post;

  const EditItemScreen({super.key, required this.post});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.post.itemName);
    _locationController = TextEditingController(text: widget.post.location);
    _descController = TextEditingController(text: widget.post.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }


  InputDecoration _mRescueInputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94a3b8), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Padding sa loob ng kahon
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe2e8f0), width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF232d74), width: 2)),
    );
  }

  void _updatePost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance.collection('items').doc(widget.post.id).update({
          'itemName': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'description': _descController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post successfully updated! 🎉"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating post: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF232d74)),
        title: Text("Edit Post", style: GoogleFonts.firaSans(color: const Color(0xFF232d74), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update Details",
                style: GoogleFonts.firaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0f172a)),
              ),
              const SizedBox(height: 5),
              Text(
                "Make sure to provide accurate information.",
                style: GoogleFonts.firaSans(fontSize: 14, color: const Color(0xFF64748b)),
              ),
              const SizedBox(height: 25),

              // ITEM NAME (Label sa labas!)
              Text("Item Name", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
              const SizedBox(height: 8), // Maliit na space bago ang kahon
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16, color: Color(0xFF0f172a)),
                decoration: _mRescueInputStyle("e.g., Blue Wallet, ID Card"),
                validator: (value) => value!.isEmpty ? "Required field" : null,
              ),
              const SizedBox(height: 20),

              // LOCATION (Label sa labas!)
              Text("Last Seen / Found Location", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                style: const TextStyle(fontSize: 16, color: Color(0xFF0f172a)),
                decoration: _mRescueInputStyle("e.g., NU Clark Canteen, Room 402"),
                validator: (value) => value!.isEmpty ? "Required field" : null,
              ),
              const SizedBox(height: 20),

              // DESCRIPTION (Label sa labas!)
              Text("Description", style: GoogleFonts.firaSans(fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: const TextStyle(fontSize: 16, color: Color(0xFF0f172a)),
                decoration: _mRescueInputStyle("Provide details like color, brand, or distinct marks."),
                validator: (value) => value!.isEmpty ? "Required field" : null,
              ),
              const SizedBox(height: 30),

              // UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF232d74),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _updatePost,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    "Save Changes",
                    style: GoogleFonts.firaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}