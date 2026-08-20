import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../game/events/event_definition.dart';
import '../../../../game/events/event_progress.dart';
import '../../../../game/events/event_type.dart';
import '../../../../game/events/event_status.dart';
import '../../../../game/boosters/booster_definition.dart';
import '../../../../models/booster.dart';
import '../../../../core/services/service_locator.dart';

class EventCard extends StatefulWidget {
  final EventDefinition event;
  final EventProgress progress;
  final EventStatus status;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.progress,
    required this.status,
    required this.onTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  Timer? _timer;
  String _timeRemaining = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = ServiceLocator.instance.dateService.now();
    DateTime targetTime;
    String prefix = "";
    
    if (widget.status == EventStatus.upcoming) {
      targetTime = widget.event.startTime;
      prefix = "Starts in: ";
    } else if (widget.status == EventStatus.active) {
      targetTime = widget.event.endTime;
      prefix = "Ends in: ";
    } else {
      if (mounted) setState(() => _timeRemaining = "Expired");
      return;
    }

    final diff = targetTime.difference(now);
    if (diff.isNegative) {
      if (mounted) setState(() => _timeRemaining = "Status updating...");
      return;
    }

    final d = diff.inDays;
    final h = diff.inHours.remainder(24);
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);

    String timeStr = prefix;
    if (d > 0) timeStr += "${d}d ";
    if (d > 0 || h > 0) timeStr += "${h}h ";
    timeStr += "${m}m ${s}s";

    if (mounted) {
      setState(() {
        _timeRemaining = timeStr;
      });
    }
  }

  String _getObjectiveText() {
    switch (widget.event.eventType) {
      case EventType.score: return "Score ${widget.event.target} points";
      case EventType.clearBlocks: return "Clear ${widget.event.target} blocks";
      case EventType.createSpecial: return "Create ${widget.event.target} Special Blocks";
      case EventType.cascade: return "Trigger ${widget.event.target} Cascades";
      case EventType.combo: return "Reach a Combo of ${widget.event.target}";
      case EventType.levelCampaign: return "Complete Event Levels";
    }
  }

  Widget _buildRewardIcon() {
    if (widget.event.rewardId == 'coins') {
      return const Icon(Icons.monetization_on, color: Colors.amber, size: 24);
    } else {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == widget.event.rewardId,
        orElse: () => BoosterType.hammer,
      );
      final def = BoosterDefinition.registry[type];
      return Icon(def?.icon ?? Icons.star, color: Colors.amber, size: 24);
    }
  }

  String _getRewardName() {
    if (widget.event.rewardId == 'coins') {
      return "${widget.event.rewardAmount} Coins";
    } else {
      final type = BoosterType.values.firstWhere(
        (e) => e.name == widget.event.rewardId,
        orElse: () => BoosterType.hammer,
      );
      final def = BoosterDefinition.registry[type];
      return "+${widget.event.rewardAmount} ${def?.name ?? 'Booster'}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = (widget.progress.currentValue / widget.event.target).clamp(0.0, 1.0);
    final bool isExpiredOrCompleted = widget.status == EventStatus.expired || widget.status == EventStatus.completed;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpiredOrCompleted ? Colors.grey.shade900 : const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.status == EventStatus.active ? Colors.blueAccent : Colors.white24,
            width: 2,
          ),
          boxShadow: [
            if (widget.status == EventStatus.active)
              const BoxShadow(color: Colors.blueAccent, blurRadius: 8, spreadRadius: -2)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.event.name.toUpperCase(),
                    style: TextStyle(
                      color: isExpiredOrCompleted ? Colors.grey : Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.status == EventStatus.completed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (widget.status == EventStatus.expired)
                  const Icon(Icons.timer_off, color: Colors.red, size: 24)
                else
                  Text(
                    _timeRemaining,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getObjectiveText(),
              style: TextStyle(
                color: isExpiredOrCompleted ? Colors.white54 : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.progress.completed ? Colors.green : (isExpiredOrCompleted ? Colors.grey : Colors.blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${widget.progress.currentValue} / ${widget.event.target}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRewardIcon(),
                const SizedBox(width: 8),
                Text(
                  "Reward: ${_getRewardName()}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            )
          ],
        ),
      ),
    );
  }
}
