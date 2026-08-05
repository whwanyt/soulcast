import 'package:flutter_test/flutter_test.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:soulcast/features/agent/api/openai_llm_mapper.dart';
import 'package:soulcast/features/agent/model/llm_chat_request.dart';
import 'package:soulcast/features/agent/model/llm_message.dart';
import 'package:soulcast/features/agent/model/llm_tool.dart';

void main() {
  test('maps function toolChoice to OpenAI ToolChoice.function', () {
    final request = toOpenAiChatCompletionRequest(
      LlmChatRequest(
        model: 'gpt-test',
        messages: [LlmMessage.user('draw a cat')],
        tools: [
          LlmToolDefinition(
            name: 'generate_image',
            description: 'Generate an image',
            parameters: {
              'type': 'object',
              'properties': {
                'prompt': {'type': 'string'},
              },
              'required': ['prompt'],
            },
          ),
        ],
        toolChoice: LlmToolChoice.function('generate_image'),
      ),
    );

    final choice = request.toolChoice;
    expect(choice, isA<ToolChoiceFunction>());
    expect((choice as ToolChoiceFunction).name, 'generate_image');
  });

  test('maps auto toolChoice when tools exist', () {
    final request = toOpenAiChatCompletionRequest(
      LlmChatRequest(
        model: 'gpt-test',
        messages: [LlmMessage.user('hi')],
        tools: [
          LlmToolDefinition(
            name: 'get_current_time',
            description: 'time',
            parameters: {'type': 'object', 'properties': <String, dynamic>{}},
          ),
        ],
        toolChoice: LlmToolChoice.auto,
      ),
    );

    expect(request.toolChoice, isA<ToolChoiceAuto>());
  });
}
