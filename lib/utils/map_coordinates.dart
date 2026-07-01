import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Converts a point on the original map (expressed from 0 to 1) to the
/// viewport used by an image painted with [BoxFit.cover].
Offset normalizedMapPointInCover({
  required Offset normalizedPoint,
  required Size sourceSize,
  required Size viewportSize,
}) {
  final scale = math.max(
    viewportSize.width / sourceSize.width,
    viewportSize.height / sourceSize.height,
  );
  final renderedSize = Size(
    sourceSize.width * scale,
    sourceSize.height * scale,
  );
  final imageOffset = Offset(
    (viewportSize.width - renderedSize.width) / 2,
    (viewportSize.height - renderedSize.height) / 2,
  );

  return Offset(
    imageOffset.dx + normalizedPoint.dx * renderedSize.width,
    imageOffset.dy + normalizedPoint.dy * renderedSize.height,
  );
}
