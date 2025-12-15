class Person {
  final int id;
  final String? name;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? email;
  final String? website;
  final String? linkedin;
  final String? title;
  final String? titleCategory;
  final String? bio;
  final String? institution;
  final String? department;
  final String? awards;
  final String? education;
  final String? founded;
  final String? professionalBackground;
  final String? industryExperiences;
  final String? boards;
  final String? previousPositions;
  final String? city;
  final String? state;
  final String? country;
  final String? nearestBigCity;
  final String? companyName;
  final int? companyId;
  final List<NotablePosition>? notablePositions;
  final List<Education>? allEducation;
  final List<CompanyType>? companyTypes;

  Person({
    required this.id,
    this.name,
    this.firstName,
    this.middleName,
    this.lastName,
    this.email,
    this.website,
    this.linkedin,
    this.title,
    this.titleCategory,
    this.bio,
    this.institution,
    this.department,
    this.awards,
    this.education,
    this.founded,
    this.professionalBackground,
    this.industryExperiences,
    this.boards,
    this.previousPositions,
    this.city,
    this.state,
    this.country,
    this.nearestBigCity,
    this.companyName,
    this.companyId,
    this.notablePositions,
    this.allEducation,
    this.companyTypes,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? 0,
      name: json['name'],
      firstName: json['axl_first_name'],
      middleName: json['axl_middle_name'],
      lastName: json['axl_last_name'],
      email: json['email'],
      website: json['website'],
      linkedin: json['linkedin'],
      title: json['title'],
      titleCategory: json['title_category'],
      bio: json['bio'],
      institution: json['institution'],
      department: json['department'],
      awards: json['awards'] ?? json['awards_new'],
      education: json['education'],
      founded: json['founded'],
      professionalBackground: json['professional_background'],
      industryExperiences: json['industry_experiences'],
      boards: json['boards'],
      previousPositions: json['previous_positions'],
      city: json['axl_people_location_city'],
      state: json['axl_people_location_state'],
      country: json['axl_people_location_country'],
      nearestBigCity: json['axl_people_location_nearest_big_city'],
      companyName: json['company_name'] ?? json['axl_company'],
      companyId: json['company_id'] ?? json['axl_company_id_id'],
      notablePositions: json['notable_positions'] is List
          ? (json['notable_positions'] as List<dynamic>)
              .map((e) => e is Map<String, dynamic>
                  ? NotablePosition.fromJson(e)
                  : NotablePosition.fromString(e.toString()))
              .toList()
          : null,
      allEducation: json['education'] is List
          ? (json['education'] as List<dynamic>)
              .map((e) => e is Map<String, dynamic>
                  ? Education.fromJson(e)
                  : Education.fromString(e.toString()))
              .toList()
          : null,
      companyTypes: json['company_type'] is List
          ? (json['company_type'] as List<dynamic>)
              .map((e) => e is Map<String, dynamic>
                  ? CompanyType.fromJson(e)
                  : null)
              .where((e) => e != null)
              .cast<CompanyType>()
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'axl_first_name': firstName,
      'axl_middle_name': middleName,
      'axl_last_name': lastName,
      'email': email,
      'website': website,
      'linkedin': linkedin,
      'title': title,
      'title_category': titleCategory,
      'bio': bio,
      'institution': institution,
      'department': department,
      'awards': awards,
      'education': education,
      'founded': founded,
      'professional_background': professionalBackground,
      'industry_experiences': industryExperiences,
      'boards': boards,
      'previous_positions': previousPositions,
      'axl_people_location_city': city,
      'axl_people_location_state': state,
      'axl_people_location_country': country,
      'axl_people_location_nearest_big_city': nearestBigCity,
      'company_name': companyName,
      'company_id': companyId,
      'notable_positions': notablePositions?.map((e) => e.toString()).toList(),
      'all_education': allEducation?.map((e) => e.toString()).toList(),
      'company_type': companyTypes?.map((e) => e.toJson()).toList(),
    };
  }

  String get displayName => name ?? 'Unknown';
  String get displayTitle => titleCategory ?? title ?? '';
  String get displayCompany => companyName ?? institution ?? '';
  String get displayLocation {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  String get initials {
    final nameParts = displayName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}

class NotablePosition {
  final int? id;
  final int rank;
  final String position;
  final String company;
  final String? title;
  final String? companyName;
  final String? titleCategory;
  final String? department;
  final String? startDate;
  final String? endDate;
  final String? location;
  final bool? isPrimary;

  NotablePosition({
    this.id,
    required this.rank,
    required this.position,
    required this.company,
    this.title,
    this.companyName,
    this.titleCategory,
    this.department,
    this.startDate,
    this.endDate,
    this.location,
    this.isPrimary,
  });

  factory NotablePosition.fromJson(Map<String, dynamic> json) {
    return NotablePosition(
      id: json['id'],
      rank: json['axl_rank'] ?? json['rank'] ?? 0,
      position: json['title'] ?? json['position'] ?? '',
      company: json['company_name'] ?? json['company_name_tb'] ?? json['company'] ?? '',
      title: json['title'],
      companyName: json['company_name'] ?? json['company_name_tb'],
      titleCategory: json['title_category'],
      department: json['department'],
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      location: json['location'],
      isPrimary: json['is_primary'] == 'TRUE' || json['is_primary'] == true,
    );
  }

  factory NotablePosition.fromString(String str) {
    // Parse format: "1 - Co-Founder & CEO - Aavia"
    final parts = str.split(' - ');
    if (parts.length >= 3) {
      return NotablePosition(
        rank: int.tryParse(parts[0]) ?? 0,
        position: parts[1],
        company: parts[2],
      );
    }
    return NotablePosition(rank: 0, position: str, company: '');
  }

  @override
  String toString() => '$rank - $position - $company';
}

class Education {
  final int? id;
  final String degree;
  final String institution;
  final String? university;
  final String? field;
  final String? startYear;
  final String? endYear;
  final int? rank;

  Education({
    this.id,
    required this.degree,
    required this.institution,
    this.university,
    this.field,
    this.startYear,
    this.endYear,
    this.rank,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'],
      degree: json['degree'] ?? json['axl_degree'] ?? '',
      institution: json['education_title'] ?? json['university'] ?? json['axl_university'] ?? '',
      university: json['university'] ?? json['axl_university'],
      field: json['field'],
      startYear: json['start_year']?.toString(),
      endYear: json['end_year']?.toString(),
      rank: json['rank'],
    );
  }

  factory Education.fromString(String str) {
    // Parse format: "Master of Business Administration (MBA) - MIT Sloan School of Management"
    final parts = str.split(' - ');
    if (parts.length >= 2) {
      return Education(
        degree: parts[0].trim(),
        institution: parts[1].trim(),
      );
    }
    return Education(degree: str, institution: '');
  }

  @override
  String toString() => '$degree - $institution';
}

class CompanyType {
  final String type;
  final int count;

  CompanyType({
    required this.type,
    required this.count,
  });

  factory CompanyType.fromJson(Map<String, dynamic> json) {
    return CompanyType(
      type: json['axl_company_type'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'axl_company_type': type,
      'count': count,
    };
  }
}

class PeopleListResponse {
  final int status;
  final String contentType;
  final List<Person> data;
  final int? totalCount;
  final Map<String, dynamic>? filters;

  PeopleListResponse({
    required this.status,
    required this.contentType,
    required this.data,
    this.totalCount,
    this.filters,
  });

  factory PeopleListResponse.fromJson(Map<String, dynamic> json) {
    // Handle data field - it should be a list
    List<Person> peopleList = [];
    final dataField = json['data'];

    if (dataField is List) {
      peopleList = [];
      for (var i = 0; i < dataField.length; i++) {
        final item = dataField[i];
        if (item is Map<String, dynamic>) {
          try {
            final person = Person.fromJson(item);
            peopleList.add(person);
          } catch (e) {
            print('Error parsing person at index $i: $e');
            print('Person data: $item');
          }
        }
      }
    }

    return PeopleListResponse(
      status: json['status'] ?? 200,
      contentType: json['content_type'] ?? 'application/json',
      data: peopleList,
      totalCount: json['total_count'],
      filters: json['filters'],
    );
  }
}