class AppUser {

  final String uid;
  final String name;
  final String email;
  final String section;
  final String college;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.section,
    required this.college,
  });


  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'section': section,
      'college': college,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      section: map['section'] ?? '',
      college: map['college'] ?? '',
    );
  }
}