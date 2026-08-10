/// A generic, headless trigger/condition/action workflow layer built on top
/// of `fl_nodes_core`.
///
/// This package supplies the *vocabulary* — [AutomationEngine] to run a
/// graph without a widget tree, `automationNode`/`triggerNode`/
/// `conditionNode`/`actionNode` to define node types against a friendlier
/// callback shape than fl_nodes_core's raw [OnNodeExecute], and
/// [AutomationRunContext]/[AutomationRunReport] for the record-in/audit-out
/// shape a real automation host needs. It has zero domain vocabulary of its
/// own (no "ticket", no "email") — that's every host's own job, the same
/// way `fl_nodes_core` has zero opinion on what a node *is*.
///
/// fl_nodes_core's `FlNodesWidget`/`FlNodesController` remain the way to put
/// a graph built from these node types on screen for editing; this package
/// only adds the pieces needed to run one for real, unattended.
library;

export 'package:fl_nodes_core/fl_nodes_core.dart';

export 'src/automation_engine.dart';
export 'src/execution_context.dart';
export 'src/node_builders.dart';
export 'src/run_context.dart';
export 'src/run_report.dart';
