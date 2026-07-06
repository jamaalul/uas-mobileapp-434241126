import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  Future<CommentModel> addComment({
    required String ticketId,
    required String content,
    required String userName,
    String? parentId,
  });

  Stream<List<CommentModel>> streamComments(String ticketId);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  CommentRemoteDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });

  CollectionReference _commentsRef(String ticketId) {
    return firestore.collection('tickets').doc(ticketId).collection('comments');
  }

  @override
  Future<CommentModel> addComment({
    required String ticketId,
    required String content,
    required String userName,
    String? parentId,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final docRef = _commentsRef(ticketId).doc();
    final now = DateTime.now();

    final comment = CommentModel(
      id: docRef.id,
      ticketId: ticketId,
      userId: user.uid,
      userName: userName,
      content: content,
      parentId: parentId,
      createdAt: now,
    );

    await docRef.set(comment.toJson());
    return comment;
  }

  @override
  Stream<List<CommentModel>> streamComments(String ticketId) {
    return _commentsRef(ticketId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc, ticketId))
            .toList());
  }
}
