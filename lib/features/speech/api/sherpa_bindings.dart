import 'package:flute_core/log/log.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// 幂等初始化 sherpa_onnx native bindings（ASR/TTS 共用）。
void ensureSherpaBindings() {
  if (_ready) {
    return;
  }
  sherpa.initBindings();
  _ready = true;
  Log.i('sherpa_onnx bindings initialized', tag: 'Speech');
}

var _ready = false;
