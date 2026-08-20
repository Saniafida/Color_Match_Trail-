import 'package:flutter/foundation.dart';
import '../../core/services/date_service.dart';
import '../../core/storage/storage.dart';
import '../../core/services/service_locator.dart';
import '../rewards/reward_definition.dart';
import 'event_definition.dart';
import 'event_progress.dart';
import 'event_storage.dart';
import 'event_status.dart';
import 'event_type.dart';
import 'event_validator.dart';

class EventManager extends ChangeNotifier {
  final DateService dateService;
  final EventStorage eventStorage;
  final GameStorage gameStorage;

  final Map<String, EventDefinition> _definitions = {};
  final Map<String, EventProgress> _progress = {};

  EventManager({
    required this.dateService,
    required this.eventStorage,
    required this.gameStorage,
  });

  List<EventDefinition> get allEvents => _definitions.values.toList();
  List<EventDefinition> get activeEvents => _definitions.values.where((e) => getStatus(e) == EventStatus.active).toList();
  List<EventDefinition> get upcomingEvents => _definitions.values.where((e) => getStatus(e) == EventStatus.upcoming).toList();

  EventProgress? getProgress(String eventId) => _progress[eventId];

  bool get hasActiveEvents => activeEvents.isNotEmpty;
  
  bool get hasUnclaimedRewards {
    return _progress.values.any((p) => p.completed && !p.rewardClaimed);
  }

  Future<void> initialize() async {
    // Inject some mock events for demonstration
    final now = dateService.now();
    final mockEvents = [
      EventDefinition(
        id: 'evt_weekend_blast',
        name: 'Weekend Blast',
        description: 'Clear 500 blocks to win big!',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(days: 2)),
        eventType: EventType.clearBlocks,
        target: 500,
        rewardId: 'hammer',
        rewardAmount: 3,
        priority: 10,
      ),
      EventDefinition(
        id: 'evt_upcoming_stars',
        name: 'Star Catcher',
        description: 'Score 5000 points!',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 3)),
        eventType: EventType.score,
        target: 5000,
        rewardId: 'coins',
        rewardAmount: 200,
        priority: 5,
      ),
      EventDefinition(
        id: 'evt_expired_magic',
        name: 'Magic Specials',
        description: 'Create 10 specials',
        startTime: now.subtract(const Duration(days: 5)),
        endTime: now.subtract(const Duration(days: 2)),
        eventType: EventType.createSpecial,
        target: 10,
        rewardId: 'colorClear',
        rewardAmount: 1,
        priority: 0,
      ),
    ];

    for (var ev in mockEvents) {
      if (EventValidator.isValid(ev) && ev.enabled) {
        _definitions[ev.id] = ev;
        // Load progress if any
        final prog = await eventStorage.loadProgress(ev.id);
        if (prog != null) {
          _progress[ev.id] = prog;
        } else {
          _progress[ev.id] = EventProgress(eventId: ev.id, targetValue: ev.target);
        }
      }
    }
    notifyListeners();
  }

  EventStatus getStatus(EventDefinition event) {
    final now = dateService.now();
    if (now.isBefore(event.startTime)) return EventStatus.upcoming;
    if (now.isAfter(event.endTime)) return EventStatus.expired;
    
    // Check if completed via progress
    final prog = _progress[event.id];
    if (prog != null && prog.completed && prog.rewardClaimed) {
      return EventStatus.completed;
    }
    
    return EventStatus.active;
  }

  Future<void> incrementProgress(EventType type, [int amount = 1]) async {
    bool changed = false;
    
    for (final ev in activeEvents) {
      if (ev.eventType != type) continue;
      
      var prog = _progress[ev.id];
      if (prog == null || prog.completed) continue;

      final newCurrent = prog.currentValue + amount;
      final isCompleted = newCurrent >= ev.target;
      
      // Handle maxProgress capping if required
      int finalCurrent = newCurrent;
      if (ev.maxProgress > 0 && finalCurrent > ev.maxProgress) {
        finalCurrent = ev.maxProgress;
      }

      prog = prog.copyWith(
        currentValue: finalCurrent,
        completed: isCompleted,
      );

      _progress[ev.id] = prog;
      await eventStorage.saveProgress(prog);
      changed = true;
    }

    if (changed) notifyListeners();
  }

  Future<void> updateProgressMax(EventType type, int value) async {
    bool changed = false;
    
    for (final ev in activeEvents) {
      if (ev.eventType != type) continue;
      
      var prog = _progress[ev.id];
      if (prog == null || prog.completed) continue;

      if (value > prog.currentValue) {
        final isCompleted = value >= ev.target;
        prog = prog.copyWith(
          currentValue: value,
          completed: isCompleted,
        );
        _progress[ev.id] = prog;
        await eventStorage.saveProgress(prog);
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  Future<bool> claimReward(String eventId) async {
    final ev = _definitions[eventId];
    var prog = _progress[eventId];
    
    if (ev == null || prog == null) return false;
    if (!prog.completed || prog.rewardClaimed) return false;

    final rewardType = ev.rewardId == 'coins' ? RewardType.coins : RewardType.booster;
    
    final rewardDef = RewardDefinition(
      id: 'reward_${ev.id}',
      type: rewardType,
      amount: ev.rewardAmount,
      itemId: rewardType == RewardType.booster ? ev.rewardId : null,
      source: 'event',
    );

    final rewardManager = ServiceLocator.instance.rewardManager;
    final result = await rewardManager.grantReward(rewardDef, uniqueClaimId: ev.id);

    if (result.isSuccess) {
      prog = prog.copyWith(rewardClaimed: true);
      _progress[eventId] = prog;
      await eventStorage.saveProgress(prog);
      notifyListeners();
      return true;
    }
    
    return false;
  }
}
