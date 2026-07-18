class Conversation {
  final int id;
  final int userId;
  final String status;
  final String? intent;
  final Map<String, dynamic>? contextData;
  final String? currentStep;
  final int messagesCount;
  final int? userSatisfaction;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? endedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.status,
    this.intent,
    this.contextData,
    this.currentStep,
    required this.messagesCount,
    this.userSatisfaction,
    required this.createdAt,
    this.updatedAt,
    this.endedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      intent: json['intent'] as String?,
      contextData: json['context_data'] as Map<String, dynamic>?,
      currentStep: json['current_step'] as String?,
      messagesCount: json['messages_count'] as int? ?? 0,
      userSatisfaction: json['user_satisfaction'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'intent': intent,
      'context_data': contextData,
      'current_step': currentStep,
      'messages_count': messagesCount,
      'user_satisfaction': userSatisfaction,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }
}