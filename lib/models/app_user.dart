/// A signed-in user of the app. Phase 1 uses an in-memory mock store;
/// Phase 3 replaces the source with Firebase Authentication.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.phoneNumber,
    this.phoneVerified = false,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? phoneNumber;
  final bool phoneVerified;

  /// Initials for the avatar ring, e.g. "AR".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final name = parts.first;
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
    }
    final first = parts.first.substring(0, 1);
    final last = parts.last.isEmpty ? '' : parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
  }

  @override
  String toString() => 'AppUser($email)';
}
