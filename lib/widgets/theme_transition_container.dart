import 'package:flutter/material.dart';

class ThemeTransitionContainer extends StatefulWidget {
  final Widget child;
  final bool darkMode;

  const ThemeTransitionContainer({
    super.key,
    required this.child,
    required this.darkMode,
  });

  @override
  State<ThemeTransitionContainer> createState() => _ThemeTransitionContainerState();
}

class _ThemeTransitionContainerState extends State<ThemeTransitionContainer>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  Widget? _childForeground;
  Widget? _childBackground;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.addListener(() {
      setState(() {});
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _childBackground = _childForeground;
          _childForeground = null;
        });
        _controller.reset();
      }
    });

    _childBackground = widget.child;
  }

  @override
  void didUpdateWidget(ThemeTransitionContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.darkMode != oldWidget.darkMode) {
      setState(() {
        _childForeground = widget.child;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        List<Widget> children = [
          if (_childBackground != null)
            SizedBox(
              width: size.width,
              height: size.height,
              child: _childBackground,
            ),
        ];

        if (_childForeground != null) {
          children.add(
            ClipPath(
              clipper: _CircularRevealClipper(
                center: _getThemeButtonPosition(size), // Dynamic position based on theme button
                radius: _scaleAnimation.value * size.width * 1.5,
              ),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: _childForeground,
                ),
              ),
            ),
          );
        }

        return Stack(children: children);
      },
    );
  }

  Offset _getThemeButtonPosition(Size size) {
    // Try to position near where theme buttons typically are in our app
    // This is a rough approximation since we don't have exact position
    return Offset(size.width - 60, 60);
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircularRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper != this;
  }
}