class Recipe {
  final String id;
  final String name;
  final String notes;

  const Recipe({
    this.id = '',
    this.name = '',
    this.notes = '',
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        notes: json['notes'] ?? '',
      );

  Recipe copyWith({
    String? id,
    String? name,
    String? notes,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'notes': notes,
      };

  Map<String, dynamic> toMap() => toJson();
}
