import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aesurg26/theme_provider.dart';
import '../components/page_scaffold.dart';
import '../pages/exhibitor_detail_page.dart';

class ExhibitorsTab extends ConsumerStatefulWidget {
  const ExhibitorsTab({super.key});

  @override
  ConsumerState<ExhibitorsTab> createState() => _ExhibitorsTabState();
}

class _ExhibitorsTabState extends ConsumerState<ExhibitorsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  bool _isGridView = false;
  List<Map<String, dynamic>> _filteredExhibitors = [];
  String? _selectedCategory;

  // Static JSON data for exhibitors
  final List<Map<String, dynamic>> _exhibitors = [
    {
      'id': '1',
      'companyName': 'MedTech Innovations',
      'category': 'Surgical Instruments',
      'booth': 'A-101',
      'badge': 'Platinum Sponsor',
      'website': 'www.medtechinnovations.com',
      'description': 'Leading manufacturer of advanced surgical instruments',
      'about':
          'MedTech Innovations is a leading manufacturer of advanced surgical instruments with over 25 years of experience in the medical device industry. We specialize in precision-engineered tools that enhance surgical outcomes and improve patient safety. Our commitment to innovation and quality has made us a trusted partner for hospitals and surgical centers worldwide.',
      'photo':
          'https://ui-avatars.com/api/?name=MedTech+Innovations&size=200&background=5856D6&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800',
      'representatives': [
        {
          'name': 'Michael Chen',
          'title': 'VP of Sales',
          'company': 'MedTech Innovations',
          'photo': 'https://randomuser.me/api/portraits/men/32.jpg',
        },
        {
          'name': 'Sarah Williams',
          'title': 'Product Manager',
          'company': 'MedTech Innovations',
          'photo': 'https://randomuser.me/api/portraits/women/32.jpg',
        },
      ],
      'documents': [
        {'name': 'Product Catalog 2024', 'size': '4.2 MB'},
        {'name': 'Technical Specifications', 'size': '1.8 MB'},
      ],
      'sessions': [
        {
          'title': 'Innovation in Surgical Instruments',
          'time': '10:00 am - 11:00 am EDT',
          'location': 'Demo Room A',
        },
        {
          'title': 'Product Showcase & Demo',
          'time': '2:00 pm - 3:30 pm EDT',
          'location': 'Booth A-101',
        },
      ],
    },
    {
      'id': '2',
      'companyName': 'BioSurgical Solutions',
      'category': 'Medical Devices',
      'booth': 'A-102',
      'badge': 'Gold Sponsor',
      'website': 'www.biosurgical.com',
      'description': 'Innovative medical device solutions for modern surgery',
      'about':
          'BioSurgical Solutions develops cutting-edge medical devices that revolutionize surgical procedures. Our products combine advanced biomaterials with intelligent design to minimize invasiveness and accelerate patient recovery. With a focus on research and development, we continue to push the boundaries of what\'s possible in modern surgery.',
      'photo':
          'https://ui-avatars.com/api/?name=BioSurgical+Solutions&size=200&background=34C759&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800',
      'representatives': [
        {
          'name': 'David Kim',
          'title': 'Senior Sales Director',
          'company': 'BioSurgical Solutions',
          'photo': 'https://randomuser.me/api/portraits/men/33.jpg',
        },
      ],
      'documents': [
        {'name': 'Clinical Studies Report', 'size': '6.5 MB'},
      ],
      'sessions': [
        {
          'title': 'Next-Gen Medical Devices',
          'time': '11:30 am - 12:30 pm EDT',
          'location': 'Conference Room B',
        },
      ],
    },
    {
      'id': '3',
      'companyName': 'SurgiCare Systems',
      'category': 'Operating Room Equipment',
      'booth': 'B-201',
      'badge': 'Exhibitor',
      'website': 'www.surgicare.com',
      'description': 'Complete operating room equipment and systems',
      'about':
          'SurgiCare Systems provides comprehensive operating room solutions, from surgical tables and lighting systems to advanced monitoring equipment. Our integrated approach ensures seamless workflow and optimal patient care. We work closely with healthcare facilities to design custom solutions that meet their specific needs and budget requirements.',
      'photo':
          'https://ui-avatars.com/api/?name=SurgiCare+Systems&size=200&background=007AFF&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=800',
      'representatives': [
        {
          'name': 'Jennifer Martinez',
          'title': 'Account Manager',
          'company': 'SurgiCare Systems',
          'photo': 'https://randomuser.me/api/portraits/women/34.jpg',
        },
        {
          'name': 'Robert Taylor',
          'title': 'Technical Specialist',
          'company': 'SurgiCare Systems',
          'photo': 'https://randomuser.me/api/portraits/men/34.jpg',
        },
      ],
      'documents': [
        {'name': 'Equipment Brochure', 'size': '3.1 MB'},
        {'name': 'Installation Guide', 'size': '2.4 MB'},
      ],
      'sessions': [
        {
          'title': 'OR Equipment Demo',
          'time': '1:00 pm - 2:00 pm EDT',
          'location': 'Booth B-201',
        },
      ],
    },
    {
      'id': '4',
      'companyName': 'Advanced Imaging Corp',
      'category': 'Imaging Technology',
      'booth': 'B-202',
      'badge': 'Silver Sponsor',
      'website': 'www.advancedimaging.com',
      'description': 'State-of-the-art surgical imaging solutions',
      'about':
          'Advanced Imaging Corp specializes in cutting-edge imaging technology for surgical applications. Our high-resolution imaging systems provide surgeons with unprecedented visibility and precision during procedures. We leverage AI and machine learning to enhance image quality and assist in real-time decision-making.',
      'photo':
          'https://ui-avatars.com/api/?name=Advanced+Imaging&size=200&background=FF9500&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=800',
      'representatives': [
        {
          'name': 'Amanda Foster',
          'title': 'Regional Sales Manager',
          'company': 'Advanced Imaging Corp',
          'photo': 'https://randomuser.me/api/portraits/women/35.jpg',
        },
      ],
      'documents': [
        {'name': 'Imaging Solutions Overview', 'size': '5.7 MB'},
      ],
      'sessions': [
        {
          'title': 'AI in Surgical Imaging',
          'time': '3:00 pm - 4:00 pm EDT',
          'location': 'Tech Theater',
        },
      ],
    },
    {
      'id': '5',
      'companyName': 'Precision Robotics',
      'category': 'Robotic Surgery',
      'booth': 'C-301',
      'badge': 'Platinum Sponsor',
      'website': 'www.precisionrobotics.com',
      'description': 'Robotic-assisted surgical systems',
      'about':
          'Precision Robotics is at the forefront of robotic-assisted surgery, developing systems that enhance surgeon capabilities and improve patient outcomes. Our robotic platforms offer unmatched precision, stability, and control, enabling minimally invasive procedures with superior results. We are committed to advancing the future of surgery through continuous innovation.',
      'photo':
          'https://ui-avatars.com/api/?name=Precision+Robotics&size=200&background=FF3B30&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800',
      'representatives': [
        {
          'name': 'Dr. James Wilson',
          'title': 'Chief Medical Officer',
          'company': 'Precision Robotics',
          'photo': 'https://randomuser.me/api/portraits/men/35.jpg',
        },
        {
          'name': 'Lisa Anderson',
          'title': 'Clinical Specialist',
          'company': 'Precision Robotics',
          'photo': 'https://randomuser.me/api/portraits/women/36.jpg',
        },
      ],
      'documents': [
        {'name': 'Robotic Surgery White Paper', 'size': '8.3 MB'},
        {'name': 'Training Materials', 'size': '12.1 MB'},
      ],
      'sessions': [
        {
          'title': 'Robotic Surgery Demonstration',
          'time': '9:00 am - 10:30 am EDT',
          'location': 'Main Exhibition Hall',
        },
        {
          'title': 'Hands-On Training Session',
          'time': '2:30 pm - 4:00 pm EDT',
          'location': 'Training Center',
        },
      ],
    },
    {
      'id': '6',
      'companyName': 'SterileGuard Technologies',
      'category': 'Sterilization Equipment',
      'booth': 'C-302',
      'badge': 'Exhibitor',
      'website': 'www.sterileguard.com',
      'description': 'Advanced sterilization and infection control',
      'about':
          'SterileGuard Technologies provides advanced sterilization equipment and infection control solutions for healthcare facilities. Our systems ensure the highest levels of sterility while maintaining efficiency and ease of use. We help hospitals meet stringent regulatory requirements and protect patient safety.',
      'photo':
          'https://ui-avatars.com/api/?name=SterileGuard&size=200&background=AF52DE&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1581093458791-9d42e2d19e0e?w=800',
      'representatives': [
        {
          'name': 'Thomas Brown',
          'title': 'Product Specialist',
          'company': 'SterileGuard Technologies',
          'photo': 'https://randomuser.me/api/portraits/men/36.jpg',
        },
      ],
      'documents': [
        {'name': 'Compliance Documentation', 'size': '2.9 MB'},
      ],
      'sessions': [
        {
          'title': 'Infection Control Best Practices',
          'time': '11:00 am - 12:00 pm EDT',
          'location': 'Workshop Room C',
        },
      ],
    },
    {
      'id': '7',
      'companyName': 'VitalMed Supplies',
      'category': 'Medical Supplies',
      'booth': 'D-401',
      'badge': 'Gold Sponsor',
      'website': 'www.vitalmed.com',
      'description': 'Complete range of medical and surgical supplies',
      'about':
          'VitalMed Supplies is a trusted distributor of medical and surgical supplies, serving healthcare providers with quality products at competitive prices. Our extensive inventory includes everything from basic consumables to specialized surgical supplies. We pride ourselves on reliable delivery and exceptional customer service.',
      'photo':
          'https://ui-avatars.com/api/?name=VitalMed+Supplies&size=200&background=32ADE6&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=800',
      'representatives': [
        {
          'name': 'Patricia Davis',
          'title': 'Supply Chain Manager',
          'company': 'VitalMed Supplies',
          'photo': 'https://randomuser.me/api/portraits/women/37.jpg',
        },
      ],
      'documents': [
        {'name': 'Supply Catalog 2024', 'size': '7.4 MB'},
      ],
      'sessions': [
        {
          'title': 'Supply Chain Optimization',
          'time': '1:30 pm - 2:30 pm EDT',
          'location': 'Conference Room D',
        },
      ],
    },
    {
      'id': '8',
      'companyName': 'SurgeonWear Pro',
      'category': 'Surgical Apparel',
      'booth': 'D-402',
      'badge': 'Exhibitor',
      'website': 'www.surgeonwear.com',
      'description': 'Premium surgical apparel and protective wear',
      'about':
          'SurgeonWear Pro manufactures premium surgical apparel designed for comfort, protection, and performance. Our products incorporate advanced fabrics and ergonomic designs to support healthcare professionals throughout their shifts. We understand the demands of the surgical environment and deliver apparel that meets those challenges.',
      'photo':
          'https://ui-avatars.com/api/?name=SurgeonWear+Pro&size=200&background=FFCC00&color=333&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=800',
      'representatives': [
        {
          'name': 'Kevin White',
          'title': 'Sales Representative',
          'company': 'SurgeonWear Pro',
          'photo': 'https://randomuser.me/api/portraits/men/37.jpg',
        },
      ],
      'documents': [
        {'name': 'Apparel Catalog', 'size': '4.6 MB'},
      ],
      'sessions': [
        {
          'title': 'Comfort and Safety in Surgical Apparel',
          'time': '10:30 am - 11:30 am EDT',
          'location': 'Booth D-402',
        },
      ],
    },
    {
      'id': '9',
      'companyName': 'PharmaSurg International',
      'category': 'Pharmaceuticals',
      'booth': 'E-501',
      'badge': 'Silver Sponsor',
      'website': 'www.pharmasurg.com',
      'description': 'Surgical pharmaceuticals and anesthetics',
      'about':
          'PharmaSurg International specializes in surgical pharmaceuticals and anesthetics, providing safe and effective medications for perioperative care. Our research-driven approach ensures that we deliver products that meet the highest standards of quality and efficacy. We partner with healthcare providers to improve patient outcomes and surgical success.',
      'photo':
          'https://ui-avatars.com/api/?name=PharmaSurg&size=200&background=FF2D55&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800',
      'representatives': [
        {
          'name': 'Dr. Rachel Green',
          'title': 'Medical Science Liaison',
          'company': 'PharmaSurg International',
          'photo': 'https://randomuser.me/api/portraits/women/38.jpg',
        },
        {
          'name': 'Mark Johnson',
          'title': 'Territory Manager',
          'company': 'PharmaSurg International',
          'photo': 'https://randomuser.me/api/portraits/men/38.jpg',
        },
      ],
      'documents': [
        {'name': 'Product Monographs', 'size': '5.2 MB'},
        {'name': 'Safety Data Sheets', 'size': '3.8 MB'},
      ],
      'sessions': [
        {
          'title': 'Advances in Anesthesia',
          'time': '2:00 pm - 3:00 pm EDT',
          'location': 'Medical Theater',
        },
      ],
    },
    {
      'id': '10',
      'companyName': 'Digital Health Analytics',
      'category': 'Healthcare IT',
      'booth': 'E-502',
      'badge': 'Platinum Sponsor',
      'website': 'www.digitalhealthanalytics.com',
      'description': 'Healthcare IT solutions and data analytics',
      'about':
          'Digital Health Analytics provides comprehensive healthcare IT solutions and data analytics platforms that transform how healthcare organizations operate. Our cloud-based systems integrate seamlessly with existing infrastructure, providing real-time insights and improving operational efficiency. We empower healthcare providers with the tools they need to deliver better patient care.',
      'photo':
          'https://ui-avatars.com/api/?name=Digital+Health&size=200&background=30B0C7&color=fff&bold=true',
      'mediaUrl':
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
      'representatives': [
        {
          'name': 'Alex Turner',
          'title': 'Solutions Architect',
          'company': 'Digital Health Analytics',
          'photo': 'https://randomuser.me/api/portraits/men/39.jpg',
        },
        {
          'name': 'Emily Chen',
          'title': 'Data Analytics Lead',
          'company': 'Digital Health Analytics',
          'photo': 'https://randomuser.me/api/portraits/women/39.jpg',
        },
      ],
      'documents': [
        {'name': 'Platform Overview', 'size': '6.9 MB'},
        {'name': 'Integration Guide', 'size': '4.3 MB'},
      ],
      'sessions': [
        {
          'title': 'Healthcare Data Analytics Workshop',
          'time': '9:30 am - 11:00 am EDT',
          'location': 'Innovation Lab',
        },
        {
          'title': 'Cloud Solutions Demo',
          'time': '3:30 pm - 4:30 pm EDT',
          'location': 'Booth E-502',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredExhibitors = _exhibitors;
    _searchController.addListener(_onSearchChanged);
  }

  List<String> _getAllCategories() {
    final categories = _exhibitors
        .map((e) => e['category'].toString())
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredExhibitors = _exhibitors.where((exhibitor) {
        // Category filter
        if (_selectedCategory != null &&
            exhibitor['category'] != _selectedCategory) {
          return false;
        }

        // Search filter
        if (query.isNotEmpty) {
          return exhibitor['companyName'].toLowerCase().contains(query) ||
              exhibitor['category'].toLowerCase().contains(query) ||
              exhibitor['booth'].toLowerCase().contains(query) ||
              exhibitor['description'].toLowerCase().contains(query);
        }

        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
        _applyFilters();
      }
    });
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _filteredExhibitors = _exhibitors;
    });
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Platinum Sponsor':
        return const Color(0xFF5856D6);
      case 'Gold Sponsor':
        return const Color(0xFFFFCC00);
      case 'Silver Sponsor':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF34C759);
    }
  }

  Widget _buildViewToggleButton(bool isDarkMode) {
    final activeColor = isDarkMode ? Color(0xFF23C061) : Color(0xFF21AA62);

    return SizedBox(
      height: 32,
      child: CupertinoSlidingSegmentedControl<bool>(
        groupValue: _isGridView,
        backgroundColor: isDarkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        thumbColor: activeColor,
        padding: const EdgeInsets.all(2),
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _isGridView = value;
            });
          }
        },
        children: {
          false: Container(
            width: 32,
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.list_bullet,
              size: 18,
              color: !_isGridView
                  ? Colors.white
                  : (isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2),
            ),
          ),
          true: Container(
            width: 32,
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.square_grid_2x2,
              size: 18,
              color: _isGridView
                  ? Colors.white
                  : (isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2),
            ),
          ),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final cardBg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: false,
      heading: 'Exhibitors',
      trailing: _buildViewToggleButton(isDarkMode),
      searchController: _searchController,
      showSearchField: _showSearchField,
      onSearchToggle: (_) => _toggleSearch(),
      onBottomRefresh: () => _onRefresh(),
      onRefresh: _onRefresh,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          // Category Filter
          _buildCategoryFilter(isDarkMode),
          // Grid/List View Container
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation =
                    Tween<Offset>(
                      begin: const Offset(0.15, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      ),
                    );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _isGridView
                  ? _buildGridContent(isDarkMode, cardBg, textColor)
                  : _buildListContent(isDarkMode, cardBg, textColor),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDarkMode) {
    final categories = _getAllCategories();
    final activeColor = isDarkMode ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Categories chip
            _buildCategoryChip(
              'All',
              _selectedCategory == null,
              () => _filterByCategory(null),
              isDarkMode,
              activeColor,
            ),
            const SizedBox(width: 8),
            // Individual category chips
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  category,
                  _selectedCategory == category,
                  () => _filterByCategory(category),
                  isDarkMode,
                  activeColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDarkMode,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDarkMode
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent(bool isDarkMode, Color cardBg, Color textColor) {
    final cols = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    return GridView.builder(
      key: const ValueKey('grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredExhibitors.length,
      itemBuilder: (context, index) {
        final exhibitor = _filteredExhibitors[index];
        return _buildExhibitorGridCard(
          exhibitor,
          isDarkMode,
          cardBg,
          textColor,
        );
      },
    );
  }

  Widget _buildListContent(bool isDarkMode, Color cardBg, Color textColor) {
    return ListView.builder(
      key: const ValueKey('list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredExhibitors.length,
      itemBuilder: (context, index) {
        final exhibitor = _filteredExhibitors[index];
        final isLast = index == _filteredExhibitors.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: _buildExhibitorListCard(
            exhibitor,
            isDarkMode,
            cardBg,
            textColor,
          ),
        );
      },
    );
  }

  Widget _buildExhibitorGridCard(
    Map<String, dynamic> exhibitor,
    bool isDarkMode,
    Color cardBg,
    Color textColor,
  ) {
    final activeColor = isDarkMode ? Color(0xFF23C061) : Color(0xFF21AA62);

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) => ExhibitorDetailPage(exhibitor: exhibitor),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF1C1C1E), const Color(0xFF1A1A1C)]
                : [Colors.white, const Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : _getBadgeColor(exhibitor['badge']).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo with overlay gradient
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(exhibitor['photo']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Name
                        Text(
                          exhibitor['companyName'],
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Category with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                CupertinoIcons.cube_box_fill,
                                size: 11,
                                color: activeColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                exhibitor['category'],
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Booth Number with enhanced design
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 13,
                                color: activeColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                exhibitor['booth'],
                                style: TextStyle(
                                  color: activeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Badge positioned at top right
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getBadgeColor(exhibitor['badge']),
                      _getBadgeColor(
                        exhibitor['badge'],
                      ).withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getBadgeColor(
                        exhibitor['badge'],
                      ).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  exhibitor['badge'].toString().replaceAll(' Sponsor', ''),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExhibitorListCard(
    Map<String, dynamic> exhibitor,
    bool isDarkMode,
    Color cardBg,
    Color textColor,
  ) {
    final activeColor = isDarkMode ? Color(0xFF23C061) : Color(0xFF21AA62);

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) => ExhibitorDetailPage(exhibitor: exhibitor),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDarkMode
                ? [const Color(0xFF1C1C1E), const Color(0xFF1A1A1C)]
                : [Colors.white, const Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : _getBadgeColor(exhibitor['badge']).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Row(
                children: [
                  // Company Logo with gradient overlay
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(exhibitor['photo']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              isDarkMode
                                  ? const Color(
                                      0xFF1C1C1E,
                                    ).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Company Name
                          Text(
                            exhibitor['companyName'],
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Category with icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  CupertinoIcons.cube_box_fill,
                                  size: 12,
                                  color: activeColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exhibitor['category'],
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Booth Number
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  size: 13,
                                  color: activeColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  exhibitor['booth'],
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Chevron
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: activeColor,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              // Badge positioned at top left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getBadgeColor(exhibitor['badge']),
                        _getBadgeColor(
                          exhibitor['badge'],
                        ).withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getBadgeColor(
                          exhibitor['badge'],
                        ).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    exhibitor['badge'].toString().replaceAll(' Sponsor', ''),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
