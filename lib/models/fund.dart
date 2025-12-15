class Fund {
  final int id;
  final String? axlVcFirm;
  final String? axlVcName;
  final String? axlVcTitle;
  final String? axlVcLocation;
  final String? axlVcLocationNearestBigCity;
  final String? axlVcBio;
  final String? axlVcSince;
  final String? axlVcBoards;
  final String? axlLinkedin;
  final List<Investment>? investments;
  final List<String>? allEducation;
  final List<CompanyType>? companyType;

  Fund({
    required this.id,
    this.axlVcFirm,
    this.axlVcName,
    this.axlVcTitle,
    this.axlVcLocation,
    this.axlVcLocationNearestBigCity,
    this.axlVcBio,
    this.axlVcSince,
    this.axlVcBoards,
    this.axlLinkedin,
    this.investments,
    this.allEducation,
    this.companyType,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Parse investments
    List<Investment>? investmentsList;
    if (json['investments'] is List) {
      investmentsList = (json['investments'] as List)
          .map((e) => Investment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse education
    List<String>? educationList;
    if (json['all_education'] is List) {
      educationList = (json['all_education'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Parse company types
    List<CompanyType>? companyTypeList;
    if (json['company_type'] is List) {
      companyTypeList = (json['company_type'] as List)
          .map((e) => CompanyType.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Fund(
      id: parseInt(json['id']) ?? 0,
      axlVcFirm: json['axl_vc_firm']?.toString(),
      axlVcName: json['axl_vc_name']?.toString(),
      axlVcTitle: json['axl_vc_title']?.toString(),
      axlVcLocation: json['axl_vc_location']?.toString(),
      axlVcLocationNearestBigCity: json['axl_vc_location_nearest_big_city']
          ?.toString(),
      axlVcBio: json['axl_vc_bio']?.toString(),
      axlVcSince: json['axl_vc_since']?.toString(),
      axlVcBoards: json['axl_vc_boards']?.toString(),
      axlLinkedin: json['axl_linkedin']?.toString(),
      investments: investmentsList,
      allEducation: educationList,
      companyType: companyTypeList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'axl_vc_firm': axlVcFirm,
      'axl_vc_name': axlVcName,
      'axl_vc_title': axlVcTitle,
      'axl_vc_location': axlVcLocation,
      'axl_vc_location_nearest_big_city': axlVcLocationNearestBigCity,
      'axl_vc_bio': axlVcBio,
      'axl_vc_since': axlVcSince,
      'axl_vc_boards': axlVcBoards,
      'axl_linkedin': axlLinkedin,
      'investments': investments?.map((e) => e.toJson()).toList(),
      'all_education': allEducation,
      'company_type': companyType?.map((e) => e.toJson()).toList(),
    };
  }

  String get displayName => axlVcName ?? 'Unknown Fund';
  String get displayFirm => axlVcFirm ?? '';
  String get displayTitle => axlVcTitle ?? '';
  String get displayLocation =>
      axlVcLocation ?? axlVcLocationNearestBigCity ?? '';

  String get initials {
    final name = displayName;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
  }
}

class Investment {
  final int? id;
  final String? axlCompanyName;

  Investment({this.id, this.axlCompanyName});

  factory Investment.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Investment(
      id: parseInt(json['id']),
      axlCompanyName: json['axl_company_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'axl_company_name': axlCompanyName};
  }
}

class CompanyType {
  final String? axlCompanyType;
  final int? count;

  CompanyType({this.axlCompanyType, this.count});

  factory CompanyType.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return CompanyType(
      axlCompanyType: json['axl_company_type']?.toString(),
      count: parseInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'axl_company_type': axlCompanyType, 'count': count};
  }
}

class FundsListResponse {
  final int status;
  final String contentType;
  final List<Fund> data;
  final int? count;
  final Map<String, dynamic>? filters;

  FundsListResponse({
    required this.status,
    required this.contentType,
    required this.data,
    this.count,
    this.filters,
  });

  factory FundsListResponse.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    List<Fund> fundsList = [];
    final dataField = json['data'];

    if (dataField is List) {
      for (var i = 0; i < dataField.length; i++) {
        final item = dataField[i];
        if (item is Map<String, dynamic>) {
          try {
            final fund = Fund.fromJson(item);
            fundsList.add(fund);
          } catch (e) {
            print('Error parsing fund at index $i: $e');
          }
        }
      }
    }

    return FundsListResponse(
      status: parseInt(json['status']) ?? 200,
      contentType: json['content_type'] ?? 'application/json',
      data: fundsList,
      count: parseInt(json['count']),
      filters: json['filters'] as Map<String, dynamic>?,
    );
  }
}
