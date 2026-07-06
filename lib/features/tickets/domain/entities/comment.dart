class Comment {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String content;
  final String? parentId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.content,
    this.parentId,
    required this.createdAt,
  });
}
