import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  CommentModel({
    required super.id,
    required super.ticketId,
    required super.userId,
    required super.userName,
    required super.content,
    super.parentId,
    required super.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc, String ticketId) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      ticketId: ticketId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      content: data['content'] ?? '',
      parentId: data['parentId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'parentId': parentId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
