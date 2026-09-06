import 'package:cloud_firestore/cloud_firestore.dart';

class College {
  final String id;
  final String name;
  final String code;

  College({
    required this.id,
    required this.name,
    required this.code,
  });

  factory College.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return College(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
    );
  }

  factory College.fromMap(String id, Map<String, dynamic> data) {
    return College(
      id: id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
    };
  }
}
