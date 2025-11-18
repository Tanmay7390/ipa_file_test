import 'package:flutter/cupertino.dart';
import '../components/page_scaffold.dart';
import '../pages/attendee_detail_page.dart';

class AttendeesTab extends StatefulWidget {
  const AttendeesTab({super.key});

  @override
  State<AttendeesTab> createState() => _AttendeesTabState();
}

class _AttendeesTabState extends State<AttendeesTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Map<String, dynamic>> _filteredAttendees = [];
  Map<String, List<Map<String, dynamic>>> _groupedAttendees = {};
  Map<String, GlobalKey> _sectionKeys = {};

  // Static JSON data for attendees
  final List<Map<String, dynamic>> _attendees = [
    {
      'id': '1',
      'name': 'John Smith',
      'email': 'john.smith@hospital.com',
      'title': 'DIRECTOR OF SURGERY',
      'organization': 'City General Hospital',
      'role': 'Surgeon',
      'location': 'New York, NY',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1823',
      'photo': 'https://randomuser.me/api/portraits/men/11.jpg',
      'about':
          'John Smith is an experienced surgeon with over 15 years in the field. He specializes in general and emergency surgery and is passionate about advancing surgical techniques and improving patient outcomes.',
    },
    {
      'id': '2',
      'name': 'Maria Garcia',
      'email': 'maria.garcia@medcenter.com',
      'title': 'MEDICAL RESIDENT',
      'organization': 'Medical Center of Excellence',
      'role': 'Resident',
      'location': 'Los Angeles, CA',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 2145',
      'photo': 'https://randomuser.me/api/portraits/women/12.jpg',
      'about':
          'Maria Garcia is a dedicated medical resident specializing in internal medicine. She is enthusiastic about learning and attending medical conferences to expand her knowledge and network with fellow healthcare professionals.',
    },
    {
      'id': '3',
      'name': 'Ahmed Hassan',
      'email': 'ahmed.hassan@clinic.com',
      'title': 'SURGICAL FELLOW',
      'organization': 'Advanced Surgical Clinic',
      'role': 'Fellow',
      'location': 'Chicago, IL',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1567',
      'photo': 'https://randomuser.me/api/portraits/men/13.jpg',
      'about':
          'Ahmed Hassan is a surgical fellow with a keen interest in minimally invasive procedures. He actively participates in medical conferences to stay updated with the latest advancements in surgical technology.',
    },
    {
      'id': '4',
      'name': 'Jennifer Lee',
      'email': 'jennifer.lee@healthsystem.com',
      'title': 'ATTENDING PHYSICIAN',
      'organization': 'Metro Health System',
      'role': 'Attending Physician',
      'location': 'Seattle, WA',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1998',
      'photo': 'https://randomuser.me/api/portraits/women/14.jpg',
      'about':
          'Jennifer Lee is an attending physician with expertise in patient care and medical education. She is committed to mentoring the next generation of physicians and staying current with medical innovations.',
    },
    {
      'id': '5',
      'name': 'Carlos Rodriguez',
      'email': 'carlos.rodriguez@hospital.org',
      'title': 'CHIEF RESIDENT',
      'organization': 'Regional Medical Center',
      'role': 'Chief Resident',
      'location': 'Miami, FL',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 2067',
      'photo': 'https://randomuser.me/api/portraits/men/15.jpg',
      'about':
          'Carlos Rodriguez serves as Chief Resident, leading his team with dedication and excellence. He has a strong interest in surgical education and quality improvement initiatives.',
    },
    {
      'id': '6',
      'name': 'Priya Sharma',
      'email': 'priya.sharma@healthcenter.com',
      'title': 'MEDICAL STUDENT',
      'organization': 'University Health Center',
      'role': 'Medical Student',
      'location': 'Boston, MA',
      'photo': 'https://randomuser.me/api/portraits/women/16.jpg',
      'about':
          'Priya Sharma is an aspiring medical student passionate about healthcare and patient advocacy. She attends conferences to learn from experienced professionals and explore various medical specialties.',
    },
    {
      'id': '7',
      'name': 'Thomas Anderson',
      'email': 'thomas.anderson@clinic.net',
      'organization': 'Specialty Surgical Group',
      'role': 'Surgeon',
      'photo': 'https://randomuser.me/api/portraits/men/17.jpg',
    },
    {
      'id': '8',
      'name': 'Sophie Martin',
      'email': 'sophie.martin@hospital.fr',
      'organization': 'International Medical Institute',
      'role': 'Research Fellow',
      'photo': 'https://randomuser.me/api/portraits/women/18.jpg',
    },
    {
      'id': '9',
      'name': 'Raj Patel',
      'email': 'raj.patel@medgroup.com',
      'organization': 'Surgical Associates',
      'role': 'Partner',
      'photo': 'https://randomuser.me/api/portraits/men/19.jpg',
    },
    {
      'id': '10',
      'name': 'Emma Wilson',
      'email': 'emma.wilson@healthcare.com',
      'organization': 'Community Healthcare Network',
      'role': 'Intern',
      'photo': 'https://randomuser.me/api/portraits/women/20.jpg',
    },
    {
      'id': '11',
      'name': 'Luis Fernandez',
      'email': 'luis.fernandez@medcenter.es',
      'organization': 'Centro Medico Especializado',
      'role': 'Consultant',
      'photo': 'https://randomuser.me/api/portraits/men/21.jpg',
    },
    {
      'id': '12',
      'name': 'Yuki Tanaka',
      'email': 'yuki.tanaka@hospital.jp',
      'organization': 'Tokyo Medical University',
      'role': 'Associate Professor',
      'photo': 'https://randomuser.me/api/portraits/men/22.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredAttendees = _attendees;
    _groupAttendees();
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
    return parts.first;
  }

  void _groupAttendees() {
    // Sort attendees by first name
    _filteredAttendees.sort((a, b) {
      final firstNameA = _getFirstName(a['name']);
      final firstNameB = _getFirstName(b['name']);
      return firstNameA.compareTo(firstNameB);
    });

    // Group by first letter of first name
    _groupedAttendees.clear();
    _sectionKeys.clear();

    for (var attendee in _filteredAttendees) {
      final firstName = _getFirstName(attendee['name']);
      final firstLetter = firstName[0].toUpperCase();

      if (!_groupedAttendees.containsKey(firstLetter)) {
        _groupedAttendees[firstLetter] = [];
        _sectionKeys[firstLetter] = GlobalKey();
      }
      _groupedAttendees[firstLetter]!.add(attendee);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAttendees = _attendees;
      } else {
        _filteredAttendees = _attendees.where((attendee) {
          return attendee['name'].toLowerCase().contains(query) ||
              attendee['organization'].toLowerCase().contains(query) ||
              attendee['role'].toLowerCase().contains(query) ||
              attendee['email'].toLowerCase().contains(query);
        }).toList();
      }
      _groupAttendees();
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
        _filteredAttendees = _attendees;
        _groupAttendees();
      }
    });
  }

  Future<void> _onRefresh() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _filteredAttendees = _attendees;
      _groupAttendees();
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

  Widget _buildSubtitle(BuildContext context, Map<String, dynamic> attendee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attendee['role'],
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ),
        Text(
          attendee['organization'],
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey2.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPageScaffold(
          scrollController: _scrollController,
          isLoading: false,
          heading: 'Attendees',
          searchController: _searchController,
          showSearchField: _showSearchField,
          onSearchToggle: (_) => _toggleSearch(),
          onBottomRefresh: () => _onRefresh(),
          onRefresh: _onRefresh,
          sliverList: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entries = _groupedAttendees.entries.toList();
              final entry = entries[index];
              final letter = entry.key;
              final attendees = entry.value;

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
                  // Attendees list for this section
                  CupertinoListSection(
                    margin: EdgeInsets.zero,
                    additionalDividerMargin: 72,
                    backgroundColor: CupertinoColors.white,
                    topMargin: 0,
                    children: attendees.map((attendee) {
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
                            attendee['photo']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const FlutterLogo(size: 60),
                          ),
                        ),
                        title: Text(
                          attendee['name'] ?? '',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.25,
                          ),
                        ),
                        subtitle: _buildSubtitle(context, attendee),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  AttendeeDetailPage(attendee: attendee),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }, childCount: _groupedAttendees.length),
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
                  final hasSection = _groupedAttendees.containsKey(letter);

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
