import 'package:flutter_test/flutter_test.dart';
import 'package:sherpa_onnx_ortv2/sherpa_onnx_ortv2.dart';

void main() {
  test('pocket tts keeps voiceEmbeddingCacheCapacity in json roundtrip', () {
    const cfg = OfflineTtsPocketModelConfig(
      lmFlow: 'flow.onnx',
      lmMain: 'main.onnx',
      voiceEmbeddingCacheCapacity: 128,
    );

    final json = cfg.toJson();
    expect(json['voiceEmbeddingCacheCapacity'], 128);

    final restored = OfflineTtsPocketModelConfig.fromJson(json);
    expect(restored.voiceEmbeddingCacheCapacity, 128);
  });
}
