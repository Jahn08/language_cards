import 'dart:math';
import 'package:flutter/material.dart';

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({required this.child, required this.animation});

  final Widget child;

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final transform = Matrix4.identity();
          transform.setEntry(3, 2, 0.001);
          transform.rotateY(animation.value);

          return Transform(
              transform: transform, alignment: Alignment.center, child: child);
        },
        child: child);
  }
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _frontRotation;

  late Animation<double> _backRotation;

  final _isFrontNotifier = new ValueNotifier(true);

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller.reset();
  }

  @override
  void initState() {
    super.initState();

    _controller = new AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);

    _frontRotation = new TweenSequence<double>([
      new TweenSequenceItem(
          tween: new Tween<double>(begin: 0, end: pi / 2)
              .chain(new CurveTween(curve: Curves.easeIn)),
          weight: 50),
      new TweenSequenceItem(
          tween: new ConstantTween(pi / 2)
              .chain(new CurveTween(curve: Curves.easeOut)),
          weight: 50)
    ]).animate(_controller);

    _backRotation = new TweenSequence<double>([
      new TweenSequenceItem(
          tween: new ConstantTween(pi / 2)
              .chain(new CurveTween(curve: Curves.easeIn)),
          weight: 50),
      new TweenSequenceItem(
          tween: new Tween<double>(begin: -pi / 2, end: 0)
              .chain(new CurveTween(curve: Curves.easeOut)),
          weight: 50)
    ]).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_isFrontNotifier.value)
            _controller.forward();
          else
            _controller.reverse();

          _isFrontNotifier.value = !_isFrontNotifier.value;
        },
        child: new ValueListenableBuilder(
            valueListenable: _isFrontNotifier,
            builder: (_, bool isFront, __) =>
                Stack(fit: StackFit.passthrough, children: <Widget>[
                  new _FlipCardSide(
                      animation: _frontRotation,
                      child: widget.front,
                      isHittable: isFront),
                  new _FlipCardSide(
                      animation: _backRotation,
                      child: widget.back,
                      isHittable: !isFront)
                ])));
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }
}

class _FlipCardSide extends StatelessWidget {
  final bool isHittable;

  final Widget child;

  final Animation<double> animation;

  const _FlipCardSide(
      {required this.child, required this.animation, required this.isHittable});

  @override
  Widget build(BuildContext context) => new IgnorePointer(
      ignoring: isHittable,
      child: new _AnimatedCard(child: child, animation: animation));
}

class FlipCard extends StatefulWidget {
  final Widget front;

  final Widget back;

  const FlipCard({required this.front, required this.back});

  @override
  _FlipCardState createState() => new _FlipCardState();
}
