class ProcedureDocument {
  final String name;
  final bool required;
  final String? notes;

  const ProcedureDocument({
    required this.name,
    required this.required,
    this.notes,
  });

  factory ProcedureDocument.fromJson(Map<String, dynamic> json) =>
      ProcedureDocument(
        name: json['name'] as String,
        required: json['required'] as bool,
        notes: json['notes'] as String?,
      );
}

class ProcedureStep {
  final int order;
  final String title;
  final String description;
  final String? ufficio;
  final double? costoStimatoEur;
  final int? tempoStimatoGiorni;
  final List<ProcedureDocument> documents;

  const ProcedureStep({
    required this.order,
    required this.title,
    required this.description,
    this.ufficio,
    this.costoStimatoEur,
    this.tempoStimatoGiorni,
    required this.documents,
  });

  factory ProcedureStep.fromJson(Map<String, dynamic> json) => ProcedureStep(
        order: json['order'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        ufficio: json['ufficio'] as String?,
        costoStimatoEur: (json['costo_stimato_eur'] as num?)?.toDouble(),
        tempoStimatoGiorni: json['tempo_stimato_giorni'] as int?,
        documents: (json['documents'] as List<dynamic>)
            .map((d) => ProcedureDocument.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

class Procedure {
  final String slug;
  final String name;
  final String category;
  final String description;
  final String enteCompetente;
  final List<String> tags;
  final int? tempoStimatoGiorni;
  final double? costoStimatoEur;
  final List<ProcedureStep> steps;

  const Procedure({
    required this.slug,
    required this.name,
    required this.category,
    required this.description,
    required this.enteCompetente,
    required this.tags,
    this.tempoStimatoGiorni,
    this.costoStimatoEur,
    this.steps = const [],
  });

  factory Procedure.fromJson(Map<String, dynamic> json) => Procedure(
        slug: json['slug'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        enteCompetente: json['ente_competente'] as String,
        tags: List<String>.from(json['tags'] as List<dynamic>),
        tempoStimatoGiorni: json['tempo_stimato_giorni'] as int?,
        costoStimatoEur: (json['costo_stimato_eur'] as num?)?.toDouble(),
        steps: json.containsKey('steps')
            ? (json['steps'] as List<dynamic>)
                .map((s) => ProcedureStep.fromJson(s as Map<String, dynamic>))
                .toList()
            : const [],
      );

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'category': category,
        'description': description,
        'ente_competente': enteCompetente,
        'tags': tags,
        'tempo_stimato_giorni': tempoStimatoGiorni,
        'costo_stimato_eur': costoStimatoEur,
      };
}
