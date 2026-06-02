import 'package:adondeamos/core/api/api_providers.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/features/auth/auth_controller.dart';
import 'package:adondeamos/shared/models/decision_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Estado local de la decisión activa
final activeDecisionProvider =
    NotifierProvider<ActiveDecisionNotifier, Decision?>(
      ActiveDecisionNotifier.new,
    );

class ActiveDecisionNotifier extends Notifier<Decision?> {
  @override
  Decision? build() => null;

  void set(Decision decision) => state = decision;
  void clear() => state = null;
}

// Operaciones sobre decisiones (no un Notifier, es un helper stateless)
final decisionOpsProvider = Provider<DecisionOps>((ref) => DecisionOps(ref));

class DecisionOps {
  const DecisionOps(this._ref);

  final Ref _ref;

  String? get _token => _ref.read(authControllerProvider).asData?.value.token;

  Future<Decision> createDecision({String? groupId, String? context}) async {
    final token = _token;
    if (token == null) throw const ApiException('Sin sesión activa.');

    final decision = await _ref
        .read(decisionsApiProvider)
        .createDecision(token: token, groupId: groupId, context: context);
    _ref.read(activeDecisionProvider.notifier).set(decision);
    return decision;
  }

  Future<Decision> addFromSaves(String decisionId) async {
    final token = _token;
    if (token == null) throw const ApiException('Sin sesión activa.');

    final decision = await _ref
        .read(decisionsApiProvider)
        .addOptions(
          token: token,
          decisionId: decisionId,
          autoFillFromSaves: true,
        );
    _ref.read(activeDecisionProvider.notifier).set(decision);
    return decision;
  }

  Future<Decision> castVote({
    required String decisionId,
    required String optionId,
    required bool isYes,
  }) async {
    final token = _token;
    if (token == null) throw const ApiException('Sin sesión activa.');

    final decision = await _ref
        .read(decisionsApiProvider)
        .castVote(
          token: token,
          decisionId: decisionId,
          optionId: optionId,
          isYes: isYes,
        );
    _ref.read(activeDecisionProvider.notifier).set(decision);
    return decision;
  }

  Future<Decision> refresh(String decisionId) async {
    final token = _token;
    if (token == null) throw const ApiException('Sin sesión activa.');

    final decision = await _ref
        .read(decisionsApiProvider)
        .getDecision(token: token, decisionId: decisionId);
    _ref.read(activeDecisionProvider.notifier).set(decision);
    return decision;
  }
}
