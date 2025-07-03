
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// API Provider using Dio and Riverpod
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final courseContentProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  const String apiUrl = 
      'http://139.59.3.28:4011/webservice/rest/server.php?wstoken=af09f50e8876046e3ef8ccf51f4b1db6&wsfunction=local_mycustomapi_get_course_content&moodlewsrestformat=json&courseid=3';
  
  try {
    final response = await dio.get(apiUrl);
    return List<dynamic>.from(response.data);
  } catch (e) {
    throw Exception('Failed to load course content: $e');
  }
});

// Expansion state provider for sections
final sectionExpansionProvider = StateProvider.family<bool, String>((ref, sectionId) => false);

class CourseContentScreen extends ConsumerWidget {
  const CourseContentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseContentAsync = ref.watch(courseContentProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Course Content',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Expand/Collapse all logic
              ref.refresh(courseContentProvider);
            },
            child: const Text(
              'Expand All',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: courseContentAsync.when(
        data: (sections) => _buildContent(context, ref, sections),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(courseContentProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<dynamic> sections) {
    final totalSections = sections.length;
    final totalActivities = sections.fold<int>(
      0, 
      (sum, section) => sum + (section['lessons'] as int? ?? 0),
    );

    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            '$totalSections sections • $totalActivities activities',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        // Content sections
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index] as Map<String, dynamic>;
              return _buildSectionCard(context, ref, section);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, WidgetRef ref, Map<String, dynamic> section) {
    final sectionId = section['id']?.toString() ?? '';
    final isExpanded = ref.watch(sectionExpansionProvider(sectionId));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            ref.read(sectionExpansionProvider(sectionId).notifier).state = expanded;
          },
          leading: _getSectionIcon(section),
          title: Text(
            _cleanTitle(section['title']?.toString() ?? ''),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: _buildSectionSubtitle(section),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                section['duration']?.toString() ?? '',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
            ],
          ),
          children: _buildSubmodules(context, ref, section),
        ),
      ),
    );
  }

  Widget _getSectionIcon(Map<String, dynamic> section) {
    final title = section['title']?.toString().toLowerCase() ?? '';
    final progress = section['progress'] as int? ?? 0;
    
    IconData iconData;
    Color iconColor;
    
    if (title.contains('announcements') || title.contains('general')) {
      iconData = Icons.campaign;
      iconColor = Colors.orange;
    } else if (title.contains('introduction') || title.contains('listening')) {
      iconData = Icons.play_circle_outline;
      iconColor = Colors.blue;
    } else if (title.contains('reading') || title.contains('writing')) {
      iconData = Icons.edit_document;
      iconColor = Colors.green;
    } else if (title.contains('speaking') || title.contains('quiz')) {
      iconData = Icons.quiz;
      iconColor = Colors.purple;
    } else {
      iconData = Icons.library_books;
      iconColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget? _buildSectionSubtitle(Map<String, dynamic> section) {
    final progress = section['progress'] as int? ?? 0;
    final lessons = section['lessons'] as int? ?? 0;
    
    if (progress == 0 && lessons == 0) return null;
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '${section['duration'] ?? ''} • $progress/$lessons completed',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSubmodules(BuildContext context, WidgetRef ref, Map<String, dynamic> section) {
    final submodules = section['submodules'] as List<dynamic>? ?? [];
    
    return submodules.map<Widget>((submodule) {
      final submoduleMap = submodule as Map<String, dynamic>;
      return _buildSubmodule(context, ref, submoduleMap);
    }).toList();
  }

  Widget _buildSubmodule(BuildContext context, WidgetRef ref, Map<String, dynamic> submodule) {
    final content = submodule['content'] as List<dynamic>? ?? [];
    final title = submodule['title']?.toString() ?? '';
    
    if (title.isEmpty && content.length == 1) {
      // Single content item without submodule title
      return _buildContentItem(context, ref, content[0] as Map<String, dynamic>);
    }
    
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 40, right: 16),
      childrenPadding: const EdgeInsets.only(left: 60),
      leading: const Icon(Icons.folder_outlined, color: Colors.grey, size: 20),
      title: Text(
        _cleanTitle(title),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        submodule['duration']?.toString() ?? '',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      children: content.map<Widget>((item) {
        return _buildContentItem(context, ref, item as Map<String, dynamic>);
      }).toList(),
    );
  }

  Widget _buildContentItem(BuildContext context, WidgetRef ref, Map<String, dynamic> content) {
    final type = content['type']?.toString() ?? '';
    final title = content['title']?.toString() ?? '';
    final duration = content['duration']?.toString() ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 60, right: 16),
        leading: _getContentIcon(type),
        title: Text(
          _cleanTitle(title),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              duration,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            if (type == 'quiz')
              Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 16),
          ],
        ),
        onTap: () {
          // Handle content item tap
          _handleContentTap(context, content);
        },
      ),
    );
  }

  Widget _getContentIcon(String type) {
    IconData iconData;
    Color iconColor;
    
    switch (type.toLowerCase()) {
      case 'page':
        iconData = Icons.description_outlined;
        iconColor = Colors.blue;
        break;
      case 'quiz':
        iconData = Icons.quiz_outlined;
        iconColor = Colors.purple;
        break;
      case 'video':
      case 'label':
        iconData = Icons.play_circle_outline;
        iconColor = Colors.red;
        break;
      case 'forum':
        iconData = Icons.forum_outlined;
        iconColor = Colors.orange;
        break;
      case 'subsection':
        iconData = Icons.folder_outlined;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.article_outlined;
        iconColor = Colors.grey;
    }
    
    return Icon(iconData, color: iconColor, size: 18);
  }

  String _cleanTitle(String title) {
    // Remove HTML entities and clean up title
    return title
        .replaceAll('&amp;', '&')
        .replaceAll('📘', '')
        .replaceAll('📗', '')
        .replaceAll('📙', '')
        .trim();
  }

  void _handleContentTap(BuildContext context, Map<String, dynamic> content) {
    final type = content['type']?.toString() ?? '';
    final title = content['title']?.toString() ?? '';
    final description = content['description']?.toString() ?? '';
    
    // Handle different content types
    if (type == 'quiz') {
      _showQuizDialog(context, title);
    } else if (description.contains('youtube.com')) {
      _showVideoDialog(context, title, description);
    } else {
      _showContentDialog(context, title, type);
    }
  }

  void _showQuizDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Quiz content would be loaded here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start quiz logic
            },
            child: const Text('Start Quiz'),
          ),
        ],
      ),
    );
  }

  void _showVideoDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Video content:'),
            const SizedBox(height: 8),
            Text(
              description.trim(),
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open video logic
            },
            child: const Text('Watch Video'),
          ),
        ],
      ),
    );
  }

  void _showContentDialog(BuildContext context, String title, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('This is a $type content item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open content logic
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
