/// String extensions for Open Fit
extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
