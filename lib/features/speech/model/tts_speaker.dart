/// TTS 说话人条目（sid + 可选名称）。
class TtsSpeaker {
  const TtsSpeaker({required this.sid, this.name = ''});

  final int sid;

  /// 模型元数据中的名称；无名时为空字符串。
  final String name;

  bool get hasName => name.isNotEmpty;
}
