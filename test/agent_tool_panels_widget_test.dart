import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/mcp_server/mcp_server.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/main/widget/main_chat_input.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('Tool action opens the tool panel as a bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: const ProviderScope(
          child: MaterialApp(home: _ToolPanelSheetTestHost()),
        ),
      ),
    );

    await tester.tap(find.byTooltip(t.main.toolPanel.open));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AgentToolPanel), findsOneWidget);
    expect(find.text(t.main.toolPanel.title), findsOneWidget);
  });

  testWidgets('MCP action opens the MCP panel as a bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            mcpServersProvider.overrideWith((ref) => Stream.value(const [])),
            mcpDiscoveredToolsProvider.overrideWith(
              (ref) => const [
                McpRemoteTool(
                  qualifiedName: 'mcp_test_echo',
                  serverId: 'server_test',
                  serverName: 'Test',
                  originalName: 'echo',
                  displayName: 'Echo',
                  description: 'Echo input',
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: _McpPanelSheetTestHost()),
        ),
      ),
    );

    await tester.tap(find.byTooltip(t.main.mcpPanel.open));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(McpToolPanel), findsOneWidget);
    expect(find.text(t.main.mcpPanel.title), findsOneWidget);
  });

  testWidgets('Agent tool panel toggles available tools', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: AgentToolPanel())),
        ),
      ),
    );

    final locationSwitch = find.byKey(
      const ValueKey('agent_tool_switch_get_current_location'),
    );
    expect(locationSwitch, findsOneWidget);
    expect(
      container.read(agentToolsProvider).map((tool) => tool.name),
      contains(AgentToolIds.currentLocation),
    );

    await tester.tap(locationSwitch);
    await tester.pump();

    expect(
      container.read(agentToolsProvider).map((tool) => tool.name),
      isNot(contains(AgentToolIds.currentLocation)),
    );
  });
}

class _ToolPanelSheetTestHost extends StatelessWidget {
  const _ToolPanelSheetTestHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainChatInput(
        enabled: true,
        isSending: false,
        draftMessage: '',
        onDraftChanged: (_) {},
        onSubmitted: (_) {},
        onStopPressed: () {},
        onToolsPressed: () {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => const AgentToolPanel(),
          );
        },
        onMcpPressed: () {},
        modelLabel: 'GPT-4o mini',
        onModelPressed: () {},
      ),
    );
  }
}

class _McpPanelSheetTestHost extends StatelessWidget {
  const _McpPanelSheetTestHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainChatInput(
        enabled: true,
        isSending: false,
        draftMessage: '',
        onDraftChanged: (_) {},
        onSubmitted: (_) {},
        onStopPressed: () {},
        onToolsPressed: () {},
        onMcpPressed: () {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => const McpToolPanel(),
          );
        },
        modelLabel: 'GPT-4o mini',
        onModelPressed: () {},
      ),
    );
  }
}
