// Defines the structure for returning results from batch operations.
class BatchProcessResult {
  final int totalProcessed;
  final int successfullyUpdated;
  final int emailsTriggered;
  final List<String> errors; // List of error messages or identifiers

  BatchProcessResult({
    required this.totalProcessed,
    required this.successfullyUpdated,
    required this.emailsTriggered,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'BatchProcessResult(totalProcessed: $totalProcessed, successfullyUpdated: $successfullyUpdated, emailsTriggered: $emailsTriggered, errors: ${errors.length})';
  }

  String toDisplayString() {
    StringBuffer sb = StringBuffer();
    sb.writeln("Processing Complete!");
    sb.writeln("------------------------------------");
    sb.writeln("Total Institutions Checked: $totalProcessed");
    sb.writeln("Institutions Updated: $successfullyUpdated");
    sb.writeln("Email Notifications Triggered: $emailsTriggered");
    if (errors.isNotEmpty) {
      sb.writeln("Errors Encountered: ${errors.length}");
      errors.forEach((err) => sb.writeln(" - $err"));
    } else {
      sb.writeln("No errors encountered.");
    }
    return sb.toString();
  }
}
