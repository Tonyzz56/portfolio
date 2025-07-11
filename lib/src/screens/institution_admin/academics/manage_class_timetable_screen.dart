import 'package:flutter/material.dart';
import 'package:school_management_system/src/models/timetable_entry_model.dart';
import 'package:school_management_system/src/models/class_model.dart';
import 'package:school_management_system/src/models/academic_year_model.dart';
import 'package:school_management_system/src/models/term_model.dart';
import 'package:school_management_system/src/services/timetable_service.dart';
// For displaying subject and teacher names - these would be fetched via their respective services
// import 'package:school_management_system/src/services/academic_service.dart'; // To get subject name
// import 'package:school_management_system/src/services/auth_service.dart'; // To get teacher name (or UserService)
import 'timetable_entry_form_screen.dart';
import 'package:intl/intl.dart'; // For potential date display if needed, though timetable is by day

class ManageClassTimetableScreen extends StatefulWidget {
  final String institutionId;
  final AcademicYearModel academicYear;
  final TermModel? term; // Timetable might be term-specific or year-long
  final ClassModel selectedClass;

  const ManageClassTimetableScreen({
    super.key,
    required this.institutionId,
    required this.academicYear,
    this.term,
    required this.selectedClass,
  });

  @override
  State<ManageClassTimetableScreen> createState() => _ManageClassTimetableScreenState();
}

class _ManageClassTimetableScreenState extends State<ManageClassTimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  // final AcademicService _academicService = AcademicService(); // For subject names
  // final AuthService _authService = AuthService(); // For teacher names

  Map<DayOfWeek, List<TimetableEntryModel>> _groupedTimetable = {};

  @override
  void initState() {
    super.initState();
    // Fetch and group timetable entries when the screen loads
    _loadAndGroupTimetable();
  }

  void _loadAndGroupTimetable() {
     _timetableService.getTimetableForClass(
      institutionId: widget.institutionId,
      classId: widget.selectedClass.id,
      academicYearId: widget.academicYear.id,
      termId: widget.term?.id,
    ).listen((entries) {
      if(mounted){
        Map<DayOfWeek, List<TimetableEntryModel>> tempGrouped = {};
        for (var entry in entries) {
          tempGrouped.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
        }
        // Sort entries within each day by start time (already done in service, but good for safety)
        tempGrouped.forEach((day, dayEntries) {
          dayEntries.sort((a, b) => a.startTime.compareTo(b.startTime));
        });
        setState(() {
          _groupedTimetable = tempGrouped;
        });
      }
    });
  }


  void _navigateToForm({TimetableEntryModel? entryToEdit, DayOfWeek? preselectedDay}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimetableEntryFormScreen(
          institutionId: widget.institutionId,
          academicYearId: widget.academicYear.id,
          termId: widget.term?.id,
          selectedClass: widget.selectedClass,
          entryToEdit: entryToEdit,
          // We could pass preselectedDay to the form if adding from a specific day's section
        ),
      ),
    ).then((_) {
      // Refresh is handled by the stream, but if not using stream for initial load:
      // _loadAndGroupTimetable();
    });
  }

  Future<void> _confirmDeleteEntry(TimetableEntryModel entry) async {
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
            return AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text('Delete this timetable slot?\n${dayOfWeekToString(entry.dayOfWeek)}: ${entry.startTime}-${entry.endTime}\nSubject ID: ${entry.subjectId.substring(0,5)}..., Teacher UID: ${entry.teacherUid.substring(0,5)}...'),
                actions: <Widget>[
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                ],
            );
        });
    if (confirm == true) {
        bool success = await _timetableService.deleteTimetableEntry(entry.id);
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Slot deleted.' : 'Failed to delete slot.'), backgroundColor: success ? Colors.green : Colors.red));
            // Stream will auto-update the list
        }
    }
  }

  // Placeholder for fetching subject/teacher names. In a real app, use services and cache.
  Widget _getEntryDetailsWidget(TimetableEntryModel entry) {
    // For now, display IDs. Future: Fetch names.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Subject ID: ${entry.subjectId}", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("Teacher UID: ${entry.teacherUid}"),
        if (entry.roomId != null && entry.roomId!.isNotEmpty) Text("Room: ${entry.roomId}"),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    String title = 'Timetable: ${widget.selectedClass.name}';
    if (widget.term != null) title += ' (${widget.term!.name})';
    title += ' - ${widget.academicYear.name}';

    // Order days of the week correctly
    List<DayOfWeek> sortedDays = DayOfWeek.values.toList();
    // If you want a specific start day, reorder here. For now, natural enum order.

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Timetable Slot',
            onPressed: () => _navigateToForm(),
          ),
        ],
      ),
      body: _groupedTimetable.isEmpty && !_isLoading // Check if loading or genuinely empty
          ? const Center(child: Text('No timetable entries yet. Add some!'))
          : ListView(
              children: sortedDays.map((day) {
                List<TimetableEntryModel> dayEntries = _groupedTimetable[day] ?? [];
                if (dayEntries.isEmpty) {
                  return ExpansionTile(
                    title: Text(dayOfWeekToString(day).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    subtitle: const Text("No entries for this day."),
                    initiallyExpanded: false, // Keep empty days collapsed
                    children: [
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text("Add Slot for ${dayOfWeekToString(day)}"),
                            onPressed: () => _navigateToForm(preselectedDay: day), // Pass day to form
                          ),
                       )
                    ],
                  );
                }
                return ExpansionTile(
                  title: Text(dayOfWeekToString(day).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)),
                  initiallyExpanded: true, // Expand days with entries
                  children: dayEntries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('${entry.startTime} - ${entry.endTime}'),
                        subtitle: _getEntryDetailsWidget(entry),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _navigateToForm(entryToEdit: entry)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteEntry(entry)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
    );
  }
}
