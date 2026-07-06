class Ticket {
  final String id;
  final String userId;
  final String issue;
  final String description;
  final String? attachmentUrl;
  final String? helpdesk;
  final String status;
  final DateTime createdAt;

  Ticket({
    required this.id,
    required this.userId,
    required this.issue,
    required this.description,
    this.attachmentUrl,
    this.helpdesk,
    this.status = 'open',
    required this.createdAt,
  });
}
