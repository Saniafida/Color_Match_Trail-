import 'package:flutter/material.dart';
import '../../../core/services/service_locator.dart';
import '../../../app/routes/routes.dart';
import 'widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _manager = ServiceLocator.instance.eventManager;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _manager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final events = _manager.allEvents.toList();
    
    // Sort: Active first, Upcoming, then Completed, then Expired. Then by Priority.
    events.sort((a, b) {
      final sA = _manager.getStatus(a).index;
      final sB = _manager.getStatus(b).index;
      if (sA != sB) {
        // active (1), upcoming (0), completed (2), expired (3)
        // Let's manually weight them
        int weight(int s) {
          if (s == 1) return 0; // Active
          if (s == 0) return 1; // Upcoming
          if (s == 2) return 2; // Completed
          return 3; // Expired
        }
        return weight(sA).compareTo(weight(sB));
      }
      return b.priority.compareTo(a.priority);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      appBar: AppBar(
        title: const Text("Special Events"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: events.isEmpty 
          ? const Center(child: Text("No events right now!", style: TextStyle(color: Colors.white)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final ev = events[index];
                final prog = _manager.getProgress(ev.id);
                final status = _manager.getStatus(ev);
                
                if (prog == null) return const SizedBox.shrink();

                return EventCard(
                  event: ev,
                  progress: prog,
                  status: status,
                  onTap: () {
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.eventDetail, 
                      arguments: ev.id,
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}
