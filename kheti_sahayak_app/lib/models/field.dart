class Field {
  final int? id;
  final String name;
  final double area; // in acres
  final String cropType;
  final String location;

  Field({
    this.id,
    required this.name,
    required this.area,
    required this.cropType,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'crop_type': cropType,
      'location': location,
    };
  }

  factory Field.fromMap(Map<String, dynamic> map) {
    return Field(
      id: map['id'],
      name: map['name'],
      area: map['area'],
      cropType: map['crop_type'],
      location: map['location'],
    );
  }
}
