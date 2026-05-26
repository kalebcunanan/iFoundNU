import 'package:cloud_firestore/cloud_firestore.dart';


class ItemPost {
  final String id;
  final String itemName;
  final String location;
  final String description;
  final bool isLost;
  final String reporterId;
  final DateTime dateReported;
  final String imageUrl;

  final String reporterName;
  final String reporterProgram;

  final String status;

  ItemPost({
    required this.id,
    required this.itemName,
    required this.location,
    required this.description,
    required this.isLost,
    required this.reporterId,
    required this.dateReported,
    this.imageUrl = '',
    this.reporterName = 'Loading Name...',
    this.reporterProgram = 'Loading Program...',
    this.status = 'Open',
  });

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'location': location,
      'description': description,
      'isLost': isLost,
      'reporterId': reporterId,
      'dateReported': Timestamp.fromDate(dateReported),
      'imageUrl': imageUrl,
      'reporterName': reporterName,
      'reporterProgram': reporterProgram,
      'status': status,
    };
  }
}