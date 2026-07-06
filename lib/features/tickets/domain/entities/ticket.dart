class Ticket {
  final String id;
  final String userId;
  final String issue;
  final String description;
  final String? attachmentUrl;
  final String? helpdesk;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.issue,
    required this.description,
    this.attachmentUrl,
    this.helpdesk,
    required this.createdAt,
  });
}
