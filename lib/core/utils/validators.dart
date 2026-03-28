class AppValidators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? v, String password) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? taskTitle(String? v) {
    if (v == null || v.isEmpty) return 'Task title is required';
    if (v.trim().isEmpty) return 'Enter a valid title';
    return null;
  }

  static String? strongPassword(String? v) {
    final base = password(v);
    if (base != null) return base;
    if (!RegExp(r'[A-Z]').hasMatch(v!))
      return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
    if (!RegExp(r'[!@#\$%^&*]').hasMatch(v))
      return 'Include at least one special character';
    return null;
  }
}
