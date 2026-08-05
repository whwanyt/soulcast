import 'dart:convert';
import 'package:soulcast/features/agent/llm.dart';

import 'package:flute_core/log/log.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/i18n/strings.g.dart';

import 'package:soulcast/features/agent_tools/agent_tools.dart';

import '../../model/chat_completion_result.dart';
import '../../model/chat_create_image_mention.dart';
import '../chat_llm_message_mapper.dart';
import '../chat_memory_prompt_builder.dart';

part 'types.dart';
part 'helpers.dart';
part 'image_result_mapper.dart';
part 'request_builder.dart';
part 'assistant_turn_mapper.dart';
part 'request_message_builder.dart';
part 'tool_loop.dart';
part 'image_mode.dart';
part 'completion.dart';
part 'completion_stream.dart';

/// 聊天请求编排器，统一处理上下文、工具循环及流式/非流式完成。
class ChatService
    with
        _ChatImageResultMapper,
        _ChatRequestBuilder,
        _ChatServiceHelpers,
        _ChatAssistantTurnMapper,
        _ChatToolLoop,
        _ChatImageMode,
        _ChatCompletion,
        _ChatCompletionStream {
  const ChatService();
}
