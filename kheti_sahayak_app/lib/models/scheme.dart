class Scheme {
  final int id;
  final String name;
  final String description;
  final String? benefits;
  final String? eligibility;
  final String? category;
  final String? link;
  final List<String> requiredDocuments;
  final Map<String, dynamic> eligibilityCriteria;
  final double? minFarmSize;
  final double? maxFarmSize;
  final List<String> crops;
  final List<String> states;
  final List<String> districts;
  final double? minIncome;
  final double? maxIncome;
  final String? landOwnershipType;
  final DateTime? deadline;
  final Map<String, dynamic>? benefitsMatrix;

  Scheme({
    required this.id,
    required this.name,
    required this.description,
    this.benefits,
    this.eligibility,
    this.category,
    this.link,
    this.requiredDocuments = const [],
    this.eligibilityCriteria = const {},
    this.minFarmSize,
    this.maxFarmSize,
    this.crops = const [],
    this.states = const [],
    this.districts = const [],
    this.minIncome,
    this.maxIncome,
    this.landOwnershipType,
    this.deadline,
    this.benefitsMatrix,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      benefits: json['benefits'],
      eligibility: json['eligibility'],
      category: json['category'],
      link: json['link'],
      requiredDocuments: (json['required_documents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      eligibilityCriteria: json['eligibility_criteria'] ?? {},
      minFarmSize: json['min_farm_size'] != null ? (json['min_farm_size'] as num).toDouble() : null,
      maxFarmSize: json['max_farm_size'] != null ? (json['max_farm_size'] as num).toDouble() : null,
      crops: (json['crops'] != null) 
          ? (json['crops'] is String ? List<String>.from(jsonDecode(json['crops'])) : List<String>.from(json['crops']))
          : [],
      states: (json['states'] != null)
          ? (json['states'] is String ? List<String>.from(jsonDecode(json['states'])) : List<String>.from(json['states']))
          : [],
      districts: (json['districts'] != null)
          ? (json['districts'] is String ? List<String>.from(jsonDecode(json['districts'])) : List<String>.from(json['districts']))
          : [],
      minIncome: json['min_income'] != null ? (json['min_income'] as num).toDouble() : null,
      maxIncome: json['max_income'] != null ? (json['max_income'] as num).toDouble() : null,
      landOwnershipType: json['land_ownership_type'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      benefitsMatrix: json['benefits_matrix'] != null 
          ? (json['benefits_matrix'] is String ? jsonDecode(json['benefits_matrix']) : json['benefits_matrix'])
          : null,
    );
  }
}
