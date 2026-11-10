class SupportCategory {
  final String code;
  final String label;

  const SupportCategory({required this.code, required this.label});

  factory SupportCategory.fromJson(Map<String, dynamic> json) {
    return SupportCategory(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? json['code']?.toString() ?? '',
    );
  }
}

class SupportAttachment {
  final String key;
  final String name;

  const SupportAttachment({required this.key, required this.name});

  factory SupportAttachment.fromJson(Map<String, dynamic> json) {
    return SupportAttachment(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Tệp đính kèm',
    );
  }
}

class SupportReply {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime? createdAt;
  final List<SupportAttachment> attachments;

  const SupportReply({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.attachments,
  });

  factory SupportReply.fromJson(Map<String, dynamic> json) {
    return SupportReply(
      id: json['reply_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'Avora',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      attachments: _attachments(json['attachment_urls']),
    );
  }
}

class SupportTicket {
  final String id;
  final String title;
  final String description;
  final String categoryCode;
  final String categoryLabel;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final List<SupportAttachment> attachments;
  final List<SupportReply> replies;

  const SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryCode,
    required this.categoryLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
    required this.resolutionNote,
    required this.attachments,
    required this.replies,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final replies = json['replies'];
    return SupportTicket(
      id: json['ticket_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryCode: json['ticket_type_cd']?.toString() ?? '',
      categoryLabel:
          json['category_label']?.toString() ??
          json['ticket_type_cd']?.toString() ??
          'Khác',
      status: (json['ticket_status_cd']?.toString() ?? 'OPN').toUpperCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
      resolutionNote: json['resolution_note']?.toString(),
      attachments: _attachments(json['attachment_urls']),
      replies: replies is List
          ? replies
                .whereType<Map>()
                .map(
                  (item) =>
                      SupportReply.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

List<SupportAttachment> _attachments(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => SupportAttachment.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList();
}
