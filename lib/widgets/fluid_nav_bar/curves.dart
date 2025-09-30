import 'dart:math' as math;
import 'package:flutter/animation.dart';

class CenteredElasticOutCurve extends Curve {
  final double period;

  const CenteredElasticOutCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    return math.pow(2.0, -10.0 * t) * math.sin(t * 2.0 * math.pi / period) +
        0.5;
  }
}

class CenteredElasticInCurve extends Curve {
  final double period;

  const CenteredElasticInCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    return -math.pow(2.0, 10.0 * (t - 1.0)) *
            math.sin((t - 1.0) * 2.0 * math.pi / period) +
        0.5;
  }
}

class LinearPointCurve extends Curve {
  final double pIn;
  final double pOut;

  const LinearPointCurve(this.pIn, this.pOut);

  @override
  double transform(double t) {
    final lowerScale = pOut / pIn;
    final upperScale = (1.0 - pOut) / (1.0 - pIn);
    final upperOffset = 1.0 - upperScale;
    return t < pIn ? t * lowerScale : t * upperScale + upperOffset;
  }
}

class ElasticOutCurve extends Curve {
  final double period;

  const ElasticOutCurve([this.period = 0.4]);

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) return t;
    return math.pow(2.0, -10.0 * t) *
            math.sin((t - period / 4.0) * (math.pi * 2.0) / period) +
        1.0;
  }
}
