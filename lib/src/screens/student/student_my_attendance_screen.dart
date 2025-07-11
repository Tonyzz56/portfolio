import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/src/models/user_model.dart';
import 'package:school_management_system/src/models/attendance_record_model.dart';
import 'package:school_management_system/src/services/attendance_service.dart';

class StudentMyAttendanceScreen extends StatefulWidget {
  final String? targetChildUidFromRoute; // Passed if parent is viewing
  final String? childNameForParentView; // Passed if parent is viewing

  const StudentMyAttendanceScreen({
    super.key,
    this.targetChildUidFromRoute,
    this.childNameForParentView
  });

  @override
  State<StudentMyAttendanceScreen> createState() => _StudentMyAttendanceScreenState();
}

class _StudentMyAttendanceScreenState extends State<StudentMyAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceRecordModel> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  String _screenTitle = "My Attendance";

  DateTime _endDate = DateTime.now();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));

  UserModel? _currentUser; // The logged-in user (student or parent)
  String? _effectiveStudentUid; // UID of student whose attendance is being viewed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize once, or if relevant props change (though props are final here)
    if (_currentUser == null) {
      _currentUser = Provider.of<UserModel?>(context);
      _initializeTargetStudentAndFetch();
    }
  }

  void _initializeTargetStudentAndFetch() {
    if (_currentUser == null) {
      setState(() {
        _error = "User not authenticated.";
        _isLoading = false;
      });
      return;
    }

    if (widget.targetChildUidFromRoute != null && _currentUser!.role == UserRole.parent) {
      _effectiveStudentUid = widget.targetChildUidFromRoute;
      _screenTitle = "Attendance: ${widget.childNameForParentView ?? 'Child'}";
    } else if (_currentUser!.role == UserRole.student) {
      _effectiveStudentUid = _currentUser!.uid;
      _screenTitle = "My Attendance";
    } else {
      // This case means a non-student/non-parent user reached this screen,
      // or a parent reached it without a target child (e.g. direct navigation to /student/my-attendance)
      setState(() {
        _error = _currentUser!.role == UserRole.parent
            ? "Please select a child from 'My Children' to view their attendance."
            : "Access Denied. This view is for students or parents viewing a child.";
        _isLoading = false;
      });
      return;
    }
    _fetchAttendance();
  }


  Future<void> _fetchAttendance() async {
    if (_currentUser == null || _currentUser!.institutionId == null || _effectiveStudentUid == null) {
      setState(() {
        _error = "User, institution, or target student data not available to fetch attendance.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Using .listen will keep updating, for a one-time fetch with FutureBuilder, use .first
      _attendanceService.getAttendanceForStudent(
        studentUid: _effectiveStudentUid!,
        institutionId: _currentUser!.institutionId!,
        startDate: _startDate,
        endDate: _endDate,
      ).listen((records) {
        if(mounted){
          setState(() {
            _attendanceRecords = records;
            _isLoading = false;
          });
        }
      }, onError: (e) {
         if(mounted){
            setState(() {
                _error = "Error fetching attendance: ${e.toString()}";
                _isLoading = false;
            });
         }
      });
    } catch (e) {
       if(mounted) {
        setState(() {
            _error = "Failed to initiate attendance fetching: ${e.toString()}";
            _isLoading = false;
        });
       }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      if(_effectiveStudentUid != null) _fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat displayFormatter = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        actions: [
          if (_effectiveStudentUid != null)
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: "Select Date Range",
              onPressed: () => _selectDateRange(context),
            )
        ],
      ),
      body: Column(
        children: [
          if (_effectiveStudentUid != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Showing records from: ${displayFormatter.format(_startDate)} to ${displayFormatter.format(_endDate)}",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
            )))
          else if (_attendanceRecords.isEmpty && _effectiveStudentUid != null)
            const Expanded(child: Center(child: Text('No attendance records found for the selected period.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = _attendanceRecords[index];
                  IconData statusIcon;
                  Color statusColor;
                  switch (record.status) {
                    case AttendanceStatus.present:
                      statusIcon = Icons.check_circle;
                      statusColor = Colors.green;
                      break;
                    case AttendanceStatus.absent:
                      statusIcon = Icons.cancel;
                      statusColor = Colors.red;
                      break;
                    case AttendanceStatus.late:
                      statusIcon = Icons.watch_later;
                      statusColor = Colors.orange;
                      break;
                    case AttendanceStatus.excused:
                      statusIcon = Icons.info;
                      statusColor = Colors.blue;
                      break;
                    default:
                      statusIcon = Icons.help_outline;
                      statusColor = Colors.grey;
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Icon(statusIcon, color: statusColor, size: 30),
                      title: Text(
                        "${attendanceStatusToString(record.status).toUpperCase()} on ${displayFormatter.format(record.date)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.subjectId != null) Text("Subject ID: ${record.subjectId}"),
                          if (record.periodSlot != null) Text("Period: ${record.periodSlot}"),
                          if (record.remarks != null && record.remarks!.isNotEmpty) Text("Remarks: ${record.remarks}"),
                        ],
                      ),
                       isThreeLine: (record.subjectId != null || record.periodSlot != null || (record.remarks != null && record.remarks!.isNotEmpty)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
