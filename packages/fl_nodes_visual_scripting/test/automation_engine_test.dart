import 'package:fl_nodes_visual_scripting/fl_nodes_visual_scripting.dart';
import 'package:flutter_test/flutter_test.dart';

FlFieldPrototype _labelField(String defaultValue) =>
    textField(idName: 'label', displayName: (_) => 'Label', defaultValue: defaultValue);

void main() {
  // See fl_nodes_core's runner_branching_test.dart for why this is needed
  // even though AutomationEngine never builds a widget.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomationEngine', () {
    late List<String> sideEffects;
    late AutomationEngine engine;

    List<FlNodePrototype> buildCatalog(AutomationEngine Function() self) => [
          triggerNode(
            idName: 'trigger.manual',
            displayName: (_) => 'Manual trigger',
            getRun: () => self().currentRun!,
          ),
          conditionNode(
            idName: 'condition.record_flag',
            displayName: (_) => 'Record flag?',
            outPorts: const ['true', 'false'],
            getRun: () => self().currentRun!,
            evaluate: (ctx) async => (ctx.run.record['pass'] == true) ? 'true' : 'false',
          ),
          actionNode(
            idName: 'action.record',
            displayName: (_) => 'Record side effect',
            fields: [_labelField('unlabeled')],
            getRun: () => self().currentRun!,
            perform: (ctx) async => sideEffects.add(ctx.fields['label'] as String),
          ),
        ];

    setUp(() {
      sideEffects = [];
      engine = AutomationEngine(appVersion: '1.0.0', nodePrototypes: buildCatalog(() => engine));
    });

    tearDown(() => engine.dispose());

    Map<String, dynamic> buildBranchingGraph(AutomationEngine onEngine) {
      final trigger = onEngine.controller.addNode('trigger.manual');
      final condition = onEngine.controller.addNode('condition.record_flag');
      final onTrue = onEngine.controller.addNode('action.record');
      final onFalse = onEngine.controller.addNode('action.record');
      onTrue.fields['label']!.data = 'passed';
      onFalse.fields['label']!.data = 'failed';

      onEngine.controller.addLink(trigger.id, 'out', condition.id, 'in');
      onEngine.controller.addLink(condition.id, 'true', onTrue.id, 'in');
      onEngine.controller.addLink(condition.id, 'false', onFalse.id, 'in');

      return onEngine.exportGraph();
    }

    test('runs the taken branch only and reports every node outcome', () async {
      buildBranchingGraph(engine);

      final report = await engine.run(record: const {'pass': true});

      expect(sideEffects, ['passed']);
      expect(report.succeeded, isTrue);
      expect(
        report.nodes.map((n) => n.nodeType),
        containsAll(['trigger.manual', 'condition.record_flag', 'action.record']),
      );
      // Only one action.record node actually ran — the untaken branch's
      // action node never fires, so it never contributes a result.
      expect(report.nodes.where((n) => n.nodeType == 'action.record').length, 1);
    });

    test('flips branch when the record disagrees', () async {
      buildBranchingGraph(engine);

      final report = await engine.run(record: const {'pass': false});

      expect(sideEffects, ['failed']);
      expect(report.succeeded, isTrue);
    });

    test('currentRun is null outside of run()', () async {
      expect(engine.currentRun, isNull);
      buildBranchingGraph(engine);
      await engine.run(record: const {'pass': true});
      expect(engine.currentRun, isNull);
    });

    test('a saved graph JSON round-trips through a fresh engine unchanged', () async {
      final graphJson = buildBranchingGraph(engine);

      final rehydratedEffects = <String>[];
      late final AutomationEngine rehydrated;
      rehydrated = AutomationEngine(
        appVersion: '1.0.0',
        nodePrototypes: [
          triggerNode(
            idName: 'trigger.manual',
            displayName: (_) => 'Manual trigger',
            getRun: () => rehydrated.currentRun!,
          ),
          conditionNode(
            idName: 'condition.record_flag',
            displayName: (_) => 'Record flag?',
            outPorts: const ['true', 'false'],
            getRun: () => rehydrated.currentRun!,
            evaluate: (ctx) async => (ctx.run.record['pass'] == true) ? 'true' : 'false',
          ),
          actionNode(
            idName: 'action.record',
            displayName: (_) => 'Record side effect',
            fields: [_labelField('unlabeled')],
            getRun: () => rehydrated.currentRun!,
            perform: (ctx) async => rehydratedEffects.add(ctx.fields['label'] as String),
          ),
        ],
      );
      addTearDown(rehydrated.dispose);

      await rehydrated.loadGraph(graphJson);
      final report = await rehydrated.run(record: const {'pass': true});

      expect(rehydratedEffects, ['passed']);
      expect(report.succeeded, isTrue);
    });

    test('an action node throwing is recorded, not silently swallowed', () async {
      late final AutomationEngine failing;
      failing = AutomationEngine(
        appVersion: '1.0.0',
        nodePrototypes: [
          triggerNode(
            idName: 'trigger.manual',
            displayName: (_) => 'Manual trigger',
            getRun: () => failing.currentRun!,
          ),
          actionNode(
            idName: 'action.boom',
            displayName: (_) => 'Boom',
            getRun: () => failing.currentRun!,
            perform: (ctx) async => throw StateError('boom'),
          ),
        ],
      );
      addTearDown(failing.dispose);

      final trigger = failing.controller.addNode('trigger.manual');
      final boom = failing.controller.addNode('action.boom');
      failing.controller.addLink(trigger.id, 'out', boom.id, 'in');

      final report = await failing.run();

      expect(report.succeeded, isFalse);
      expect(report.nodes.any((n) => n.outcome == AutomationNodeOutcome.exception), isTrue);
    });
  });
}
