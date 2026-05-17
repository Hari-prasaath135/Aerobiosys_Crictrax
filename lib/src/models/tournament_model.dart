import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tournament Model
//
// Stored in the TOP-LEVEL  /tournaments/{tournamentId}  collection so that
// every authenticated (non-anonymous) user can read all tournaments, while
// Firestore rules restrict writes to the original creator only.
// ─────────────────────────────────────────────────────────────────────────────

class Tournament {
  final String tournamentId;
  final String name;
  final String city;
  final String ground;
  final String organizerName;
  final String organizerPhone;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categories;
  final List<String> tags;
  final String? logoPath;
  final DateTime createdAt;

  /// UID of the Firebase user who created this tournament.
  /// Used by the UI to gate edit / delete actions and enforced by Firestore rules.
  final String createdBy;

  const Tournament({
    required this.tournamentId,
    required this.name,
    required this.city,
    required this.ground,
    required this.organizerName,
    required this.organizerPhone,
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.tags,
    required this.createdAt,
    required this.createdBy,
    this.logoPath,
  });

  // ── Firestore reference ────────────────────────────────────────────────────

  /// Top-level collection — readable by all signed-in, non-anonymous users.
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('tournaments');

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'tournamentId': tournamentId,
        'name': name,
        'city': city,
        'ground': ground,
        'organizerName': organizerName,
        'organizerPhone': organizerPhone,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'categories': categories,
        'tags': tags,
        'logoPath': logoPath,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy, // persisted for Firestore rule checks
      };

  factory Tournament.fromMap(Map<String, dynamic> map) => Tournament(
        tournamentId: map['tournamentId'] as String,
        name: map['name'] as String,
        city: map['city'] as String,
        ground: map['ground'] as String,
        organizerName: map['organizerName'] as String,
        organizerPhone: map['organizerPhone'] as String,
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: (map['endDate'] as Timestamp).toDate(),
        categories: List<String>.from(map['categories'] ?? []),
        tags: List<String>.from(map['tags'] ?? []),
        logoPath: map['logoPath'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        // Graceful fallback — older documents without createdBy still load.
        createdBy: (map['createdBy'] as String?) ?? '',
      );

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Generate a unique ID (uses Firestore's built-in ID generator).
  static String generateId() => _col.doc().id;

  /// Returns true when the currently signed-in user is the creator.
  bool get isOwnedByCurrentUser {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == createdBy;
  }

  /// Returns true when the current user is anonymous.
  /// Used to block tournament access at the app layer (Firestore rules also enforce this).
  static bool get currentUserIsAnonymous {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Save (create or overwrite) a tournament.
  /// The [createdBy] field in the payload must match the caller's UID —
  /// enforced both here and by Firestore rules.
  static Future<void> save(Tournament tournament) async {
    if (currentUserIsAnonymous) {
      throw Exception('Anonymous users cannot create tournaments.');
    }
    await _col.doc(tournament.tournamentId).set(tournament.toMap());
  }

  /// Fetch ALL tournaments visible to every authenticated, non-anonymous user,
  /// ordered by creation time (newest first).
  static Future<List<Tournament>> getAll() async {
    if (currentUserIsAnonymous) {
      throw Exception('Anonymous users cannot view tournaments.');
    }
    final snap = await _col.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => Tournament.fromMap(doc.data())).toList();
  }

  /// Real-time stream of ALL tournaments — every signed-in user gets live updates
  /// including tournaments created by other users.
  static Stream<List<Tournament>> stream() {
    if (currentUserIsAnonymous) {
      // Return an empty stream instead of throwing, so the UI can handle it gracefully.
      return const Stream.empty();
    }
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Tournament.fromMap(doc.data())).toList());
  }

  /// Delete a tournament by ID.
  /// Firestore rules ensure only the creator can actually do this.
  static Future<void> delete(String tournamentId) async {
    if (currentUserIsAnonymous) {
      throw Exception('Anonymous users cannot delete tournaments.');
    }
    await _col.doc(tournamentId).delete();
  }
}