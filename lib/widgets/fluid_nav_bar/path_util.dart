import 'dart:ui' as ui;

/// Extracts a partial path from a given path based on start and end percentages
ui.Path extractPartialPath(ui.Path originalPath, double startPercent, double endPercent) {
  final pathMetrics = originalPath.computeMetrics();
  final extractedPath = ui.Path();

  for (final pathMetric in pathMetrics) {
    final extractedLength = pathMetric.length * (endPercent - startPercent);
    final extractedStart = pathMetric.length * startPercent;

    final extracted = pathMetric.extractPath(extractedStart, extractedStart + extractedLength);
    extractedPath.addPath(extracted, ui.Offset.zero);
  }

  return extractedPath;
}