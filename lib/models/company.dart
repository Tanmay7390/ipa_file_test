class Company {
  final int id;
  final String? axlCompanyName;
  final String? axlCompanyLegalName;
  final String? description;
  final String? axlCompanyShortDescription;
  final String? axlCompanyLogo;
  final String? axlCompanyWebsite;
  final String? axlCompanyType;
  final String? axlCompanySubtype;
  final String? axlCompanyCategory;
  final String? axlCompanySubcategory;
  final String? axlCompanyState;
  final String? axlCompanyCountry;
  final String? axlUsFlag;
  final String? axlCompanyStatus;
  final String? axlCompanySubstatus;
  final String? axlCompanyLinkedin;
  final String? axlCompanyFoundedYear;
  final String? axlCompanyAddress;
  final String? axlCompanyCity;
  final String? axlCompanySize;
  final String? axlPreviousNames;
  final String? axlExchange;
  final String? axlTicker;
  final String? axlMarkdownOverview;
  final String? axlMarkdownHistory;
  final String? axlMarkdownFounders;
  final String? axlMarkdownManagement;
  final String? axlMarkdownFinancials;
  final String? axlMarkdownProducts;
  final String? axlMarkdownTrials;
  final List<NotablePosition>? notablePositions;

  Company({
    required this.id,
    this.axlCompanyName,
    this.axlCompanyLegalName,
    this.description,
    this.axlCompanyShortDescription,
    this.axlCompanyLogo,
    this.axlCompanyWebsite,
    this.axlCompanyType,
    this.axlCompanySubtype,
    this.axlCompanyCategory,
    this.axlCompanySubcategory,
    this.axlCompanyState,
    this.axlCompanyCountry,
    this.axlUsFlag,
    this.axlCompanyStatus,
    this.axlCompanySubstatus,
    this.axlCompanyLinkedin,
    this.axlCompanyFoundedYear,
    this.axlCompanyAddress,
    this.axlCompanyCity,
    this.axlCompanySize,
    this.axlPreviousNames,
    this.axlExchange,
    this.axlTicker,
    this.axlMarkdownOverview,
    this.axlMarkdownHistory,
    this.axlMarkdownFounders,
    this.axlMarkdownManagement,
    this.axlMarkdownFinancials,
    this.axlMarkdownProducts,
    this.axlMarkdownTrials,
    this.notablePositions,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? 0,
      axlCompanyName: json['axl_company_name'],
      axlCompanyLegalName: json['axl_company_legal_name'],
      description: json['description'],
      axlCompanyShortDescription: json['axl_company_short_description'],
      axlCompanyLogo: json['axl_company_logo'],
      axlCompanyWebsite: json['axl_company_website'],
      axlCompanyType: json['axl_company_type'],
      axlCompanySubtype: json['axl_company_subtype'],
      axlCompanyCategory: json['axl_company_category'],
      axlCompanySubcategory: json['axl_company_subcategory'],
      axlCompanyState: json['axl_company_state'],
      axlCompanyCountry: json['axl_company_country'],
      axlUsFlag: json['axl_us_flag'],
      axlCompanyStatus: json['axl_company_status'],
      axlCompanySubstatus: json['axl_company_substatus'],
      axlCompanyLinkedin: json['axl_company_linkedin'],
      axlCompanyFoundedYear: json['axl_company_founded_year'],
      axlCompanyAddress: json['axl_company_address'],
      axlCompanyCity: json['axl_company_city'],
      axlCompanySize: json['axl_company_size'],
      axlPreviousNames: json['axl_previous_names'],
      axlExchange: json['axl_exchange'],
      axlTicker: json['axl_ticker'],
      axlMarkdownOverview: json['axl_markdown_overview'],
      axlMarkdownHistory: json['axl_markdown_history'],
      axlMarkdownFounders: json['axl_markdown_founders'],
      axlMarkdownManagement: json['axl_markdown_management'],
      axlMarkdownFinancials: json['axl_markdown_financials'],
      axlMarkdownProducts: json['axl_markdown_products'],
      axlMarkdownTrials: json['axl_markdown_trials'],
      notablePositions: json['notable_positions'] is List
          ? (json['notable_positions'] as List<dynamic>)
                .map(
                  (e) => e is Map<String, dynamic>
                      ? NotablePosition.fromJson(e)
                      : null,
                )
                .where((e) => e != null)
                .cast<NotablePosition>()
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'axl_company_name': axlCompanyName,
      'axl_company_legal_name': axlCompanyLegalName,
      'description': description,
      'axl_company_short_description': axlCompanyShortDescription,
      'axl_company_logo': axlCompanyLogo,
      'axl_company_website': axlCompanyWebsite,
      'axl_company_type': axlCompanyType,
      'axl_company_subtype': axlCompanySubtype,
      'axl_company_category': axlCompanyCategory,
      'axl_company_subcategory': axlCompanySubcategory,
      'axl_company_state': axlCompanyState,
      'axl_company_country': axlCompanyCountry,
      'axl_us_flag': axlUsFlag,
      'axl_company_status': axlCompanyStatus,
      'axl_company_substatus': axlCompanySubstatus,
      'axl_company_linkedin': axlCompanyLinkedin,
      'axl_company_founded_year': axlCompanyFoundedYear,
      'axl_company_address': axlCompanyAddress,
      'axl_company_city': axlCompanyCity,
      'axl_company_size': axlCompanySize,
      'axl_previous_names': axlPreviousNames,
      'axl_exchange': axlExchange,
      'axl_ticker': axlTicker,
      'axl_markdown_overview': axlMarkdownOverview,
      'axl_markdown_history': axlMarkdownHistory,
      'axl_markdown_founders': axlMarkdownFounders,
      'axl_markdown_management': axlMarkdownManagement,
      'axl_markdown_financials': axlMarkdownFinancials,
      'axl_markdown_products': axlMarkdownProducts,
      'axl_markdown_trials': axlMarkdownTrials,
      'notable_positions': notablePositions?.map((e) => e.toJson()).toList(),
    };
  }

  String get displayName => axlCompanyName ?? 'Unknown';
  String get displayType => axlCompanyType ?? '';
  String get displayStatus => axlCompanyStatus ?? '';
  String get displayLocation {
    final parts = <String>[];
    if (axlCompanyCity != null && axlCompanyCity!.isNotEmpty) {
      parts.add(axlCompanyCity!);
    }
    if (axlCompanyState != null && axlCompanyState!.isNotEmpty) {
      parts.add(axlCompanyState!);
    }
    if (axlCompanyCountry != null && axlCompanyCountry!.isNotEmpty) {
      parts.add(axlCompanyCountry!);
    }
    return parts.join(', ');
  }

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

class NotablePosition {
  final int? id;
  final int? companyId;
  final int? peopleId;
  final String? titleCategory;
  final String? companyPeopleCategory;
  final String? endDate;
  final String? peopleName;

  NotablePosition({
    this.id,
    this.companyId,
    this.peopleId,
    this.titleCategory,
    this.companyPeopleCategory,
    this.endDate,
    this.peopleName,
  });

  factory NotablePosition.fromJson(Map<String, dynamic> json) {
    return NotablePosition(
      id: json['id'],
      companyId: json['company_id'],
      peopleId: json['people_id'],
      titleCategory: json['title_category'],
      companyPeopleCategory: json['company_people_category'],
      endDate: json['end_date'],
      peopleName: json['people_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'people_id': peopleId,
      'title_category': titleCategory,
      'company_people_category': companyPeopleCategory,
      'end_date': endDate,
      'people_name': peopleName,
    };
  }
}

class CompaniesListResponse {
  final int status;
  final String contentType;
  final List<Company> data;
  final int? totalCount;
  final Map<String, dynamic>? filters;

  CompaniesListResponse({
    required this.status,
    required this.contentType,
    required this.data,
    this.totalCount,
    this.filters,
  });

  factory CompaniesListResponse.fromJson(Map<String, dynamic> json) {
    List<Company> companiesList = [];
    final dataField = json['data'];

    if (dataField is List) {
      companiesList = [];
      for (var i = 0; i < dataField.length; i++) {
        final item = dataField[i];
        if (item is Map<String, dynamic>) {
          try {
            final company = Company.fromJson(item);
            companiesList.add(company);
          } catch (e) {
            print('Error parsing company at index $i: $e');
            print('Company data: $item');
          }
        }
      }
    }

    return CompaniesListResponse(
      status: json['status'] ?? 200,
      contentType: json['content_type'] ?? 'application/json',
      data: companiesList,
      totalCount: json['total_count'],
      filters: json['filters'],
    );
  }
}
