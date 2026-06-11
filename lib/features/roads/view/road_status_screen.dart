import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/road_controller.dart';
import '../model/road_model.dart';

class RoadStatusScreen extends StatefulWidget {
  const RoadStatusScreen({super.key});

  @override
  State<RoadStatusScreen> createState() => _RoadStatusScreenState();
}

class _RoadStatusScreenState extends State<RoadStatusScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------- ROAD CARD ----------------
  Widget _roadCard(RoadModel road, RoadController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(road.name),
        subtitle: Text("${road.origin} → ${road.destination}"),
        trailing: Text(
          road.status.toUpperCase(),
          style: TextStyle(
            color: road.status == "open"
                ? Colors.green
                : road.status == "closed"
                ? Colors.red
                : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  // ---------------- ADD ROAD SHEET ----------------
  void _addRoadSheet(BuildContext context) {
    final name = TextEditingController();
    final origin = TextEditingController();
    final dest = TextEditingController();
    final desc = TextEditingController();

    String status = "open";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: "Road Name")),
              TextField(controller: origin, decoration: const InputDecoration(labelText: "Origin")),
              TextField(controller: dest, decoration: const InputDecoration(labelText: "Destination")),
              TextField(controller: desc, decoration: const InputDecoration(labelText: "Description")),

              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: "open", child: Text("Open")),
                  DropdownMenuItem(value: "closed", child: Text("Closed")),
                  DropdownMenuItem(value: "blocked", child: Text("Blocked")),
                ],
                onChanged: (val) {
                  if (val != null) status = val;
                },
              ),

              ElevatedButton(
                onPressed: () {
                  final road = RoadModel(
                    id: '',
                    name: name.text,
                    status: status,
                    description: desc.text,
                    origin: origin.text,
                    destination: dest.text,
                    distanceKm: 0.0,
                    weather: 'Clear',
                    safetyRating: 5.0,
                    lastUpdated: DateTime.now(),
                  );

                  context.read<RoadController>().submitRoad(road);
                  Navigator.pop(ctx);
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoadController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Road Status"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRoadSheet(context),
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: controller.updateSearchQuery,
              decoration: const InputDecoration(
                hintText: "Search roads...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterChip(
                label: const Text("All"),
                selected: controller.statusFilter == "All",
                onSelected: (_) => controller.setFilter("All"),
              ),
              FilterChip(
                label: const Text("Open"),
                selected: controller.statusFilter == "open",
                onSelected: (_) => controller.setFilter("open"),
              ),
              FilterChip(
                label: const Text("Closed"),
                selected: controller.statusFilter == "closed",
                onSelected: (_) => controller.setFilter("closed"),
              ),
              FilterChip(
                label: const Text("Blocked"),
                selected: controller.statusFilter == "blocked",
                onSelected: (_) => controller.setFilter("blocked"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.hasError
                ? Center(child: Text(controller.errorMessage!))
                : controller.filteredRoads.isEmpty
                ? const Center(child: Text("No Roads Found"))
                : ListView.builder(
              itemCount: controller.filteredRoads.length,
              itemBuilder: (context, index) {
                final road = controller.filteredRoads[index];
                return _roadCard(road, controller);
              },
            ),
          ),
        ],
      ),
    );
  }
}