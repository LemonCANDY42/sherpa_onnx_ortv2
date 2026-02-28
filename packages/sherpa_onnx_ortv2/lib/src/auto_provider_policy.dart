// Copyright (c) 2026 sherpa_onnx_ortv2 contributors
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:onnxruntime_v2/onnxruntime_v2.dart' as ort;

class AutoProviderPolicy {
  const AutoProviderPolicy({
    this.androidPriority = const <String>['nnapi', 'qnn', 'xnnpack', 'cpu'],
    this.iosPriority = const <String>['coreml', 'xnnpack', 'cpu'],
    this.defaultPriority = const <String>['xnnpack', 'cpu'],
    this.enableOnnxruntimeProbe = true,
    this.allowOptimisticSelectionWithoutProbe = false,
    this.enableDiagnostics = true,
  });

  final List<String> androidPriority;
  final List<String> iosPriority;
  final List<String> defaultPriority;
  final bool enableOnnxruntimeProbe;
  final bool allowOptimisticSelectionWithoutProbe;
  final bool enableDiagnostics;
}

class ProviderResolution {
  const ProviderResolution({
    required this.requestedProvider,
    required this.resolvedProvider,
    this.fallbackReason,
  });

  final String requestedProvider;
  final String resolvedProvider;
  final String? fallbackReason;
}

AutoProviderPolicy _autoProviderPolicy = const AutoProviderPolicy();

AutoProviderPolicy get autoProviderPolicy => _autoProviderPolicy;

void setAutoProviderPolicy(AutoProviderPolicy policy) {
  _autoProviderPolicy = policy;
}

const Map<String, String> _providerToOrtEp = <String, String>{
  'cpu': 'cpuexecutionprovider',
  'cuda': 'cudaexecutionprovider',
  'coreml': 'coremlexecutionprovider',
  'xnnpack': 'xnnpackexecutionprovider',
  'nnapi': 'nnapiexecutionprovider',
  'qnn': 'qnnexecutionprovider',
  'trt': 'tensorrtexecutionprovider',
  'directml': 'dmlexecutionprovider',
};

const Set<String> _sherpaSupportedProviders = <String>{
  'cpu',
  'cuda',
  'coreml',
  'xnnpack',
  'nnapi',
  'qnn',
  'trt',
  'directml',
  'spacemit',
};

ProviderResolution resolveProvider(
  String requestedProvider, {
  String component = 'unknown',
}) {
  final normalizedRequest = requestedProvider.trim().toLowerCase();
  if (normalizedRequest.isEmpty || normalizedRequest == 'auto') {
    return _resolveAutoProvider(component: component);
  }

  if (_sherpaSupportedProviders.contains(normalizedRequest)) {
    _emitDiagnostics(
      ProviderResolution(
        requestedProvider: normalizedRequest,
        resolvedProvider: normalizedRequest,
      ),
      component: component,
    );
    return ProviderResolution(
      requestedProvider: normalizedRequest,
      resolvedProvider: normalizedRequest,
    );
  }

  final result = ProviderResolution(
    requestedProvider: normalizedRequest,
    resolvedProvider: 'cpu',
    fallbackReason: 'unsupported_provider',
  );
  _emitDiagnostics(result, component: component);
  return result;
}

ProviderResolution _resolveAutoProvider({required String component}) {
  final priorities = _priorityForCurrentPlatform();
  Set<String>? availableProviders;
  String? probeError;

  if (_autoProviderPolicy.enableOnnxruntimeProbe) {
    try {
      ort.OrtEnv.instance.init();
      availableProviders = ort.OrtEnv.instance
          .availableProviders()
          .map((provider) => provider.toString().toLowerCase())
          .toSet();
    } catch (e) {
      probeError = e.toString();
    }
  }

  for (final candidate in priorities) {
    final normalized = candidate.trim().toLowerCase();
    if (!_sherpaSupportedProviders.contains(normalized)) {
      continue;
    }

    if (normalized == 'cpu') {
      final result = ProviderResolution(
        requestedProvider: 'auto',
        resolvedProvider: 'cpu',
        fallbackReason: probeError != null
            ? 'probe_unavailable_fallback_cpu'
            : _autoProviderPolicy.enableOnnxruntimeProbe
                ? 'fallback_cpu'
                : 'probe_disabled_fallback_cpu',
      );
      _emitDiagnostics(result, component: component, probeError: probeError);
      return result;
    }

    if (availableProviders == null) {
      if (_autoProviderPolicy.allowOptimisticSelectionWithoutProbe) {
        final result = ProviderResolution(
          requestedProvider: 'auto',
          resolvedProvider: normalized,
          fallbackReason: probeError == null
              ? 'probe_disabled_assume_available'
              : 'probe_unavailable_assume_available',
        );
        _emitDiagnostics(result, component: component, probeError: probeError);
        return result;
      }
      continue;
    }

    final expectedEp = _providerToOrtEp[normalized];
    if (expectedEp == null) {
      continue;
    }

    final matched = availableProviders.any((ep) => ep.contains(expectedEp));
    if (matched) {
      final result = ProviderResolution(
        requestedProvider: 'auto',
        resolvedProvider: normalized,
        fallbackReason: 'auto_select_available',
      );
      _emitDiagnostics(result, component: component, probeError: probeError);
      return result;
    }
  }

  final result = ProviderResolution(
    requestedProvider: 'auto',
    resolvedProvider: 'cpu',
    fallbackReason: probeError != null
        ? 'probe_unavailable_fallback_cpu'
        : _autoProviderPolicy.enableOnnxruntimeProbe
            ? 'no_accelerated_provider_available'
            : 'probe_disabled_fallback_cpu',
  );
  _emitDiagnostics(result, component: component, probeError: probeError);
  return result;
}

List<String> _priorityForCurrentPlatform() {
  if (Platform.isAndroid) {
    return _autoProviderPolicy.androidPriority;
  }
  if (Platform.isIOS) {
    return _autoProviderPolicy.iosPriority;
  }
  return _autoProviderPolicy.defaultPriority;
}

void _emitDiagnostics(
  ProviderResolution resolution, {
  required String component,
  String? probeError,
}) {
  if (!_autoProviderPolicy.enableDiagnostics) {
    return;
  }

  final payload = <String, String?>{
    'component': component,
    'requested_provider': resolution.requestedProvider,
    'resolved_provider': resolution.resolvedProvider,
    'fallback_reason': resolution.fallbackReason,
    'probe_error': probeError,
  };
  developer.log(
    jsonEncode(payload),
    name: 'sherpa_onnx_ortv2.provider',
  );
}
