import 'package:flutter/material.dart';
import '../../../../game/feedback/feedback_controller.dart';
import '../../../../game/feedback/feedback_event.dart';
import 'win_celebration.dart';
import 'goal_complete_feedback.dart';

class FeedbackLayer extends StatefulWidget {
  final FeedbackController feedbackController;

  const FeedbackLayer({super.key, required this.feedbackController});

  @override
  State<FeedbackLayer> createState() => _FeedbackLayerState();
}

class _FeedbackLayerState extends State<FeedbackLayer> {
  final List<Widget> _transientWidgets = [];
  int _widgetIdCounter = 0;

  @override
  void initState() {
    super.initState();
    widget.feedbackController.onEvent.listen(_handleFeedbackEvent);
  }

  void _handleFeedbackEvent(FeedbackEvent event) {
    if (!mounted) return;

    final id = _widgetIdCounter++;
    Widget? newWidget;

    if (event is GoalCompleteFeedbackEvent) {
      newWidget = GoalCompleteFeedback(
        key: ValueKey(id),
        onComplete: () => _removeWidget(id),
      );
    } else if (event is LevelWinFeedbackEvent) {
      newWidget = WinCelebration(
        key: ValueKey(id),
        onComplete: () => _removeWidget(id),
      );
    }

    if (newWidget != null) {
      setState(() {
        _transientWidgets.add(
          _TransientWrapper(id: id, child: newWidget!),
        );
      });
    }
  }

  void _removeWidget(int id) {
    if (!mounted) return;
    setState(() {
      _transientWidgets.removeWhere((w) => (w as _TransientWrapper).id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: _transientWidgets,
      ),
    );
  }
}

class _TransientWrapper extends StatelessWidget {
  final int id;
  final Widget child;
  const _TransientWrapper({required this.id, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
