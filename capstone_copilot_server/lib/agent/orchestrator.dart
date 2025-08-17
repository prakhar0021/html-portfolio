import 'dart:convert';

import '../models/plan_models.dart';
import '../services/openai_client.dart';
import '../tools/web_search_tool.dart';

class PlanningOrchestrator {
  final OpenAIClient _llm;
  final WebSearchTool _searchTool;

  PlanningOrchestrator({OpenAIClient? llm, WebSearchTool? searchTool})
      : _llm = llm ?? OpenAIClient(),
        _searchTool = searchTool ?? WebSearchTool();

  Future<PlanResponse> generatePlan(PlanRequest request) async {
    final system = 'You are Capstone Copilot, an expert B.Tech capstone mentor. '
        'Produce detailed, feasible project plans for undergraduate teams. '
        'Always return STRICT JSON matching this schema: '\
        '{"projectTitle": string, "problemStatement": string, "goals": string[], "risks": string[], '\
        '"modules": [{"name": string, "description": string, "technologies": string[]}], '\
        '"timeline": [{"week": number, "title": string, "tasks": string[]}], '\
        '"deliverables": string[]}';

    final user = {
      'role': 'user',
      'content': [
        'Idea: ${request.idea}',
        'Domains: ${request.domains.join(', ')}',
        'DurationWeeks: ${request.durationWeeks}',
        'TeamSize: ${request.teamSize}',
        'TechPreferences: ${request.techPreferences.join(', ')}',
        'Constraints: ${request.constraints.join(', ')}',
        'Return JSON only.'
      ].join('\n')
    };

    final content = await _llm.chat(messages: [user as Map<String, String>], system: system);

    try {
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return _planFromJson(decoded);
    } catch (_) {
      return _fallbackPlan(request);
    }
  }

  Future<Map<String, dynamic>> runMentorChat(Map<String, dynamic> payload) async {
    final messages = (payload['messages'] as List<dynamic>? ?? [])
        .map<Map<String, String>>((e) => {
              'role': e['role']?.toString() ?? 'user',
              'content': e['content']?.toString() ?? '',
            })
        .toList();

    final last = messages.isNotEmpty ? messages.last['content'] ?? '' : '';
    final shouldSearch = _shouldUseSearch(last);

    List<Map<String, dynamic>> sources = [];
    String contextBlock = '';

    if (shouldSearch) {
      final results = await _searchTool.search(last);
      sources = results;
      final fetched = <String>[];
      for (final r in results) {
        final link = (r['link'] ?? '').toString();
        if (link.isEmpty) continue;
        final text = await _searchTool.fetchUrl(link);
        fetched.add('Source: ${r['title']}\nURL: $link\n${_truncate(text, 1200)}');
        if (fetched.length >= 3) break;
      }
      contextBlock = fetched.join('\n\n---\n\n');
    }

    final system = 'You are Capstone Copilot, a pragmatic B.Tech project mentor. '
        'Give concise, actionable answers. If you cite web findings, include a short references list.';

    final assistantInstruction = contextBlock.isEmpty
        ? 'Answer the user based on your knowledge.'
        : 'Use the provided context to answer. If a claim is from the web, cite it with [n].\n\nContext:\n$contextBlock';

    final merged = [
      ...messages,
      {'role': 'system', 'content': assistantInstruction},
    ];

    final reply = await _llm.chat(messages: merged, system: system);

    return {
      'message': {'role': 'assistant', 'content': reply},
      'sources': sources,
    };
  }

  PlanResponse _planFromJson(Map<String, dynamic> json) {
    final modules = <PlanModule>[];
    final mods = json['modules'] as List<dynamic>? ?? [];
    for (final m in mods) {
      final map = m as Map<String, dynamic>;
      modules.add(PlanModule(
        name: (map['name'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        technologies: (map['technologies'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      ));
    }

    final timeline = <PlanMilestone>[];
    final t = json['timeline'] as List<dynamic>? ?? [];
    for (final m in t) {
      final map = m as Map<String, dynamic>;
      timeline.add(PlanMilestone(
        week: map['week'] is int ? map['week'] as int : int.tryParse('${map['week']}') ?? 1,
        title: (map['title'] ?? '').toString(),
        tasks: (map['tasks'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      ));
    }

    return PlanResponse(
      projectTitle: (json['projectTitle'] ?? '').toString(),
      problemStatement: (json['problemStatement'] ?? '').toString(),
      goals: (json['goals'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      risks: (json['risks'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      modules: modules,
      timeline: timeline,
      deliverables: (json['deliverables'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  PlanResponse _fallbackPlan(PlanRequest req) {
    final modules = [
      PlanModule(
        name: 'Requirements and Design',
        description: 'Gather requirements, define scope, design system architecture and data models.',
        technologies: [...req.techPreferences, 'UML', 'Figma'],
      ),
      PlanModule(
        name: 'Core Implementation',
        description: 'Build core features aligned to the idea across mobile app and backend.',
        technologies: [...req.techPreferences],
      ),
      PlanModule(
        name: 'Testing and Evaluation',
        description: 'Unit, integration, and user testing with iterative improvements.',
        technologies: ['JUnit', 'Flutter Test'],
      ),
    ];

    final timeline = List.generate(req.durationWeeks, (i) {
      final week = i + 1;
      return PlanMilestone(
        week: week,
        title: week <= 2
            ? 'Planning'
            : week <= req.durationWeeks - 2
                ? 'Build Sprint ${week - 2}'
                : 'Stabilization and Handover',
        tasks: [
          if (week <= 2) 'Requirements and design workshops',
          if (week <= 2) 'Architecture and tech stack decisions',
          if (week > 2 && week <= req.durationWeeks - 2) 'Implement prioritized features',
          if (week > 2 && week <= req.durationWeeks - 2) 'Write tests and docs',
          if (week > req.durationWeeks - 2) 'Bug fixing and performance',
          if (week > req.durationWeeks - 2) 'Prepare final report and demo',
        ],
      );
    });

    return PlanResponse(
      projectTitle: 'Capstone Project Plan',
      problemStatement: 'Create a practical project based on the provided idea: ${req.idea}.',
      goals: [
        'Deliver a functional prototype',
        'Follow clean architecture and best practices',
        'Demonstrate testing and CI readiness',
      ],
      risks: [
        'Scope creep due to evolving requirements',
        'Integration complexity across modules',
        'Timeline pressure near delivery',
      ],
      modules: modules,
      timeline: timeline,
      deliverables: [
        'Project proposal and design document',
        'Working application with source code',
        'Test reports and user documentation',
        'Final presentation and demonstration video',
      ],
    );
  }

  bool _shouldUseSearch(String text) {
    final lower = text.toLowerCase();
    return lower.contains('latest') ||
        lower.contains('2023') ||
        lower.contains('2024') ||
        lower.contains('2025') ||
        lower.contains('market') ||
        lower.contains('compare') ||
        lower.contains('news') ||
        lower.contains('benchmarks') ||
        lower.contains('accuracy') ||
        lower.contains('pricing');
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return text.substring(0, max);
  }
}