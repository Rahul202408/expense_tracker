import 'package:flutter/material.dart';

class ThreeDTiltCard extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle;
  final double scaleOnHover;
  final BorderRadius? borderRadius;
  final bool enableGlare;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color shadowColor;
  final double elevation;
  final bool enableTilt;

  const ThreeDTiltCard({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.12,
    this.scaleOnHover = 1.02,
    this.borderRadius,
    this.enableGlare = true,
    this.onTap,
    this.margin,
    this.padding,
    this.shadowColor = Colors.black,
    this.elevation = 12.0,
    this.enableTilt = true,
  });

  @override
  State<ThreeDTiltCard> createState() => _ThreeDTiltCardState();
}

class _ThreeDTiltCardState extends State<ThreeDTiltCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _resetController;
  late Animation<double> _animX;
  late Animation<double> _animY;
  late Animation<double> _animScale;

  double _rotateX = 0.0;
  double _rotateY = 0.0;
  double _scale = 1.0;
  Offset _glarePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.enableTilt) {
      _initController();
    }
  }

  void _initController() {
    _animX = const AlwaysStoppedAnimation(0.0);
    _animY = const AlwaysStoppedAnimation(0.0);
    _animScale = const AlwaysStoppedAnimation(1.0);

    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _resetController!.addListener(() {
      setState(() {
        _rotateX = _animX.value;
        _rotateY = _animY.value;
        _scale = _animScale.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant ThreeDTiltCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableTilt && _resetController == null) {
      _initController();
    } else if (!widget.enableTilt && _resetController != null) {
      _resetController!.dispose();
      _resetController = null;
    }
  }

  @override
  void dispose() {
    _resetController?.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset localPosition, Size size) {
    if (!widget.enableTilt || size.width <= 0 || size.height <= 0) return;
    _resetController?.stop();

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final percentX = ((localPosition.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final percentY = ((localPosition.dy - centerY) / centerY).clamp(-1.0, 1.0);

    setState(() {
      _rotateX = -percentY * widget.maxTiltAngle;
      _rotateY = percentX * widget.maxTiltAngle;
      _scale = widget.scaleOnHover;
      _glarePosition = Offset(
        (percentX + 1.0) / 2.0,
        (percentY + 1.0) / 2.0,
      );
    });
  }

  void _resetTilt() {
    if (!widget.enableTilt || _resetController == null) return;
    _animX = Tween<double>(begin: _rotateX, end: 0.0).animate(
      CurvedAnimation(parent: _resetController!, curve: Curves.easeOutCubic),
    );
    _animY = Tween<double>(begin: _rotateY, end: 0.0).animate(
      CurvedAnimation(parent: _resetController!, curve: Curves.easeOutCubic),
    );
    _animScale = Tween<double>(begin: _scale, end: 1.0).animate(
      CurvedAnimation(parent: _resetController!, curve: Curves.easeOutCubic),
    );

    _resetController!.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20);

    Widget cardBody = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: widget.elevation > 0
            ? [
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: 0.12),
                  blurRadius: widget.elevation * 1.5,
                  offset: Offset(
                    _rotateY * 20,
                    -_rotateX * 20 + (widget.elevation / 2),
                  ),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: 0.06),
                  blurRadius: widget.elevation * 3,
                  offset: Offset(
                    _rotateY * 35,
                    -_rotateX * 35 + widget.elevation,
                  ),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Stack(
          children: [
            widget.child,
            if (widget.enableTilt &&
                widget.enableGlare &&
                (_rotateX != 0 || _rotateY != 0))
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: effectiveRadius,
                      gradient: LinearGradient(
                        begin: Alignment(
                          _glarePosition.dx * 2 - 1,
                          _glarePosition.dy * 2 - 1,
                        ),
                        end: Alignment(
                          -(_glarePosition.dx * 2 - 1),
                          -(_glarePosition.dy * 2 - 1),
                        ),
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // If tilt is disabled (e.g. inside scroll lists or forms), render purely static & fast
    if (!widget.enableTilt) {
      if (widget.onTap != null) {
        cardBody = GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: cardBody,
        );
      }
      return Container(
        margin: widget.margin,
        child: RepaintBoundary(child: cardBody),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final double cardHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0;
        final cardSize = Size(cardWidth, cardHeight);

        return Container(
          margin: widget.margin,
          child: Listener(
            onPointerDown: (event) => _onPointerMove(event.localPosition, cardSize),
            onPointerMove: (event) => _onPointerMove(event.localPosition, cardSize),
            onPointerUp: (_) => _resetTilt(),
            onPointerCancel: (_) => _resetTilt(),
            child: MouseRegion(
              onHover: (event) => _onPointerMove(event.localPosition, cardSize),
              onExit: (_) => _resetTilt(),
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(_rotateX)
                    ..rotateY(_rotateY)
                    ..scale(_scale),
                  child: RepaintBoundary(child: cardBody),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
