## 0.1.0

* Real content, replacing the empty `flutter create` stub this package
  shipped as before.
* `AutomationEngine` — a headless wrapper around `FlNodesController` that
  runs a saved graph (`loadGraph`/`exportGraph`) against an input record
  with no widget tree required, for server-less trigger dispatch.
* `automationNode`/`triggerNode`/`conditionNode`/`actionNode` — node-authoring
  helpers over a friendlier `AutomationExecutionContext` callback shape than
  fl_nodes_core's raw positional `OnNodeExecute`.
* `AutomationRunContext` (the record + variables a run carries) and
  `AutomationRunReport`/`AutomationNodeResult` (a per-node audit trail a host
  persists, e.g. one row per workflow run).
* Built to be used by `F8F` (`daslaller/F8F`) as the engine behind its
  visual editor, and by any other host that wants a generic
  trigger/condition/action automation layer on `fl_nodes_core`.

## 0.0.1

* Empty placeholder package (upstream `flutter create` scaffold), never
  published with real content.
