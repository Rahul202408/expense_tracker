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
  });

  @override
  State<ThreeDTiltCard> createState() => _ThreeDTiltCardState();
}

class _ThreeDTiltCardState extends State<ThreeDTiltCard>
    with SingleTickerProviderStateMixin {
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  double _scale = 1.0;
  Offset _glarePosition = Offset.zero;

  late AnimationController _resetController;
  late Animation<double> _animX;
  late Animation<double> _animY;
  late Animation<double> _animScale;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _resetController.addListener(() {
      setState(() {
        _rotateX = _animX.value;
        _rotateY = _animY.value;
        _scale = _animScale.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(Offset localPosition, Size size) {
    _resetController.stop();

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final percentX = (localPosition.dx - centerX) / centerX;
    final percentY = (localPosition.dy - centerY) / centerY;

    final clampedX = percentX.clamp(-1.0, 1.0);
    final clampedY = percentY.clamp(-1.0, 1.0);

    setState(() {
      _rotateX = -clampedY * widget.maxTiltAngle;
      _rotateY = clampedX * widget.maxTiltAngle;
      _scale = widget.scaleOnHover;
      _glarePosition = Offset(
        (clampedX + 1.0) / 2.0,
        (clampedY + 1.0) / 2.0,
      );
    });
  }

  void _resetTilt() {
    _animX = Tween<double>(begin: _rotateX, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _animY = Tween<double>(begin: _rotateY, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _animScale = Tween<double>(begin: _scale, end: 1.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );

    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          margin: widget.margin,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanDown: (details) => _onPanUpdate(details.localPosition, cardSize),
            onPanUpdate: (details) => _onPanUpdate(details.localPosition, cardSize),
            onPanEnd: (_) => _resetTilt(),
            onPanCancel: () => _resetTilt(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(_rotateX)
                ..rotateY(_rotateY)
                ..scale(_scale),
              transformAlignment: Alignment.center,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: effectiveRadius,
                  boxShadow: [
                    BoxShadow(
                      color: widget.shadowColor.withValues(alpha: 0.12),
                      blurRadius: widget.elevation * 1.5,
                      offset: Offset(
                        _rotateY * 25,
                        -_rotateX * 25 + (widget.elevation / 2),
                      ),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: widget.shadowColor.withValues(alpha: 0.06),
                      blurRadius: widget.elevation * 3,
                      offset: Offset(
                        _rotateY * 40,
                        -_rotateX * 40 + widget.elevation,
                      ),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: effectiveRadius,
                  child: Stack(
                    children: [
                      widget.child,
                      if (widget.enableGlare && (_rotateX != 0 || _rotateY != 0))
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
                                    Colors.white.withValues(alpha: 0.25),
                                    Colors.white.withValues(alpha: 0.05),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
