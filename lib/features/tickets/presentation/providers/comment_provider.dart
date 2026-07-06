import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment.dart';
import '../../data/datasources/comment_remote_datasource.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// Datasource provider
final commentDataSourceProvider = Provider<CommentRemoteDataSource>((ref) {
  return CommentRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

// Streams all comments for a given ticket
final ticketCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, ticketId) {
  final dataSource = ref.watch(commentDataSourceProvider);
  return dataSource.streamComments(ticketId);
});

// Notifier for posting comments
class AddCommentNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> addComment({
    required String ticketId,
    required String content,
    required String userName,
    String? parentId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(commentDataSourceProvider).addComment(
            ticketId: ticketId,
            content: content,
            userName: userName,
            parentId: parentId,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final addCommentProvider =
    NotifierProvider<AddCommentNotifier, AsyncValue<void>>(
  AddCommentNotifier.new,
);
