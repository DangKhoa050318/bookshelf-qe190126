final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp _wholeNumber = RegExp(r'^\d+$');

/// Form validators. The messages are the exact texts required by the exam.
class Validators {
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Please enter a valid email address';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Title is required';
    if (v.length > 100) return 'Title must be at most 100 characters';
    return null;
  }

  static String? author(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Author is required';
    if (v.length > 60) return 'Author must be at most 60 characters';
    return null;
  }

  static String? genre(String? value) =>
      value == null ? 'Please choose a genre' : null;

  static String? status(String? value) =>
      value == null ? 'Please choose a status' : null;

  static String? rating(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_wholeNumber.hasMatch(v) || int.parse(v) > 5) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  static String? notes(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > 300) return 'Notes must be at most 300 characters';
    return null;
  }
}
