import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExhibitorDetailPage extends StatelessWidget {
  final Map<String, dynamic> exhibitor;

  const ExhibitorDetailPage({super.key, required this.exhibitor});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Exhibitor Details'),
        previousPageTitle: 'Exhibitors',
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and basic info
              Container(
                color: CupertinoColors.systemBackground,
                child: _buildHeader(),
              ),

              SizedBox(height: 16),

              // Action buttons row
              Container(
                width: double.infinity,
                color: CupertinoColors.systemBackground,
                padding: EdgeInsets.all(20),
                child: _buildActionButtons(context),
              ),

              SizedBox(height: 16),

              // Video/Media section
              if (exhibitor['videoUrl'] != null || exhibitor['mediaUrl'] != null)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildMediaSection(),
                ),

              SizedBox(height: 16),

              // About section
              if (exhibitor['about'] != null && exhibitor['about'].toString().isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildAboutSection(),
                ),

              SizedBox(height: 16),

              // Company Representatives section
              if (exhibitor['representatives'] != null && exhibitor['representatives'].isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildRepresentativesSection(),
                ),

              SizedBox(height: 16),

              // Documents section
              if (exhibitor['documents'] != null && exhibitor['documents'].isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildDocumentsSection(),
                ),

              SizedBox(height: 16),

              // Additional Information section
              if (exhibitor['category'] != null || exhibitor['booth'] != null || exhibitor['website'] != null)
                Container(
                  color: CupertinoColors.systemBackground,
                  child: _buildAdditionalInfoSection(),
                ),

              SizedBox(height: 16),

              // Sessions section
              if (exhibitor['sessions'] != null && exhibitor['sessions'].isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildSessionsSection(),
                ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          // Company logo with shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                exhibitor['photo'] ?? exhibitor['logo'] ?? '',
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        CupertinoIcons.building_2_fill,
                        size: 64,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Company name
          Text(
            exhibitor['companyName'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12),

          // Location/Booth with icon
          if (exhibitor['booth'] != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFF9500).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    size: 18,
                    color: Color(0xFFFF9500),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Booth ${exhibitor['booth']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          // Tags/Badges
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (exhibitor['category'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE9D5FF), Color(0xFFF3E8FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFFA78BFA),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    exhibitor['category'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              if (exhibitor['badge'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF6EE7B7),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.star_fill,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 6),
                      Text(
                        exhibitor['badge'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.link,
              label: 'Contact',
              onPressed: () {},
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.doc_text,
              label: 'Notes',
              onPressed: () {},
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.star,
              label: 'Favorite',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF9500).withOpacity(0.1),
            Color(0xFFFF9500).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(0xFFFF9500),
          width: 2,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 14),
        borderRadius: BorderRadius.circular(14),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Color(0xFFFF9500),
              size: 26,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF9500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video section with rounded corners and shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (exhibitor['mediaUrl'] != null)
                      Image.network(
                        exhibitor['mediaUrl'],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                size: 48,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                      ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            CupertinoColors.black.withOpacity(0.1),
                            CupertinoColors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    // Play button overlay
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF7C3AED).withOpacity(0.5),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.play_fill,
                        color: CupertinoColors.white,
                        size: 36,
                      ),
                    ),
                    // Sound button
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: CupertinoColors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoColors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.speaker_2_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Video controls mockup
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.play_fill, color: CupertinoColors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  '2:14',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.35,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Icon(CupertinoIcons.speaker_2_fill, color: CupertinoColors.white, size: 20),
                SizedBox(width: 12),
                Icon(CupertinoIcons.gear_alt_fill, color: CupertinoColors.white, size: 20),
              ],
            ),
          ),
          SizedBox(height: 18),
          // Book demo button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9500), Color(0xFFFF8000)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF9500).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(14),
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Book a Demo With Us!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            exhibitor['about'] ?? exhibitor['description'] ?? '',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentativesSection() {
    final representatives = exhibitor['representatives'] as List<dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPANY REPRESENTATIVES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16),
          ...representatives.map((rep) => _buildRepresentativeCard(rep)),
        ],
      ),
    );
  }

  Widget _buildRepresentativeCard(Map<String, dynamic> rep) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.white,
            CupertinoColors.systemGrey6.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                rep['photo'] ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        color: CupertinoColors.systemGrey,
                        size: 28,
                      ),
                    ),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rep['name'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  rep['title'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF9500).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.chat_bubble_fill,
              color: Color(0xFFFF9500),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final documents = exhibitor['documents'] as List<dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOCUMENTS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16),
          ...documents.map((doc) => _buildDocumentCard(doc)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.white,
            CupertinoColors.systemGrey6.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey4.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.doc_text_fill,
              color: CupertinoColors.white,
              size: 26,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.doc,
                      size: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      doc['size'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF9500).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.arrow_down_circle_fill,
              color: Color(0xFFFF9500),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ADDITIONAL INFORMATION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                CupertinoIcons.chevron_up,
                size: 18,
                color: CupertinoColors.systemOrange,
              ),
            ],
          ),
          SizedBox(height: 16),

          if (exhibitor['category'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.tag,
              label: 'Category',
              value: exhibitor['category'],
            ),

          if (exhibitor['booth'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.location_solid,
              label: 'Booth Number',
              value: exhibitor['booth'],
            ),

          if (exhibitor['website'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.globe,
              label: 'Website',
              value: exhibitor['website'],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CupertinoColors.systemGrey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (value.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSection() {
    final sessions = exhibitor['sessions'] as List<dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSIONS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16),
          ...sessions.map((session) {
            if (session is Map<String, dynamic>) {
              return _buildSessionCard(session);
            } else if (session is String) {
              return _buildSimpleSessionCard(session);
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.white,
            CupertinoColors.systemGrey6.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF7C3AED).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7C3AED).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  session['title'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          if (session['time'] != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.clock_fill,
                    size: 16,
                    color: Color(0xFFFF9500),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session['time'],
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (session['location'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.location_solid,
                    size: 16,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session['location'],
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleSessionCard(String sessionTitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              sessionTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
