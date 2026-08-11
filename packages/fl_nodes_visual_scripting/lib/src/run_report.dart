/// What happened to one node during an [AutomationEngine.run] call.
enum AutomationNodeOutcome {
  /// The node's `onExecute` returned normally.
  completed,

  /// The node's `onExecute` threw. The run is not necessarily over — a
  /// downstream node the failed one never reached simply never runs — but
  /// this specific node did not do what it was supposed to.
  exception,
}

class AutomationNodeResult {
  const AutomationNodeResult({required this.nodeType, required this.outcome});

  /// The node prototype's `idName` (e.g. `action.send_canned_message`) —
  /// not a per-instance id. Recording is done by the `automationNode`
  /// wrapper itself (see `node_builders.dart`), which fl_nodes_core's raw
  /// `OnNodeExecute` callback shape does not hand a node instance id to.
  final String nodeType;
  final AutomationNodeOutcome outcome;

  Map<String, dynamic> toJson() => {'nodeType': nodeType, 'outcome': outcome.name};
}

/// Everything that happened during one [AutomationEngine.run] call — the
/// audit trail a host persists (e.g. RepairX's `workflow_runs` collection,
/// one row per run, this object's [toJson] as its payload).
class AutomationRunReport {
  AutomationRunReport({required this.startedAt});

  final DateTime startedAt;
  DateTime? finishedAt;

  /// One entry per node execution, in the order nodes actually ran.
  final List<AutomationNodeResult> nodes = [];

  /// Set only for a graph-build/execute-level failure (e.g. a malformed
  /// graph, or fl_nodes_core's own UI-feedback path throwing headless —
  /// distinct from a single node's [AutomationNodeOutcome.exception], which
  /// is recorded per-node in [nodes] regardless of whether it also surfaces
  /// here.
  String? error;

  bool get succeeded =>
      error == null && nodes.every((n) => n.outcome != AutomationNodeOutcome.exception);

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'succeeded': succeeded,
        'error': error,
        'nodes': [for (final n in nodes) n.toJson()],
      };
}
