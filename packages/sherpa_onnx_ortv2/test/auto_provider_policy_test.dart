import 'package:flutter_test/flutter_test.dart';
import 'package:sherpa_onnx_ortv2/sherpa_onnx.dart';

void main() {
  late AutoProviderPolicy originalPolicy;

  setUp(() {
    originalPolicy = autoProviderPolicy;
  });

  tearDown(() {
    setAutoProviderPolicy(originalPolicy);
  });

  test('explicit provider keeps requested provider', () {
    const policy = AutoProviderPolicy(
      enableOnnxruntimeProbe: false,
      enableDiagnostics: false,
    );
    setAutoProviderPolicy(policy);

    final resolved = resolveProvider('nnapi', component: 'test_explicit');
    expect(resolved.requestedProvider, 'nnapi');
    expect(resolved.resolvedProvider, 'nnapi');
    expect(resolved.fallbackReason, isNull);
  });

  test('explicit qnn provider is accepted', () {
    const policy = AutoProviderPolicy(
      enableOnnxruntimeProbe: false,
      enableDiagnostics: false,
    );
    setAutoProviderPolicy(policy);

    final resolved = resolveProvider('qnn', component: 'test_explicit_qnn');
    expect(resolved.requestedProvider, 'qnn');
    expect(resolved.resolvedProvider, 'qnn');
    expect(resolved.fallbackReason, isNull);
  });

  test('unsupported explicit provider falls back to cpu', () {
    const policy = AutoProviderPolicy(
      enableOnnxruntimeProbe: false,
      enableDiagnostics: false,
    );
    setAutoProviderPolicy(policy);

    final resolved = resolveProvider(
      'made_up_provider',
      component: 'test_unsupported',
    );
    expect(resolved.requestedProvider, 'made_up_provider');
    expect(resolved.resolvedProvider, 'cpu');
    expect(resolved.fallbackReason, 'unsupported_provider');
  });

  test('auto falls back to cpu when probe is disabled', () {
    const policy = AutoProviderPolicy(
      androidPriority: <String>['nnapi', 'qnn', 'xnnpack', 'cpu'],
      iosPriority: <String>['coreml', 'xnnpack', 'cpu'],
      defaultPriority: <String>['xnnpack', 'cpu'],
      enableOnnxruntimeProbe: false,
      enableDiagnostics: false,
    );
    setAutoProviderPolicy(policy);

    final resolved = resolveProvider('auto', component: 'test_auto');
    expect(resolved.requestedProvider, 'auto');
    expect(resolved.resolvedProvider, 'cpu');
    expect(resolved.fallbackReason, 'probe_disabled_fallback_cpu');
  });

  test('auto can optimistically select provider when configured', () {
    const policy = AutoProviderPolicy(
      defaultPriority: <String>['xnnpack', 'cpu'],
      enableOnnxruntimeProbe: false,
      allowOptimisticSelectionWithoutProbe: true,
      enableDiagnostics: false,
    );
    setAutoProviderPolicy(policy);

    final resolved = resolveProvider('auto', component: 'test_auto_optimistic');
    expect(resolved.requestedProvider, 'auto');
    expect(resolved.resolvedProvider, 'xnnpack');
    expect(resolved.fallbackReason, 'probe_disabled_assume_available');
  });
}
