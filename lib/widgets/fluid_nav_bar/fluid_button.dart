import 'package:flutter/material.dart' hide ElasticOutCurve;
import 'fluid_icon.dart';
import 'curves.dart';

typedef void FluidNavBarButtonPressedCallback();

class FluidNavBarButton extends StatefulWidget {
  static const nominalExtent = const Size(64, 64);

  final FluidFillIconData _iconData;
  final bool _selected;
  final FluidNavBarButtonPressedCallback _onPressed;

  FluidNavBarButton(
    FluidFillIconData iconData,
    bool selected,
    FluidNavBarButtonPressedCallback onPressed,
  ) : _iconData = iconData,
      _selected = selected,
      _onPressed = onPressed;

  @override
  State createState() {
    return _FluidNavBarButtonState(_iconData, _selected, _onPressed);
  }
}

class _FluidNavBarButtonState extends State<FluidNavBarButton>
    with SingleTickerProviderStateMixin {
  static const double _activeOffset = 16;
  static const double _defaultOffset = 0;
  static const double _radius = 25;

  FluidFillIconData _iconData;
  bool _selected;
  FluidNavBarButtonPressedCallback _onPressed;

  late AnimationController _animationController;
  late Animation<double> _animation;

  _FluidNavBarButtonState(
    FluidFillIconData iconData,
    bool selected,
    FluidNavBarButtonPressedCallback onPressed,
  ) : _iconData = iconData,
      _selected = selected,
      _onPressed = onPressed;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1666),
      reverseDuration: const Duration(milliseconds: 833),
      vsync: this,
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
          ..addListener(() {
            setState(() {});
          });
    _startAnimation();

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    const ne = FluidNavBarButton.nominalExtent;
    final offsetCurve = _selected ? ElasticOutCurve(0.38) : Curves.easeInQuint;
    final scaleCurve = _selected
        ? CenteredElasticOutCurve(0.6)
        : CenteredElasticInCurve(0.6);

    final progress = LinearPointCurve(0.28, 0.0).transform(_animation.value);

    final offset = Tween<double>(
      begin: _defaultOffset,
      end: _activeOffset,
    ).transform(offsetCurve.transform(progress));
    final scaleCurveScale = 0.50;
    final scaleY =
        0.5 +
        scaleCurve.transform(progress) * scaleCurveScale +
        (0.5 - scaleCurveScale / 2);

    return GestureDetector(
      onTap: _onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints.tight(ne),
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.all(ne.width / 2 - _radius),
          constraints: BoxConstraints.tight(Size.square(_radius * 2)),
          decoration: ShapeDecoration(
            color: Color(0xFF1976D2),
            shape: CircleBorder(),
          ),
          transform: Matrix4.translationValues(0, -offset, 0),
          child: FluidFillIcon(
            _iconData,
            LinearPointCurve(0.25, 1.0).transform(_animation.value),
            scaleY,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(oldWidget) {
    setState(() {
      _selected = widget._selected;
    });
    _startAnimation();
    super.didUpdateWidget(oldWidget);
  }

  void _startAnimation() {
    if (_selected) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
