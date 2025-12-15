class Trial {
  final int id;
  final String? nctNumber;
  final String? axlBriefTitle;
  final String? axlOfficialTitle;
  final String? axlBriefSummary;
  final String? axlDescription;
  final String? axlPhase;
  final String? axlStatus;
  final String? axlCompany;
  final String? axlCompanyName;
  final String? axlCompanyType;
  final String? axlCompanySize;
  final String? axlPrimaryIntervention;
  final String? axlInterventionCategory;
  final String? axlTherapeuticArea;
  final int? enrollment;
  final int? noOfLocation;
  final String? axlStartDate;
  final String? axlPrimaryCompletionDate;
  final String? completionDate;
  final String? conditions;
  final String? interventions;
  final String? locations;
  final String? outcomeMeasures;
  final String? studyDesigns;
  final String? age;
  final String? gender;
  final String? studyFirstPostedDate;
  final double? esm;
  final int? esmAll;
  final int? noOfLocationAll;

  Trial({
    required this.id,
    this.nctNumber,
    this.axlBriefTitle,
    this.axlOfficialTitle,
    this.axlBriefSummary,
    this.axlDescription,
    this.axlPhase,
    this.axlStatus,
    this.axlCompany,
    this.axlCompanyName,
    this.axlCompanyType,
    this.axlCompanySize,
    this.axlPrimaryIntervention,
    this.axlInterventionCategory,
    this.axlTherapeuticArea,
    this.enrollment,
    this.noOfLocation,
    this.axlStartDate,
    this.axlPrimaryCompletionDate,
    this.completionDate,
    this.conditions,
    this.interventions,
    this.locations,
    this.outcomeMeasures,
    this.studyDesigns,
    this.age,
    this.gender,
    this.studyFirstPostedDate,
    this.esm,
    this.esmAll,
    this.noOfLocationAll,
  });

  factory Trial.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic (handles String, int, double, null)
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }

    // Helper function to safely parse double from dynamic
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }

    return Trial(
      id: parseInt(json['id']) ?? 0,
      nctNumber: json['nct_number'],
      axlBriefTitle: json['axl_brief_title'],
      axlOfficialTitle: json['axl_official_title'],
      axlBriefSummary: json['axl_brief_summary'],
      axlDescription: json['axl_description'],
      axlPhase: json['axl_phase'],
      axlStatus: json['axl_status'],
      axlCompany: json['axl_company'],
      axlCompanyName: json['axl_company_name'],
      axlCompanyType: json['axl_company_type'],
      axlCompanySize: json['axl_company_size'],
      axlPrimaryIntervention: json['axl_primary_intervention'],
      axlInterventionCategory: json['axl_intervention_category'],
      axlTherapeuticArea: json['axl_therapeutic_area'],
      enrollment: parseInt(json['enrollment']),
      noOfLocation: parseInt(json['no_of_location']),
      axlStartDate: json['axl_start_date'],
      axlPrimaryCompletionDate: json['axl_primary_completion_date'],
      completionDate: json['completion_date'],
      conditions: json['conditions'],
      interventions: json['interventions'],
      locations: json['locations'],
      outcomeMeasures: json['outcome_measures'],
      studyDesigns: json['study_designs'],
      age: json['age'],
      gender: json['gender'],
      studyFirstPostedDate: json['study_first_posted_date'],
      esm: parseDouble(json['esm']),
      esmAll: parseInt(json['esm_all']),
      noOfLocationAll: parseInt(json['no_of_location_all']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nct_number': nctNumber,
      'axl_brief_title': axlBriefTitle,
      'axl_official_title': axlOfficialTitle,
      'axl_brief_summary': axlBriefSummary,
      'axl_description': axlDescription,
      'axl_phase': axlPhase,
      'axl_status': axlStatus,
      'axl_company': axlCompany,
      'axl_company_name': axlCompanyName,
      'axl_company_type': axlCompanyType,
      'axl_company_size': axlCompanySize,
      'axl_primary_intervention': axlPrimaryIntervention,
      'axl_intervention_category': axlInterventionCategory,
      'axl_therapeutic_area': axlTherapeuticArea,
      'enrollment': enrollment,
      'no_of_location': noOfLocation,
      'axl_start_date': axlStartDate,
      'axl_primary_completion_date': axlPrimaryCompletionDate,
      'completion_date': completionDate,
      'conditions': conditions,
      'interventions': interventions,
      'locations': locations,
      'outcome_measures': outcomeMeasures,
      'study_designs': studyDesigns,
      'age': age,
      'gender': gender,
      'study_first_posted_date': studyFirstPostedDate,
      'esm': esm,
      'esm_all': esmAll,
      'no_of_location_all': noOfLocationAll,
    };
  }

  String get displayName =>
      axlBriefTitle ?? axlOfficialTitle ?? 'Unknown Trial';
  String get displayPhase => axlPhase ?? '';
  String get displayStatus => axlStatus ?? '';
  String get displayConditions => conditions ?? '';
  String get displayInterventions => interventions ?? '';
  String get displayCompany => axlCompanyName ?? axlCompany ?? '';

  String get initials {
    if (nctNumber != null && nctNumber!.isNotEmpty) {
      return nctNumber!
          .substring(0, nctNumber!.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    final title = displayName;
    final parts = title.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return title.isNotEmpty
        ? title.substring(0, title.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
  }
}

class TrialsListResponse {
  final int status;
  final String contentType;
  final List<Trial> data;
  final int? count;
  final int? axlTrialLengthAll;

  TrialsListResponse({
    required this.status,
    required this.contentType,
    required this.data,
    this.count,
    this.axlTrialLengthAll,
  });

  factory TrialsListResponse.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    List<Trial> trialsList = [];
    final dataField = json['data'];

    if (dataField is List) {
      trialsList = [];
      for (var i = 0; i < dataField.length; i++) {
        final item = dataField[i];
        if (item is Map<String, dynamic>) {
          try {
            final trial = Trial.fromJson(item);
            trialsList.add(trial);
          } catch (e) {
            print('Error parsing trial at index $i: $e');
          }
        }
      }
    }

    return TrialsListResponse(
      status: parseInt(json['status']) ?? 200,
      contentType: json['content_type'] ?? 'application/json',
      data: trialsList,
      count: parseInt(json['count']),
      axlTrialLengthAll: parseInt(json['axl_trial_length_all']),
    );
  }
}
