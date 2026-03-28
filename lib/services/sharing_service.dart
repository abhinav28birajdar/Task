import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();

  factory SharingService() {
    return _instance;
  }

  SharingService._internal();

  /// Share task via WhatsApp
  Future<void> shareTaskWhatsApp({
    required String taskTitle,
    required String taskDescription,
  }) async {
    try {
      final text = '''
📋 Task: $taskTitle

$taskDescription

Download the Task App to manage all your tasks!
      ''';

      await Share.share(text, subject: 'Check out my task!');
    } catch (e) {
      debugPrint('❌ WhatsApp share failed: $e');
      rethrow;
    }
  }

  /// Share task via Twitter
  Future<void> shareTaskTwitter({
    required String taskTitle,
    required String dynamicLink,
  }) async {
    try {
      final encoded = Uri.encodeComponent(
        'Check out my task: $taskTitle\n$dynamicLink\n#TaskManagement #Productivity',
      );
      final url = 'https://twitter.com/intent/tweet?text=$encoded';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ Twitter share failed: $e');
      rethrow;
    }
  }

  /// Share task via Email
  Future<void> shareTaskEmail({
    required String taskTitle,
    required String taskDescription,
    required List<String> recipients,
  }) async {
    try {
      final body = '''
Task: $taskTitle

Description:
$taskDescription

---
Shared via Task App
      ''';

      final url = Uri(
        scheme: 'mailto',
        path: recipients.join(','),
        queryParameters: {
          'subject': 'Task: $taskTitle',
          'body': body,
        },
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('❌ Email share failed: $e');
      rethrow;
    }
  }

  /// Generic share
  Future<void> shareGeneric({
    required String title,
    required String description,
    required String? dynamicLink,
  }) async {
    try {
      String text = '$title\n$description';
      if (dynamicLink != null) {
        text += '\n\n$dynamicLink';
      }

      await Share.share(text, subject: title);
    } catch (e) {
      debugPrint('❌ Generic share failed: $e');
      rethrow;
    }
  }

  /// Copy link to clipboard
  Future<void> copyLinkToClipboard(String link) async {
    try {
      // Use share_plus to copy to clipboard
      await Share.share(link);
      debugPrint('✅ Link copied to clipboard');
    } catch (e) {
      debugPrint('❌ Failed to copy link: $e');
      rethrow;
    }
  }
}

// Firebase Dynamic Link Service
class FirebaseDynamicLinkService {
  static final FirebaseDynamicLinkService _instance =
      FirebaseDynamicLinkService._internal();

  factory FirebaseDynamicLinkService() {
    return _instance;
  }

  FirebaseDynamicLinkService._internal();

  /// Create a dynamic link for a task
  Future<String> createTaskLink({
    required String taskId,
    required String taskTitle,
  }) async {
    try {
      debugPrint('🔗 Creating dynamic link for task: $taskId');

      // Format: https://task.app.com/t/{taskId}
      // In production, use firebase_dynamic_links package
      final link =
          'https://task.app.page.link/?link=https://task.app.com/task/$taskId&apn=com.example.task_app&isi=1234567890';

      debugPrint('✅ Dynamic link created: $link');
      return link;
    } catch (e) {
      debugPrint('❌ Failed to create dynamic link: $e');
      rethrow;
    }
  }

  /// Create a dynamic link for a note
  Future<String> createNoteLink({
    required String noteId,
    required String noteTitle,
  }) async {
    try {
      debugPrint('🔗 Creating dynamic link for note: $noteId');

      final link =
          'https://task.app.page.link/?link=https://task.app.com/note/$noteId&apn=com.example.task_app&isi=1234567890';

      debugPrint('✅ Dynamic link created: $link');
      return link;
    } catch (e) {
      debugPrint('❌ Failed to create dynamic link: $e');
      rethrow;
    }
  }

  /// Handle incoming dynamic link
  Future<String?> handleDynamicLink(String link) async {
    try {
      debugPrint('🔗 Handling dynamic link: $link');

      // Extract ID from link
      if (link.contains('/task/')) {
        final id = link.split('/task/').last;
        return 'task:$id';
      } else if (link.contains('/note/')) {
        final id = link.split('/note/').last;
        return 'note:$id';
      }

      return null;
    } catch (e) {
      debugPrint('❌ Failed to handle dynamic link: $e');
      return null;
    }
  }
}
