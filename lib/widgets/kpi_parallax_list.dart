import 'package:flutter/material.dart';
import '../models/kpi_indicator.dart';
import 'kpi_parallax_card.dart';

class KPIParallaxList extends StatefulWidget {
  final List<KPIIndicator> kpis;
  final Function(KPIIndicator)? onKPISelected;

  const KPIParallaxList({
    super.key,
    required this.kpis,
    this.onKPISelected,
  });

  @override
  State<KPIParallaxList> createState() => _KPIParallaxListState();
}

class _KPIParallaxListState extends State<KPIParallaxList>
    with SingleTickerProviderStateMixin {
  final double _maxRotation = 15;

  PageController? _pageController;

  double _cardWidth = 280;
  double _cardHeight = 320;
  double _normalizedOffset = 0;
  double _prevScrollX = 0;
  bool _isScrolling = false;

  late AnimationController _tweenController;
  late Tween<double> _tween;
  late Animation<double> _tweenAnim;

  @override
  void initState() {
    super.initState();

    _tweenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _tween = Tween<double>(begin: -1, end: 0);

    _tweenAnim = _tween.animate(
      CurvedAnimation(
        parent: _tweenController,
        curve: Curves.elasticOut,
      ),
    );

    _tweenAnim.addListener(() => _setOffset(_tweenAnim.value));
  }

  @override
  void dispose() {
    _tweenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kpis.isEmpty) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;

    // Responsive card sizing
    if (size.width < 600) {
      _cardWidth = size.width * 0.85;
      _cardHeight = 300;
    } else {
      _cardWidth = 280;
      _cardHeight = 320;
    }

    _pageController = PageController(
      initialPage: 0,
      viewportFraction: _cardWidth / size.width,
    );

    Widget listContent = SizedBox(
      height: _cardHeight + 50,
      child: PageView.builder(
        physics: const BouncingScrollPhysics(),
        controller: _pageController,
        itemCount: widget.kpis.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _buildKPICard(index),
        onPageChanged: (index) {
          if (widget.onKPISelected != null) {
            widget.onKPISelected!(widget.kpis[index]);
          }
        },
      ),
    );

    return Listener(
      onPointerUp: _handlePointerUp,
      child: NotificationListener(
        onNotification: _handleScrollNotifications,
        child: listContent,
      ),
    );
  }

  Widget _buildKPICard(int index) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(_normalizedOffset * _maxRotation * (3.14159 / 180)),
      child: KPIParallaxCard(
        kpi: widget.kpis[index],
        cardWidth: _cardWidth,
        cardHeight: _cardHeight,
        normalizedOffset: _normalizedOffset,
      ),
    );
  }

  bool _handleScrollNotifications(Notification notification) {
    if (notification is ScrollUpdateNotification) {
      if (_isScrolling) {
        double dx = notification.metrics.pixels - _prevScrollX;
        double scrollFactor = 0.01;
        double newOffset = (_normalizedOffset + dx * scrollFactor);
        _setOffset(newOffset.clamp(-1.0, 1.0));
      }
      _prevScrollX = notification.metrics.pixels;
    } else if (notification is ScrollStartNotification) {
      _isScrolling = true;
      _prevScrollX = notification.metrics.pixels;
      _tweenController.stop();
    }
    return true;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isScrolling) {
      _isScrolling = false;
      _startOffsetTweenToZero();
    }
  }

  void _setOffset(double value) {
    setState(() {
      _normalizedOffset = value;
    });
  }

  void _startOffsetTweenToZero() {
    _tween.begin = _normalizedOffset;
    _tweenController.reset();
    _tween.end = 0;
    _tweenController.forward();
  }
}