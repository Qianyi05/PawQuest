class ProfileValidation {
  static int? parseAge(String input) {
    final value = input.trim();
    if (value.isEmpty) return null;
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      throw const FormatException('Please enter a valid age (1–120)');
    }
    return age;
  }
}
