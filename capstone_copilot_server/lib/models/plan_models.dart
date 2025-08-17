class PlanRequest {
  final String idea;
  final List<String> domains;
  final int durationWeeks;
  final int teamSize;
  final List<String> techPreferences;
  final List<String> constraints;

  PlanRequest({
    required this.idea,
    required this.domains,
    required this.durationWeeks,
    required this.teamSize,
    required this.techPreferences,
    required this.constraints,
  });

  factory PlanRequest.fromJson(Map<String, dynamic> json) {
    return PlanRequest(
      idea: json['idea'] as String? ?? '',
      domains: (json['domains'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      durationWeeks: json['durationWeeks'] is int ? json['durationWeeks'] as int : int.tryParse('${json['durationWeeks']}') ?? 12,
      teamSize: json['teamSize'] is int ? json['teamSize'] as int : int.tryParse('${json['teamSize']}') ?? 3,
      techPreferences: (json['techPreferences'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      constraints: (json['constraints'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'idea': idea,
        'domains': domains,
        'durationWeeks': durationWeeks,
        'teamSize': teamSize,
        'techPreferences': techPreferences,
        'constraints': constraints,
      };
}

class PlanModule {
  final String name;
  final String description;
  final List<String> technologies;

  PlanModule({
    required this.name,
    required this.description,
    required this.technologies,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'technologies': technologies,
      };
}

class PlanMilestone {
  final int week;
  final String title;
  final List<String> tasks;

  PlanMilestone({
    required this.week,
    required this.title,
    required this.tasks,
  });

  Map<String, dynamic> toJson() => {
        'week': week,
        'title': title,
        'tasks': tasks,
      };
}

class PlanResponse {
  final String projectTitle;
  final String problemStatement;
  final List<String> goals;
  final List<String> risks;
  final List<PlanModule> modules;
  final List<PlanMilestone> timeline;
  final List<String> deliverables;

  PlanResponse({
    required this.projectTitle,
    required this.problemStatement,
    required this.goals,
    required this.risks,
    required this.modules,
    required this.timeline,
    required this.deliverables,
  });

  Map<String, dynamic> toJson() => {
        'projectTitle': projectTitle,
        'problemStatement': problemStatement,
        'goals': goals,
        'risks': risks,
        'modules': modules.map((m) => m.toJson()).toList(),
        'timeline': timeline.map((m) => m.toJson()).toList(),
        'deliverables': deliverables,
      };
}