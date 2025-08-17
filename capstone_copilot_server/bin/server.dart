import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/agent/orchestrator.dart';
import '../lib/models/plan_models.dart';

Future<void> main(List<String> args) async {
  dotenv.load();

  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;

  final router = Router();

  router.get('/health', (Request req) async {
    return Response.ok(jsonEncode({
      'status': 'ok',
      'service': 'capstone_copilot_server',
      'time': DateTime.now().toIso8601String(),
    }), headers: {'content-type': 'application/json'});
  });

  // Generate project plan
  router.post('/api/plan', (Request req) async {
    try {
      final body = await req.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final planRequest = PlanRequest.fromJson(json);

      final orchestrator = PlanningOrchestrator();
      final plan = await orchestrator.generatePlan(planRequest);

      return Response.ok(jsonEncode(plan.toJson()), headers: {'content-type': 'application/json'});
    } catch (e, st) {
      stderr.writeln('Error in /api/plan: $e\n$st');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  });

  // Agentic mentor chat
  router.post('/api/mentor/chat', (Request req) async {
    try {
      final body = await req.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final orchestrator = PlanningOrchestrator();
      final result = await orchestrator.runMentorChat(json);

      return Response.ok(jsonEncode(result), headers: {'content-type': 'application/json'});
    } catch (e, st) {
      stderr.writeln('Error in /api/mentor/chat: $e\n$st');
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
    }
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await io.serve(handler, host, port);
  stdout.writeln('✓ Server listening on http://${server.address.host}:${server.port}');
}