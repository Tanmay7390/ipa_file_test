import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  String? _scrollingLetter;
  final GlobalKey _indexBarKey = GlobalKey();

  // Static JSON data for attendees
  final List<Map<String, dynamic>> _attendees = [
    {
      'id': '1',
      'name': 'Dr. Karan Mehta',
      'email': 'karan.mehta@hospital.com',
      'title': 'Senior Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Plastic Surgeon',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1823',
      'photo': 'https://randomuser.me/api/portraits/men/11.jpg',
      'about':
          'John Smith is an experienced surgeon with over 15 years in the field. He specializes in general and emergency surgery and is passionate about advancing surgical techniques and improving patient outcomes.',
    },
    {
      'id': '2',
      'name': 'Dr. Lavanya Reddy',
      'email': 'lavanya.reddy@medcenter.com',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Aesthetic Surgeon',
      'location': 'Hyderabad, India',
      'countryCode': 'IN',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 2145',
      'photo': 'https://randomuser.me/api/portraits/women/12.jpg',
      'about':
          'Maria Garcia is a dedicated medical resident specializing in internal medicine. She is enthusiastic about learning and attending medical conferences to expand her knowledge and network with fellow healthcare professionals.',
    },
    {
      'id': '3',
      'name': 'Dr. Manish Verma',
      'email': 'manish.verma@clinic.com',
      'title': 'Associate Consultant',
      'organization': 'Max Hospital',
      'role': 'Reconstructive Surgeon',
      'location': 'Delhi, India',
      'countryCode': 'IN',
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
    // Moved from speakers list
    {
      'id': '13',
      'name': 'Dr. Manoj Khanna',
      'title': 'Consultant',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/48.jpg',
    },
    {
      'id': '14',
      'name': 'Dr. Mayank Singh',
      'title': 'Senior Consultant',
      'organization': 'Medanta Hospital',
      'role': 'Attendee',
      'location': 'Gurgaon, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/49.jpg',
    },
    {
      'id': '15',
      'name': 'Dr. Milan Doshi',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Kokilaben Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/50.jpg',
    },
    {
      'id': '16',
      'name': 'Dr. Milind Wagh',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Pune, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/51.jpg',
    },
    {
      'id': '17',
      'name': 'Dr. Mohit Sharma',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/52.jpg',
    },
    {
      'id': '18',
      'name': 'Dr. Mukund Jagannathan',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Manipal Hospital',
      'role': 'Attendee',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/53.jpg',
    },
    {
      'id': '19',
      'name': 'Dr. Narendra Kaushik',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/54.jpg',
    },
    {
      'id': '20',
      'name': 'Dr. Narendrakumar',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Ahmedabad, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/55.jpg',
    },
    {
      'id': '21',
      'name': 'Dr. Nilesh Satbhai',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Kokilaben Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/56.jpg',
    },
    {
      'id': '22',
      'name': 'Dr. Nitin Ghag',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/57.jpg',
    },
    {
      'id': '23',
      'name': 'Dr. Nitin Mokal',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/58.jpg',
    },
    {
      'id': '24',
      'name': 'Dr. Nitin Sethi',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/59.jpg',
    },
    {
      'id': '25',
      'name': 'Dr. P. V. Sudhakar',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Hyderabad, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/60.jpg',
    },
    {
      'id': '26',
      'name': 'Dr. Parag Vibhakar',
      'title': 'Senior Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/61.jpg',
    },
    {
      'id': '27',
      'name': 'Dr. Pradeep Goil',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/62.jpg',
    },
    {
      'id': '28',
      'name': 'Dr. Priti Shukla',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Lucknow, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/24.jpg',
    },
    {
      'id': '29',
      'name': 'Dr. Priya Bansal',
      'title': 'Senior Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/25.jpg',
    },
    {
      'id': '30',
      'name': 'Dr. R. Venkatesh',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Chennai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/63.jpg',
    },
    {
      'id': '31',
      'name': 'Dr. Rahul Amble',
      'title': 'Consultant',
      'organization': 'Manipal Hospital',
      'role': 'Attendee',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/64.jpg',
    },
    {
      'id': '32',
      'name': 'Dr. Raja Shanmugakrishnan',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Chennai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/65.jpg',
    },
    {
      'id': '33',
      'name': 'Dr. Raja Tiwari',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/66.jpg',
    },
    {
      'id': '34',
      'name': 'Dr. Rajan Garach',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/67.jpg',
    },
    {
      'id': '35',
      'name': 'Dr. Rajat Gupta',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/68.jpg',
    },
    {
      'id': '36',
      'name': 'Dr. Rajat Kapoor',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/69.jpg',
    },
    {
      'id': '37',
      'name': 'Dr. Rakesh Kalra',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/70.jpg',
    },
    {
      'id': '38',
      'name': 'Dr. Rameen Lull',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/26.jpg',
    },
    {
      'id': '39',
      'name': 'Dr. Ravi Mahajan',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/71.jpg',
    },
    {
      'id': '40',
      'name': 'Dr. Rustom Ginwala',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/72.jpg',
    },
    {
      'id': '41',
      'name': 'Dr. Sandeep Sattur',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/73.jpg',
    },
    {
      'id': '42',
      'name': 'Dr. Sandeep Sharma',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/74.jpg',
    },
    {
      'id': '43',
      'name': 'Dr. Sandeep Vijayraghavan',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Kochi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/75.jpg',
    },
    {
      'id': '44',
      'name': 'Dr. Sandip Jain',
      'title': 'Senior Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/76.jpg',
    },
    {
      'id': '45',
      'name': 'Dr. Sanjay Dhar',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/77.jpg',
    },
    {
      'id': '46',
      'name': 'Dr. Saumya Mathews',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Kochi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/27.jpg',
    },
    {
      'id': '47',
      'name': 'Dr. Saumya Nayak',
      'title': 'Senior Consultant',
      'organization': 'Manipal Hospital',
      'role': 'Attendee',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/28.jpg',
    },
    {
      'id': '48',
      'name': 'Dr. Saurabh Rawat',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/78.jpg',
    },
    {
      'id': '49',
      'name': 'Dr. Seema Rekha Devi',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Hyderabad, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/29.jpg',
    },
    {
      'id': '50',
      'name': 'Dr. Sheeja Rajan',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Kochi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/30.jpg',
    },
    {
      'id': '51',
      'name': 'Dr. Shilpi Bhadani',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/31.jpg',
    },
    {
      'id': '52',
      'name': 'Dr. Shivangi Saha',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Kolkata, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/32.jpg',
    },
    {
      'id': '53',
      'name': 'Dr. Shrirang Pandit',
      'title': 'Senior Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Pune, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/79.jpg',
    },
    {
      'id': '54',
      'name': 'Dr. Sudhanshu Kothe',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Manipal Hospital',
      'role': 'Attendee',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/80.jpg',
    },
    {
      'id': '55',
      'name': 'Dr. Sudhir Mehta',
      'title': 'Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/81.jpg',
    },
    {
      'id': '56',
      'name': 'Dr. Sukhbir Singh',
      'title': 'Senior Consultant',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/82.jpg',
    },
    {
      'id': '57',
      'name': 'Dr. Sumit Agarwal',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/83.jpg',
    },
    {
      'id': '58',
      'name': 'Dr. Sundeep Vijayraghavan',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Kochi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/84.jpg',
    },
    {
      'id': '59',
      'name': 'Dr. Sunil Arora',
      'title': 'Senior Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/85.jpg',
    },
    {
      'id': '60',
      'name': 'Dr. Sunil Gaba',
      'title': 'Consultant Plastic Surgeon',
      'organization': 'Max Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/86.jpg',
    },
    {
      'id': '61',
      'name': 'Dr. Tejinder Bhatti',
      'title': 'Consultant',
      'organization': 'Apollo Hospital',
      'role': 'Attendee',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/87.jpg',
    },
    {
      'id': '62',
      'name': 'Dr. Uday Bhatt',
      'title': 'Senior Consultant',
      'organization': 'Fortis Hospital',
      'role': 'Attendee',
      'location': 'Ahmedabad, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/88.jpg',
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
    // Remove titles like Dr., Prof., etc.
    final cleaned = fullName.replaceAll(
      RegExp(r'^(Dr\.|Prof\.|Mr\.|Mrs\.|Ms\.)\s*'),
      '',
    );
    final parts = cleaned.split(' ');
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

    // Remove records if there are more than 10 with the same first letter
    _groupedAttendees.forEach((letter, attendees) {
      if (attendees.length > 10) {
        _groupedAttendees[letter] = attendees.sublist(0, 10);
      }
    });
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
              (attendee['title']?.toLowerCase().contains(query) ?? false) ||
              (attendee['location']?.toLowerCase().contains(query) ?? false);
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

  String? _getLetterAtPosition(double localY) {
    final RenderBox? renderBox =
        _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final barHeight = renderBox.size.height;
    final itemHeight = barHeight / 26;
    final index = (localY / itemHeight).floor().clamp(0, 25);
    final letter = String.fromCharCode(65 + index);

    return _groupedAttendees.containsKey(letter) ? letter : null;
  }

  void _handleIndexDragStart(DragStartDetails details) {
    final letter = _getLetterAtPosition(details.localPosition.dy);
    if (letter != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _scrollingLetter = letter;
      });
      _scrollToSection(letter);
    }
  }

  void _handleIndexDragUpdate(DragUpdateDetails details) {
    final letter = _getLetterAtPosition(details.localPosition.dy);
    if (letter != null && letter != _scrollingLetter) {
      HapticFeedback.selectionClick();
      setState(() {
        _scrollingLetter = letter;
      });
      _scrollToSection(letter);
    }
  }

  void _handleIndexDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _scrollingLetter = null;
        });
      }
    });
  }

  void _scrollToSection(String letter) {
    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: Duration.zero, // Instant scroll like iOS
          alignment: 0.0,
        );
      } catch (e) {
        // Ignore scroll errors
      }
    }
  }

  // Helper function to convert country code to emoji flag
  String _countryCodeToEmoji(String countryCode) {
    final codePoints = countryCode.toUpperCase().codeUnits;
    return String.fromCharCodes(
      codePoints.map((code) => 0x1F1E6 + (code - 0x41)),
    );
  }

  Widget _buildSubtitle(BuildContext context, Map<String, dynamic> attendee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attendee['role'] ?? attendee['title'] ?? '',
          style: TextStyle(fontSize: 15, letterSpacing: 0.25),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            if (attendee['countryCode'] != null)
              Text(
                _countryCodeToEmoji(attendee['countryCode']),
                style: TextStyle(fontSize: 14),
              ),
            if (attendee['countryCode'] != null) SizedBox(width: 6),
            Expanded(
              child: Text(
                attendee['location'] ?? attendee['organization'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 0.25,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
                    color: CupertinoColors.systemBackground.resolveFrom(
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
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -0.5),
                      child: CupertinoListSection(
                        margin: EdgeInsets.zero,
                        additionalDividerMargin: 72,
                        backgroundColor: CupertinoColors.systemBackground,
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
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: const CupertinoListTileChevron(),
                            ),
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      AttendeeDetailPage(attendee: attendee),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }, childCount: _groupedAttendees.length),
          ),
        ),
        // A-Z Index on the right - iOS style
        Positioned(
          right: 2,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              key: _indexBarKey,
              onVerticalDragStart: _handleIndexDragStart,
              onVerticalDragUpdate: _handleIndexDragUpdate,
              onVerticalDragEnd: _handleIndexDragEnd,
              child: Container(
                width: 20,
                color: CupertinoColors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(26, (index) {
                    final letter = String.fromCharCode(65 + index);
                    final hasSection = _groupedAttendees.containsKey(letter);

                    return GestureDetector(
                      onTap: hasSection
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _scrollingLetter = letter;
                              });
                              _scrollToSection(letter);
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  if (mounted) {
                                    setState(() {
                                      _scrollingLetter = null;
                                    });
                                  }
                                },
                              );
                            }
                          : null,
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
                  }),
                ),
              ),
            ),
          ),
        ),
        // Floating letter indicator
        if (_scrollingLetter != null)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                _scrollingLetter!,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey.withOpacity(0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
