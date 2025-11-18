import 'package:flutter/cupertino.dart';
import '../components/page_scaffold.dart';
import '../pages/speaker_detail_page.dart';

class SpeakersTab extends StatefulWidget {
  const SpeakersTab({super.key});

  @override
  State<SpeakersTab> createState() => _SpeakersTabState();
}

class _SpeakersTabState extends State<SpeakersTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Map<String, dynamic>> _filteredSpeakers = [];
  Map<String, List<Map<String, dynamic>>> _groupedSpeakers = {};
  Map<String, GlobalKey> _sectionKeys = {};

  // Static JSON data for speakers
  final List<Map<String, dynamic>> _speakers = [
    {
      'id': '1',
      'name': 'Dr. Sarah Johnson',
      'email': 'sarah.johnson@aesurg.com',
      'title': 'DIRECTOR OF CARDIOVASCULAR SURGERY',
      'specialty': 'Cardiovascular Surgery',
      'company': 'Mayo Clinic',
      'location': 'Rochester, Minnesota',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 2303',
      'photo': 'https://randomuser.me/api/portraits/women/1.jpg',
      'about':
          'Dr. Sarah Johnson is a renowned cardiovascular surgeon with over 20 years of experience. She specializes in minimally invasive cardiac procedures and has pioneered several breakthrough techniques in the field. Her passion for advancing surgical methods has made her a sought-after speaker at medical conferences worldwide.',
      'sessions': [
        {
          'date': 'Friday, September 27',
          'sessionCount': 2,
          'title': 'Opening Keynote - The Future of Cardiovascular Surgery',
          'role': 'Speaker',
          'time': '9:00 am EDT - 10:30 am EDT',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall', 'VIP Access'],
        },
        {
          'date': 'Friday, September 27',
          'sessionCount': 1,
          'title': 'Advanced Techniques in Cardiac Surgery',
          'role': 'Speaker',
          'time': '2:00 pm EDT - 3:30 pm EDT',
          'location': 'Workshop Room A',
          'addToCalendar': true,
          'tags': ['Interactive Breakout Room'],
        },
      ],
    },
    {
      'id': '2',
      'name': 'Prof. Michael Chen',
      'email': 'michael.chen@aesurg.com',
      'title': 'PROFESSOR OF NEUROSURGERY',
      'specialty': 'Neurosurgery',
      'company': 'Johns Hopkins Hospital',
      'location': 'Baltimore, Maryland',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1205',
      'photo': 'https://randomuser.me/api/portraits/men/2.jpg',
      'about':
          'Prof. Michael Chen is a leading neurosurgeon specializing in brain mapping and cognitive neuroscience. With expertise in cutting-edge neuroimaging techniques, he has contributed significantly to understanding brain function during surgical procedures. He is passionate about integrating technology into surgical practice.',
      'sessions': [
        {
          'date': 'Saturday, September 28',
          'sessionCount': 1,
          'title': 'Brain Mapping Technologies in Modern Neurosurgery',
          'role': 'Speaker',
          'time': '10:00 am EDT - 11:30 am EDT',
          'location': 'Tech Innovation Hall',
          'addToCalendar': true,
          'tags': ['Virtual', 'VIP Access'],
        },
        {
          'date': 'Saturday, September 28',
          'sessionCount': 1,
          'title': 'Minimally Invasive Neurosurgical Techniques',
          'role': 'Moderator',
          'time': '1:00 pm EDT - 2:30 pm EDT',
          'location': 'Workshop Room B',
          'addToCalendar': true,
          'tags': ['Interactive Breakout Room'],
        },
      ],
    },
    {
      'id': '3',
      'name': 'Dr. Emily Rodriguez',
      'email': 'emily.rodriguez@aesurg.com',
      'title': 'CHIEF OF ORTHOPEDIC SURGERY',
      'specialty': 'Orthopedic Surgery',
      'company': 'Cleveland Clinic',
      'location': 'Cleveland, Ohio',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1508',
      'photo': 'https://randomuser.me/api/portraits/women/3.jpg',
      'about':
          'Dr. Emily Rodriguez is a pioneer in joint replacement surgery with a focus on sports medicine. She has performed thousands of successful procedures and is known for her patient-centered approach. Her research in biomechanics has led to improved surgical outcomes.',
      'sessions': [
        {
          'date': 'Sunday, September 29',
          'sessionCount': 2,
          'title': 'Joint Replacement Innovations',
          'role': 'Speaker',
          'time': '9:30 am EDT - 11:00 am EDT',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall'],
        },
      ],
    },
    {
      'id': '4',
      'name': 'Dr. James Wilson',
      'email': 'james.wilson@aesurg.com',
      'title': 'DIRECTOR OF PLASTIC SURGERY',
      'specialty': 'Plastic Surgery',
      'company': 'Stanford Medical Center',
      'location': 'Palo Alto, California',
      'photo': 'https://randomuser.me/api/portraits/men/4.jpg',
      'about':
          'Dr. James Wilson specializes in reconstructive and aesthetic surgery. His innovative approaches to facial reconstruction have helped countless patients regain confidence and function.',
      'sessions': [
        {
          'date': 'Monday, September 30',
          'sessionCount': 1,
          'title': 'Reconstructive Surgery Advances',
          'role': 'Speaker',
          'time': '11:00 am EDT - 12:30 pm EDT',
          'location': 'Workshop Room C',
          'addToCalendar': true,
          'tags': ['Interactive Breakout Room'],
        },
      ],
    },
    {
      'id': '5',
      'name': 'Dr. Aisha Patel',
      'email': 'aisha.patel@aesurg.com',
      'title': 'PROFESSOR OF GENERAL SURGERY',
      'specialty': 'General Surgery',
      'company': 'Massachusetts General Hospital',
      'location': 'Boston, Massachusetts',
      'photo': 'https://randomuser.me/api/portraits/women/5.jpg',
      'about':
          'Dr. Aisha Patel is an expert in robotic surgery and minimally invasive techniques. She leads training programs for surgeons worldwide on the latest robotic surgical systems.',
      'sessions': [
        {
          'date': 'Monday, September 30',
          'sessionCount': 1,
          'title': 'Robotic Surgery: The Future is Now',
          'role': 'Moderator',
          'time': '2:00 pm EDT - 3:30 pm EDT',
          'location': 'Tech Innovation Hall',
          'addToCalendar': true,
          'tags': ['Virtual', 'Conference Hall'],
        },
      ],
    },
    {
      'id': '6',
      'name': 'Dr. Robert Martinez',
      'email': 'robert.martinez@aesurg.com',
      'title': 'CHIEF OF PEDIATRIC SURGERY',
      'specialty': 'Pediatric Surgery',
      'company': "Children's Hospital of Philadelphia",
      'location': 'Philadelphia, Pennsylvania',
      'photo': 'https://randomuser.me/api/portraits/men/6.jpg',
      'about':
          'Dr. Robert Martinez has dedicated his career to improving surgical outcomes for children. His gentle approach and expertise in neonatal surgery have made him a trusted name in pediatric care.',
      'sessions': [
        {
          'date': 'Tuesday, October 1',
          'sessionCount': 1,
          'title': 'Advances in Pediatric Surgical Care',
          'role': 'Speaker',
          'time': '9:00 am EDT - 10:30 am EDT',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall', 'VIP Access'],
        },
      ],
    },
    {
      'id': '7',
      'name': 'Dr. Lisa Anderson',
      'email': 'lisa.anderson@aesurg.com',
      'title': 'DIRECTOR OF THORACIC SURGERY',
      'specialty': 'Thoracic Surgery',
      'company': 'MD Anderson Cancer Center',
      'location': 'Houston, Texas',
      'photo': 'https://randomuser.me/api/portraits/women/7.jpg',
      'about':
          'Dr. Lisa Anderson specializes in lung surgery and thoracoscopic procedures. Her research in minimally invasive thoracic surgery has set new standards in patient care.',
      'sessions': [
        {
          'date': 'Tuesday, October 1',
          'sessionCount': 1,
          'title': 'Thoracoscopic Innovations in Lung Surgery',
          'role': 'Speaker',
          'time': '11:00 am EDT - 12:30 pm EDT',
          'location': 'Workshop Room A',
          'addToCalendar': true,
          'tags': ['Interactive Breakout Room'],
        },
      ],
    },
    {
      'id': '8',
      'name': 'Dr. David Kim',
      'email': 'david.kim@aesurg.com',
      'title': 'PROFESSOR OF VASCULAR SURGERY',
      'specialty': 'Vascular Surgery',
      'company': 'UCLA Medical Center',
      'location': 'Los Angeles, California',
      'photo': 'https://randomuser.me/api/portraits/men/8.jpg',
      'about':
          'Dr. David Kim is a leading expert in endovascular techniques and vascular disease management. His innovative approaches have revolutionized treatment options for complex vascular conditions.',
      'sessions': [
        {
          'date': 'Wednesday, October 2',
          'sessionCount': 1,
          'title': 'Endovascular Techniques: Best Practices',
          'role': 'Speaker',
          'time': '2:00 pm EDT - 3:30 pm EDT',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall'],
        },
      ],
    },
    {
      'id': '9',
      'name': 'Dr. David Kim',
      'email': 'david.kim@aesurg.com',
      'title': 'PROFESSOR OF VASCULAR SURGERY',
      'specialty': 'Vascular Surgery',
      'company': 'UCLA Medical Center',
      'location': 'Los Angeles, California',
      'photo': 'https://randomuser.me/api/portraits/men/8.jpg',
      'about':
          'Dr. David Kim is a leading expert in endovascular techniques and vascular disease management. His innovative approaches have revolutionized treatment options for complex vascular conditions.',
      'sessions': [
        {
          'date': 'Wednesday, October 2',
          'sessionCount': 1,
          'title': 'Endovascular Techniques: Best Practices',
          'role': 'Speaker',
          'time': '2:00 pm EDT - 3:30 pm EDT',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall'],
        },
      ],
    },
    {
      'id': '10',
      'name': 'Dr. David Kim',
      'email': 'david.kim@aesurg.com',
      'title': 'PROFESSOR OF VASCULAR SURGERY',
      'specialty': 'Vascular Surgery',
      'company': 'UCLA Medical Center',
      'location': 'Los Angeles, California',
      'photo': 'https://randomuser.me/api/portraits/men/8.jpg',
      'about':
          'Dr. David Kim is a leading expert in endovascular techniques and vascular disease management. His innovative approaches have revolutionized treatment options for complex vascular conditions.',
      'sessions': [
        {
          'date': 'Wednesday, October 2',
          'sessionCount': 1,
          'title': 'Endovascular Techniques: Best Practices',
          'role': 'Speaker',
          'time': '2:00 pm EDT - 3:30 pm EDT',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall'],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredSpeakers = _speakers;
    _groupSpeakers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getFirstName(String fullName) {
    final parts = fullName.split(' ');
    // Get the part after "Dr." or "Prof." if present
    if (parts.first == 'Dr.' || parts.first == 'Prof.') {
      return parts.length > 1 ? parts[1] : parts.first;
    }
    return parts.first;
  }

  void _groupSpeakers() {
    // Sort speakers by first name
    _filteredSpeakers.sort((a, b) {
      final firstNameA = _getFirstName(a['name']);
      final firstNameB = _getFirstName(b['name']);
      return firstNameA.compareTo(firstNameB);
    });

    // Group by first letter of first name
    _groupedSpeakers.clear();
    _sectionKeys.clear();

    for (var speaker in _filteredSpeakers) {
      final firstName = _getFirstName(speaker['name']);
      final firstLetter = firstName[0].toUpperCase();

      if (!_groupedSpeakers.containsKey(firstLetter)) {
        _groupedSpeakers[firstLetter] = [];
        _sectionKeys[firstLetter] = GlobalKey();
      }
      _groupedSpeakers[firstLetter]!.add(speaker);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSpeakers = _speakers;
      } else {
        _filteredSpeakers = _speakers.where((speaker) {
          return speaker['name'].toLowerCase().contains(query) ||
              speaker['specialty'].toLowerCase().contains(query) ||
              speaker['email'].toLowerCase().contains(query);
        }).toList();
      }
      _groupSpeakers();
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
        _filteredSpeakers = _speakers;
        _groupSpeakers();
      }
    });
  }

  Future<void> _onRefresh() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _filteredSpeakers = _speakers;
      _groupSpeakers();
    });
  }

  void _scrollToSection(String letter) {
    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPageScaffold(
          scrollController: _scrollController,
          isLoading: false,
          heading: 'Speakers',
          searchController: _searchController,
          showSearchField: _showSearchField,
          onSearchToggle: (_) => _toggleSearch(),
          onBottomRefresh: () => _onRefresh(),
          onRefresh: _onRefresh,
          sliverList: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entries = _groupedSpeakers.entries.toList();
              final entry = entries[index];
              final letter = entry.key;
              final speakers = entry.value;

              return Column(
                key: _sectionKeys[letter],
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header - Full width
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.tertiarySystemFill.resolveFrom(
                            context,
                          )
                        : CupertinoColors.systemGroupedBackground.resolveFrom(
                            context,
                          ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                  // Speakers list for this section
                  CupertinoListSection(
                    margin: EdgeInsets.zero,
                    additionalDividerMargin: 72,
                    backgroundColor: CupertinoColors.white,
                    topMargin: 0,
                    children: speakers.map((speaker) {
                      return CupertinoListTile(
                        backgroundColor: CupertinoColors.systemBackground
                            .resolveFrom(context),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        leadingSize: 60,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.network(
                            speaker['photo']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const FlutterLogo(size: 60),
                          ),
                        ),
                        title: Text(
                          speaker['name'] ?? '',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.25,
                          ),
                        ),
                        subtitle: Text(
                          speaker['specialty'].toString(),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            letterSpacing: 0.25,
                          ),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  SpeakerDetailPage(speaker: speaker),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }, childCount: _groupedSpeakers.length),
          ),
        ),
        // A-Z Index on the right - vertically centered
        Positioned(
          right: 2,
          top: 0,
          bottom: 0,
          child: Center(
            child: SizedBox(
              width: 20,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 26,
                itemBuilder: (context, index) {
                  final letter = String.fromCharCode(65 + index); // A-Z
                  final hasSection = _groupedSpeakers.containsKey(letter);

                  return GestureDetector(
                    onTap: hasSection ? () => _scrollToSection(letter) : null,
                    child: Container(
                      height: 14,
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasSection
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
