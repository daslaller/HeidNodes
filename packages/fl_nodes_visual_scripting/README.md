# fl_nodes_visual_scripting

A generic, **headless** trigger/condition/action automation/workflow layer
built on top of [`fl_nodes_core`](../fl_nodes_core). It supplies the
vocabulary a real automation host needs beyond what a pure visual-scripting
canvas gives you — this package has zero domain concepts of its own (no
"ticket", no "email"); that's every host's job, the same way `fl_nodes_core`
has zero opinion on what a node *is*.

## Why this exists

`fl_nodes_core` is a general node-graph rendering + execution framework. It
does the hard part — typed ports, multi-output/named-branch execution,
serialization — but using it directly for a real automation product means
every host reinventing the same three things: a way to run a saved graph
**without mounting a widget**, a friendlier node-authoring API than
`fl_nodes_core`'s raw positional `OnNodeExecute` callback, and a shared
shape for "what a run produced" that a host can persist as an audit trail.
This package is those three things, nothing more.

## `AutomationEngine`

```dart
final engine = AutomationEngine(
  appVersion: '1.0.0',
  nodePrototypes: myNodeCatalog, // trigger/condition/action FlNodePrototypes
);

// Author a graph via the plain fl_nodes_core controller API...
final trigger = engine.controller.addNode('trigger.ticket_status_changed');
final action = engine.controller.addNode('action.send_canned_message');
engine.controller.addLink(trigger.id, 'out', action.id, 'in');

// ...or load one a host previously saved:
await engine.loadGraph(savedGraphJson);

// Run it against a real record, headless — no widget tree involved.
final report = await engine.run(record: {'status': 'ready', 'ticket_id': 't_123'});
print(report.succeeded); // true/false
print(report.toJson());  // persist as a workflow_runs audit row
```

The same graph JSON (`engine.exportGraph()`) that a visual editor built on
`FlNodesWidget`/`FlNodesController` saves is what `AutomationEngine.loadGraph`
consumes — a workflow authored on screen runs unchanged here, and the editor
never has to be on screen for a production run.

## Authoring node types

```dart
FlNodePrototype ticketStatusChangedTrigger(RunContextProvider getRun) => triggerNode(
  idName: 'trigger.ticket_status_changed',
  displayName: (_) => 'Ticket status changed',
  getRun: getRun,
);

FlNodePrototype sendCannedMessageAction(RunContextProvider getRun, MyHostConnectors host) => actionNode(
  idName: 'action.send_canned_message',
  displayName: (_) => 'Send canned message',
  fields: [/* which template, which channel */],
  getRun: getRun,
  perform: (ctx) async {
    final templateId = ctx.fields['template_id'] as String;
    await host.sendCannedMessage(templateId, record: ctx.run.record);
  },
);
```

`conditionNode` is the branch primitive — one control input, N named control
outputs, and an `evaluate` callback that returns which single one fires. Only
the taken branch's downstream subgraph executes (see
`fl_nodes_core`'s `runner_branching_test.dart` for the guarantee this relies
on) — the untaken branch is never walked, not just visually skipped.

## What this package deliberately does not do

* No domain node catalog — triggers/conditions/actions for a real product
  (RepairX's ticket/booking/mail events, say) are the host's job.
* No persistence — `exportGraph`/`loadGraph` hand a host plain JSON; where
  it's stored (a database row, a file) is the host's decision.
* No visual editor of its own — that's `fl_nodes_core`'s `FlNodesWidget`, or
  a host package built on top of it (e.g. `F8F`).
