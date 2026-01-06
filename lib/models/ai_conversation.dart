import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'ai_conversation.g.dart';

/// Message role in AI conversation
enum MessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system
}

/// AI conversation message model
@HiveType(typeId: 17)
class AIMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  int roleIndex;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  bool isLoading;

  @HiveField(5)
  String? actionType; // 'create_task', 'show_tasks', 'analyze', etc.

  @HiveField(6)
  Map<String, dynamic>? actionData;

  @HiveField(7)
  bool hasError;

  @HiveField(8)
  String? errorMessage;

  AIMessage({
    String? id,
    required this.content,
    this.roleIndex = 0,
    DateTime? timestamp,
    this.isLoading = false,
    this.actionType,
    this.actionData,
    this.hasError = false,
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  MessageRole get role => MessageRole.values[roleIndex];
  set role(MessageRole value) => roleIndex = value.index;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  bool get hasAction => actionType != null;

  AIMessage copyWith({
    String? id,
    String? content,
    int? roleIndex,
    DateTime? timestamp,
    bool? isLoading,
    String? actionType,
    Map<String, dynamic>? actionData,
    bool? hasError,
    String? errorMessage,
  }) {
    return AIMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      roleIndex: roleIndex ?? this.roleIndex,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': roleIndex,
        'timestamp': timestamp.toIso8601String(),
        'is_loading': isLoading,
        'action_type': actionType,
        'action_data': actionData,
        'has_error': hasError,
        'error_message': errorMessage,
      };

  factory AIMessage.fromJson(Map<String, dynamic> json) => AIMessage(
        id: json['id'] as String?,
        content: json['content'] as String,
        roleIndex: json['role'] as int? ?? 0,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        isLoading: json['is_loading'] as bool? ?? false,
        actionType: json['action_type'] as String?,
        actionData: json['action_data'] as Map<String, dynamic>?,
        hasError: json['has_error'] as bool? ?? false,
        errorMessage: json['error_message'] as String?,
      );
}

/// AI conversation model
@HiveType(typeId: 18)
class AIConversation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<AIMessage> messages;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  bool isActive;

  AIConversation({
    String? id,
    this.title = 'New Conversation',
    List<AIMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get messageCount => messages.length;

  AIMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  void addMessage(AIMessage message) {
    messages.add(message);
    updatedAt = DateTime.now();
  }

  AIConversation copyWith({
    String? id,
    String? title,
    List<AIMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AIConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? List.from(this.messages),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_active': isActive,
      };

  factory AIConversation.fromJson(Map<String, dynamic> json) => AIConversation(
        id: json['id'] as String?,
        title: json['title'] as String? ?? 'New Conversation',
        messages: (json['messages'] as List<dynamic>?)
                ?.map((m) => AIMessage.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Quick AI action model
class AIQuickAction {
  final String id;
  final String label;
  final String prompt;
  final String iconName;

  const AIQuickAction({
    required this.id,
    required this.label,
    required this.prompt,
    required this.iconName,
  });

  static const List<AIQuickAction> defaultActions = [
    AIQuickAction(
      id: 'what_now',
      label: 'What should I work on now?',
      prompt:
          'Based on my tasks, what should I prioritize and work on right now?',
      iconName: 'lightbulb',
    ),
    AIQuickAction(
      id: 'show_overdue',
      label: 'Show overdue tasks',
      prompt: 'Show me all my overdue tasks that need immediate attention.',
      iconName: 'warning',
    ),
    AIQuickAction(
      id: 'productivity',
      label: 'Analyze my productivity',
      prompt:
          'Analyze my productivity patterns and give me insights on how I can improve.',
      iconName: 'analytics',
    ),
    AIQuickAction(
      id: 'plan_day',
      label: 'Plan my day',
      prompt: 'Help me plan my day based on my pending tasks and priorities.',
      iconName: 'calendar',
    ),
    AIQuickAction(
      id: 'breakdown',
      label: 'Break down a complex task',
      prompt:
          'Help me break down a complex task into smaller, manageable subtasks.',
      iconName: 'list',
    ),
    AIQuickAction(
      id: 'suggest',
      label: 'Suggest new tasks',
      prompt:
          'Based on my patterns and categories, suggest some tasks I might need to do.',
      iconName: 'add_task',
    ),
  ];
}
