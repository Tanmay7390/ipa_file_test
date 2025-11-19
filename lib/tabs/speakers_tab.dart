import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  String? _scrollingLetter;
  final GlobalKey _indexBarKey = GlobalKey();

  // Static JSON data for speakers
  final List<Map<String, dynamic>> _speakers = [
    {
      'id': '1',
      'name': 'Dr. Aditya Aggarwal',
      'email': 'aditya.aggarwal@aesurg.com',
      'title': 'Director & Senior Consultant',
      'specialty': 'Aesthetic & Reconstructive Surgery',
      'company': 'Sir Ganga Ram Hospital',
      'city': 'New Delhi',
      'location': 'New Delhi, India',
      'countryCode': 'IN',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 2303',
      'photo': 'https://randomuser.me/api/portraits/men/1.jpg',
      'about':
          'Dr. Aditya Aggarwal is a renowned plastic surgeon with over 20 years of experience. He specializes in aesthetic and reconstructive procedures and has pioneered several breakthrough techniques in the field.',
      'sessions': [
        {
          'date': 'Friday, January 24',
          'sessionCount': 2,
          'title': 'Opening Keynote - Future of Aesthetic Surgery',
          'role': 'Speaker',
          'time': '9:00 am IST - 10:30 am IST',
          'location': 'Main Conference Hall',
          'addToCalendar': true,
          'tags': ['Conference Hall', 'VIP Access'],
        },
      ],
    },
    {
      'id': '2',
      'name': 'Dr. Ajay Hariani',
      'email': 'ajay.hariani@aesurg.com',
      'title': 'Senior Consultant',
      'specialty': 'Plastic & Reconstructive Surgery',
      'company': 'Kokilaben Hospital',
      'city': 'Mumbai',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
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
      'name': 'Dr. Akshay Kumar Rout',
      'email': 'akshay.rout@aesurg.com',
      'title': 'Consultant Plastic Surgeon',
      'specialty': 'Plastic Surgery',
      'company': 'Apollo Hospital',
      'city': 'Bhubaneswar',
      'location': 'Bhubaneswar, India',
      'countryCode': 'IN',
      'venue': 'Four Season Hotel Toronto',
      'room': 'Room 1508',
      'photo': 'https://randomuser.me/api/portraits/men/3.jpg',
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
      'name': 'Dr. Dinesh Kadam',
      'email': 'dinesh.kadam@aesurg.com',
      'title': 'Consultant Plastic Surgeon',
      'specialty': 'Plastic & Cosmetic Surgery',
      'company': 'Apollo Hospital',
      'location': 'Pune, India',
      'countryCode': 'IN',
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
      'name': 'Dr. Ekta Rai',
      'email': 'ekta.rai@aesurg.com',
      'title': 'Associate Professor',
      'specialty': 'Plastic & Reconstructive Surgery',
      'company': 'Safdarjung Hospital',
      'location': 'New Delhi, India',
      'countryCode': 'IN',
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
      'name': 'Dr. Falguni Shah',
      'email': 'falguni.shah@aesurg.com',
      'title': 'Senior Consultant',
      'specialty': 'Cosmetic & Plastic Surgery',
      'company': 'Kokilaben Hospital',
      'location': 'Mumbai, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/6.jpg',
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
      'name': 'Dr. Gaurav Soni',
      'email': 'gaurav.soni@aesurg.com',
      'title': 'Consultant Plastic Surgeon',
      'specialty': 'Plastic & Aesthetic Surgery',
      'company': 'Max Hospital',
      'location': 'Delhi, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/7.jpg',
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
      'name': 'Dr. Harsh Vardhan',
      'email': 'harsh.vardhan@aesurg.com',
      'title': 'Director of Plastic Surgery',
      'specialty': 'Plastic & Reconstructive Surgery',
      'company': 'Medanta Hospital',
      'location': 'Gurugram, India',
      'countryCode': 'IN',
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
      'name': 'Dr. Isha Gupta',
      'email': 'isha.gupta@aesurg.com',
      'title': 'Senior Plastic Surgeon',
      'specialty': 'Aesthetic Surgery',
      'company': 'Manipal Hospital',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/9.jpg',
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
      'name': 'Dr. Jatin Patel',
      'email': 'jatin.patel@aesurg.com',
      'title': 'Consultant Plastic Surgeon',
      'specialty': 'Plastic & Cosmetic Surgery',
      'company': 'Narayana Health',
      'location': 'Bangalore, India',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/10.jpg',
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
    // Additional 100+ speakers from AESURG 2026
    {
      'id': '11',
      'name': 'Dr. Amit Peswani',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Kokilaben Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/11.jpg',
    },
    {
      'id': '12',
      'name': 'Dr. Amita Hiremath',
      'title': 'Consultant',
      'company': 'Manipal Hospital',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/11.jpg',
    },
    {
      'id': '13',
      'name': 'Dr. Amitabh Singh',
      'title': 'Senior Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/12.jpg',
    },
    {
      'id': '14',
      'name': 'Dr. Anand Joshi',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Pune',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/13.jpg',
    },
    {
      'id': '15',
      'name': 'Dr. Aniket Venkatram',
      'title': 'Consultant',
      'company': 'Narayana Health',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/14.jpg',
    },
    {
      'id': '16',
      'name': 'Dr. Anil Garg',
      'title': 'Senior Consultant',
      'company': 'Fortis Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/15.jpg',
    },
    {
      'id': '17',
      'name': 'Dr. Anil Tibrewala',
      'title': 'Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/16.jpg',
    },
    {
      'id': '18',
      'name': 'Dr. Anjali Saple',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Chennai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/12.jpg',
    },
    {
      'id': '19',
      'name': 'Dr. Anjana Malhotra',
      'title': 'Senior Consultant',
      'company': 'Fortis Hospital',
      'city': 'Gurgaon',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/13.jpg',
    },
    {
      'id': '20',
      'name': 'Dr. Anmol Chugh',
      'title': 'Consultant',
      'company': 'Medanta Hospital',
      'city': 'Gurgaon',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/17.jpg',
    },
    {
      'id': '21',
      'name': 'Dr. Arjun Asokan',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Kochi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/18.jpg',
    },
    {
      'id': '22',
      'name': 'Dr. Arjun Handa',
      'title': 'Senior Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/19.jpg',
    },
    {
      'id': '23',
      'name': 'Dr. Ashish Dhavalbhakta',
      'title': 'Consultant',
      'company': 'Kokilaben Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/20.jpg',
    },
    {
      'id': '24',
      'name': 'Dr. Ashit Shah',
      'title': 'Senior Consultant',
      'company': 'Fortis Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/21.jpg',
    },
    {
      'id': '25',
      'name': 'Dr. Ashutosh Shah',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Ahmedabad',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/22.jpg',
    },
    {
      'id': '26',
      'name': 'Dr. Atul Parashar',
      'title': 'Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/23.jpg',
    },
    {
      'id': '27',
      'name': 'Dr. Atul Sharma',
      'title': 'Senior Consultant',
      'company': 'Medanta Hospital',
      'city': 'Gurgaon',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/24.jpg',
    },
    {
      'id': '28',
      'name': 'Dr. Biblash Babu',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Hyderabad',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/25.jpg',
    },
    {
      'id': '29',
      'name': 'Dr. Brijesh Mishra',
      'title': 'Senior Consultant',
      'company': 'Fortis Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/26.jpg',
    },
    {
      'id': '30',
      'name': 'Dr. Dayanand L. M.',
      'title': 'Consultant',
      'company': 'Manipal Hospital',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/27.jpg',
    },
    {
      'id': '31',
      'name': 'Dr. Dinesh Kadam',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Pune',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/28.jpg',
    },
    {
      'id': '32',
      'name': 'Dr. Ekta Rai',
      'title': 'Associate Professor',
      'company': 'Safdarjung Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/14.jpg',
    },
    {
      'id': '33',
      'name': 'Dr. Falguni Shah',
      'title': 'Senior Consultant',
      'company': 'Kokilaben Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/15.jpg',
    },
    {
      'id': '34',
      'name': 'Dr. Gaurav Soni',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/29.jpg',
    },
    {
      'id': '35',
      'name': 'Dr. Giriraj Gandhi',
      'title': 'Consultant',
      'company': 'Fortis Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/30.jpg',
    },
    {
      'id': '36',
      'name': 'Dr. Hardik Ganatra',
      'title': 'Senior Consultant',
      'company': 'Apollo Hospital',
      'city': 'Ahmedabad',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/31.jpg',
    },
    {
      'id': '37',
      'name': 'Dr. Harsh Amin',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Medanta Hospital',
      'city': 'Gurgaon',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'id': '38',
      'name': 'Dr. Harsh Vardhan',
      'title': 'Director of Plastic Surgery',
      'company': 'Medanta Hospital',
      'city': 'Gurgaon',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/33.jpg',
    },
    {
      'id': '39',
      'name': 'Dr. Isha Gupta',
      'title': 'Senior Plastic Surgeon',
      'company': 'Manipal Hospital',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/16.jpg',
    },
    {
      'id': '40',
      'name': 'Dr. James Roy Kanjoor',
      'title': 'Consultant',
      'company': 'Apollo Hospital',
      'city': 'Kochi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/34.jpg',
    },
    {
      'id': '41',
      'name': 'Dr. Jas Kohli',
      'title': 'Senior Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/35.jpg',
    },
    {
      'id': '42',
      'name': 'Dr. Jatin Patel',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Narayana Health',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/36.jpg',
    },
    {
      'id': '43',
      'name': 'Dr. Jayant Kumar Dash',
      'title': 'Consultant',
      'company': 'Apollo Hospital',
      'city': 'Bhubaneswar',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/37.jpg',
    },
    {
      'id': '44',
      'name': 'Dr. Jayanthi Ravindran',
      'title': 'Senior Consultant',
      'company': 'Fortis Hospital',
      'city': 'Chennai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/17.jpg',
    },
    {
      'id': '45',
      'name': 'Dr. Jyoshid Balan',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Kochi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/38.jpg',
    },
    {
      'id': '46',
      'name': 'Dr. Kapil Agrawal',
      'title': 'Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/39.jpg',
    },
    {
      'id': '47',
      'name': 'Dr. Karishma Kogadu',
      'title': 'Senior Consultant',
      'company': 'Manipal Hospital',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/18.jpg',
    },
    {
      'id': '48',
      'name': 'Dr. Karthik Ram',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Chennai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/40.jpg',
    },
    {
      'id': '49',
      'name': 'Dr. Kavita Agarwal',
      'title': 'Consultant',
      'company': 'Fortis Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/19.jpg',
    },
    {
      'id': '50',
      'name': 'Dr. Kiran Naik',
      'title': 'Senior Consultant',
      'company': 'Narayana Health',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/41.jpg',
    },
    {
      'id': '51',
      'name': 'Dr. Kironmay Sarangi',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Apollo Hospital',
      'city': 'Bhubaneswar',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/42.jpg',
    },
    {
      'id': '52',
      'name': 'Dr. Kuldeep Singh',
      'title': 'Consultant',
      'company': 'Max Hospital',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/43.jpg',
    },
    {
      'id': '53',
      'name': 'Dr. Laxmi Pallukuri',
      'title': 'Senior Consultant',
      'company': 'Apollo Hospital',
      'city': 'Hyderabad',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/20.jpg',
    },
    {
      'id': '54',
      'name': 'Dr. Lokesh Kumar',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Medanta Hospital',
      'city': 'Gurgaon',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/44.jpg',
    },
    {
      'id': '55',
      'name': 'Dr. Madhu K. S.',
      'title': 'Consultant',
      'company': 'Manipal Hospital',
      'city': 'Bangalore',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/21.jpg',
    },
    {
      'id': '56',
      'name': 'Dr. Mahesh Nair',
      'title': 'Senior Consultant',
      'company': 'Apollo Hospital',
      'city': 'Kochi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/45.jpg',
    },
    {
      'id': '57',
      'name': 'Dr. Mahinoor Desai',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Fortis Hospital',
      'city': 'Mumbai',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/22.jpg',
    },
    {
      'id': '58',
      'name': 'Dr. Maneesh Singhal',
      'title': 'Consultant',
      'company': 'AIIMS',
      'city': 'Delhi',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/46.jpg',
    },
    {
      'id': '59',
      'name': 'Dr. Manish Patel',
      'title': 'Senior Consultant',
      'company': 'Apollo Hospital',
      'city': 'Ahmedabad',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/men/47.jpg',
    },
    {
      'id': '60',
      'name': 'Dr. Manjiri Dasgupta',
      'title': 'Consultant Plastic Surgeon',
      'company': 'Fortis Hospital',
      'city': 'Kolkata',
      'countryCode': 'IN',
      'photo': 'https://randomuser.me/api/portraits/women/23.jpg',
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
    // Remove titles like Dr., Prof., etc.
    final cleaned = fullName.replaceAll(
      RegExp(r'^(Dr\.|Prof\.|Mr\.|Mrs\.|Ms\.)\s*'),
      '',
    );
    final parts = cleaned.split(' ');
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

    // Remove records if there are more than 10 with the same first letter
    _groupedSpeakers.forEach((letter, speakers) {
      if (speakers.length > 10) {
        _groupedSpeakers[letter] = speakers.sublist(0, 10);
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSpeakers = _speakers;
      } else {
        _filteredSpeakers = _speakers.where((speaker) {
          return speaker['name'].toLowerCase().contains(query) ||
              (speaker['title']?.toLowerCase().contains(query) ?? false) ||
              (speaker['company']?.toLowerCase().contains(query) ?? false) ||
              (speaker['city']?.toLowerCase().contains(query) ?? false);
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

  String? _getLetterAtPosition(double localY) {
    final RenderBox? renderBox =
        _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final barHeight = renderBox.size.height;
    final itemHeight = barHeight / 26;
    final index = (localY / itemHeight).floor().clamp(0, 25);
    final letter = String.fromCharCode(65 + index);

    return _groupedSpeakers.containsKey(letter) ? letter : null;
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
                  // Section header - Full width with sticky effect using Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                          width: 0.5,
                        ),
                      ),
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
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -0.5),
                      child: CupertinoListSection(
                        margin: EdgeInsets.zero,
                        additionalDividerMargin: 72,
                        backgroundColor: CupertinoColors.systemBackground,
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  speaker['title'].toString(),
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 15,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (speaker['countryCode'] != null)
                                      Text(
                                        _countryCodeToEmoji(
                                          speaker['countryCode'],
                                        ),
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    if (speaker['countryCode'] != null)
                                      SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${speaker['company']}, ${speaker['city'] ?? speaker['location']}',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 14,
                                          letterSpacing: 0.25,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: const CupertinoListTileChevron(),
                            ),
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
                    ),
                  ),
                ],
              );
            }, childCount: _groupedSpeakers.length),
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
                    final hasSection = _groupedSpeakers.containsKey(letter);

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
