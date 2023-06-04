class FleetingNotesException implements Exception {
  final String message;

  FleetingNotesException(this.message);

  @override
  String toString() {
    return "FleetingNotesException(message: $message)";
  }
}
