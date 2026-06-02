import 'package:flutter/material.dart';
import 'package:adondeamos/core/animations/animation_constants.dart';

class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.delayMs,
  });

  final int index;
  final Widget child;
  final int? delayMs;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    final delay = widget.delayMs ?? Anim.staggerStart;
    final staggerTotal = delay + (widget.index * Anim.stagger.inMilliseconds);

    Future.delayed(Duration(milliseconds: staggerTotal), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class AnimatedListSeparated extends StatelessWidget {
  const AnimatedListSeparated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.padding,
    this.initialDelayMs,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final int? initialDelayMs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: separatorBuilder,
      itemBuilder: (context, index) {
        return AnimatedListItem(
          index: index,
          delayMs: initialDelayMs,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
