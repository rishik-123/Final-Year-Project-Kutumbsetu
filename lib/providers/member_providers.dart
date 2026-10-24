/// ============================================================================
/// KutumbSetu - Member Directory Providers & State Management
/// ============================================================================
/// Provides state containers and computed streams for the Community Member Directory:
/// - Full-text search and multi-facet filtering (village, city, profession, etc.)
/// - Configurable multi-attribute sorting (A-Z, newest, verified-first, etc.)
/// - Member bookmarking and persistent favorites.
/// - Alphabetical grouping for index-based list navigation.
/// - Real-time follow/connect request workflow and connection status tracking.
/// ============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_model.dart';
import '../repository/member_repository.dart';

/// Available sorting options for ordering community directory members.
enum SortOption {
  /// Sort alphabetically ascending by member full name.
  nameAZ,

  /// Sort alphabetically descending by member full name.
  nameZA,

  /// Sort alphabetically by profession.
  profession,

  /// Sort alphabetically by city.
  city,

  /// Sort alphabetically by native village.
  village,

  /// Show newest registered members first.
  newestJoined,

  /// Show oldest registered members first.
  oldestJoined,

  /// Prioritize verified badge holders at the top.
  verifiedFirst,
}

/// Extension providing user-facing display labels for [SortOption].
extension SortOptionExtension on SortOption {
  /// Formatted localized label displayed in bottom sheets and dropdown menus.
  String get label {
    switch (this) {
      case SortOption.nameAZ:
        return 'Alphabetical (A - Z)';
      case SortOption.nameZA:
        return 'Alphabetical (Z - A)';
      case SortOption.profession:
        return 'Profession';
      case SortOption.city:
        return 'City';
      case SortOption.village:
        return 'Village';
      case SortOption.newestJoined:
        return 'Newest Joined';
      case SortOption.oldestJoined:
        return 'Oldest Joined';
      case SortOption.verifiedFirst:
        return 'Verified First';
    }
  }
}


/// Holds active multi-criteria filters for refining community member search results.
class MemberFilterState {
  /// Filter by specific native villages.
  final Set<String> selectedVillages;

  /// Filter by current residential or business cities.
  final Set<String> selectedCities;

  /// Filter by occupational titles or professions.
  final Set<String> selectedProfessions;

  /// Filter by highest degree or educational qualifications.
  final Set<String> selectedEducations;

  /// Filter by business categories / industry types.
  final Set<String> selectedBusinessCategories;

  /// Filter by ABO/Rh blood groups.
  final Set<String> selectedBloodGroups;

  /// Filter by gender (e.g. Male, Female).
  final Set<String> selectedGenders;

  /// When true, only verified profiles are displayed.
  final bool? isVerifiedOnly;

  /// When true, only active members are displayed.
  final bool? isActiveOnly;

  const MemberFilterState({
    this.selectedVillages = const {},
    this.selectedCities = const {},
    this.selectedProfessions = const {},
    this.selectedEducations = const {},
    this.selectedBusinessCategories = const {},
    this.selectedBloodGroups = const {},
    this.selectedGenders = const {},
    this.isVerifiedOnly,
    this.isActiveOnly,
  });

  /// Indicates whether all filter facets are empty (default reset state).
  bool get isEmpty =>
      selectedVillages.isEmpty &&
      selectedCities.isEmpty &&
      selectedProfessions.isEmpty &&
      selectedEducations.isEmpty &&
      selectedBusinessCategories.isEmpty &&
      selectedBloodGroups.isEmpty &&
      selectedGenders.isEmpty &&
      isVerifiedOnly == null &&
      isActiveOnly == null;

  /// Total count of active filter chips across all facets.
  int get activeFilterCount {
    int count = 0;
    count += selectedVillages.length;
    count += selectedCities.length;
    count += selectedProfessions.length;
    count += selectedEducations.length;
    count += selectedBusinessCategories.length;
    count += selectedBloodGroups.length;
    count += selectedGenders.length;
    if (isVerifiedOnly != null) count += 1;
    if (isActiveOnly != null) count += 1;
    return count;
  }

  /// Returns a clone of [MemberFilterState] with optional replacements.
  MemberFilterState copyWith({
    Set<String>? selectedVillages,
    Set<String>? selectedCities,
    Set<String>? selectedProfessions,
    Set<String>? selectedEducations,
    Set<String>? selectedBusinessCategories,
    Set<String>? selectedBloodGroups,
    Set<String>? selectedGenders,
    bool? isVerifiedOnly,
    bool? isActiveOnly,
    bool clearVerified = false,
    bool clearActive = false,
  }) {
    return MemberFilterState(
      selectedVillages: selectedVillages ?? this.selectedVillages,
      selectedCities: selectedCities ?? this.selectedCities,
      selectedProfessions: selectedProfessions ?? this.selectedProfessions,
      selectedEducations: selectedEducations ?? this.selectedEducations,
      selectedBusinessCategories:
          selectedBusinessCategories ?? this.selectedBusinessCategories,
      selectedBloodGroups: selectedBloodGroups ?? this.selectedBloodGroups,
      selectedGenders: selectedGenders ?? this.selectedGenders,
      isVerifiedOnly:
          clearVerified ? null : (isVerifiedOnly ?? this.isVerifiedOnly),
      isActiveOnly: clearActive ? null : (isActiveOnly ?? this.isActiveOnly),
    );
  }
}

/// [StateNotifier] managing directory filter chips and toggle operations.
class MemberFilterNotifier extends StateNotifier<MemberFilterState> {
  MemberFilterNotifier() : super(const MemberFilterState());


  void toggleVillage(String village) {
    final updated = Set<String>.from(state.selectedVillages);
    if (updated.contains(village)) {
      updated.remove(village);
    } else {
      updated.add(village);
    }
    state = state.copyWith(selectedVillages: updated);
  }

  void toggleCity(String city) {
    final updated = Set<String>.from(state.selectedCities);
    if (updated.contains(city)) {
      updated.remove(city);
    } else {
      updated.add(city);
    }
    state = state.copyWith(selectedCities: updated);
  }

  void toggleProfession(String profession) {
    final updated = Set<String>.from(state.selectedProfessions);
    if (updated.contains(profession)) {
      updated.remove(profession);
    } else {
      updated.add(profession);
    }
    state = state.copyWith(selectedProfessions: updated);
  }

  void toggleEducation(String education) {
    final updated = Set<String>.from(state.selectedEducations);
    if (updated.contains(education)) {
      updated.remove(education);
    } else {
      updated.add(education);
    }
    state = state.copyWith(selectedEducations: updated);
  }

  void toggleBusinessCategory(String category) {
    final updated = Set<String>.from(state.selectedBusinessCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(selectedBusinessCategories: updated);
  }

  void toggleBloodGroup(String bg) {
    final updated = Set<String>.from(state.selectedBloodGroups);
    if (updated.contains(bg)) {
      updated.remove(bg);
    } else {
      updated.add(bg);
    }
    state = state.copyWith(selectedBloodGroups: updated);
  }

  void toggleGender(String gender) {
    final updated = Set<String>.from(state.selectedGenders);
    if (updated.contains(gender)) {
      updated.remove(gender);
    } else {
      updated.add(gender);
    }
    state = state.copyWith(selectedGenders: updated);
  }

  void toggleVerifiedOnly() {
    if (state.isVerifiedOnly == true) {
      state = state.copyWith(clearVerified: true);
    } else {
      state = state.copyWith(isVerifiedOnly: true);
    }
  }

  void toggleActiveOnly() {
    if (state.isActiveOnly == true) {
      state = state.copyWith(clearActive: true);
    } else {
      state = state.copyWith(isActiveOnly: true);
    }
  }

  void clearAll() {
    state = const MemberFilterState();
  }
}

/// [StateNotifier] managing user's local bookmarked / starred member IDs.
class FavoriteNotifier extends StateNotifier<Set<String>> {
  FavoriteNotifier() : super({});

  /// Toggles favorite status for a given [memberId].
  void toggleFavorite(String memberId) {
    final updated = Set<String>.from(state);
    if (updated.contains(memberId)) {
      updated.remove(memberId);
    } else {
      updated.add(memberId);
    }
    state = updated;
  }
}

/// Provider supplying the [MemberRepository] abstraction for fetching member records.
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return LocalMemberRepository();
});

/// Future provider fetching the unfiltered raw directory member records from the backend.
final rawMemberListProvider = FutureProvider<List<Member>>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getMembers();
});

/// State provider holding the current active search bar query string.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// State notifier provider tracking the currently selected sorting option.
final sortOptionProvider =
    StateNotifierProvider<SortNotifier, SortOption>((ref) {
  return SortNotifier();
});

/// State notifier managing active sorting criteria for the directory list.
class SortNotifier extends StateNotifier<SortOption> {
  SortNotifier() : super(SortOption.nameAZ);

  /// Updates active sort criteria.
  void setSortOption(SortOption option) {
    state = option;
  }
}

/// State notifier provider holding all active filter chip selections.
final activeFiltersProvider =
    StateNotifierProvider<MemberFilterNotifier, MemberFilterState>((ref) {
  return MemberFilterNotifier();
});

/// State notifier provider storing set of bookmarked/favorite member IDs.
final favoriteMemberIdsProvider =
    StateNotifierProvider<FavoriteNotifier, Set<String>>((ref) {
  return FavoriteNotifier();
});

/// Computed provider applying active search queries, facet filters, and sorting
/// to produce the final filtered list of community members.
final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final rawAsync = ref.watch(rawMemberListProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filters = ref.watch(activeFiltersProvider);
  final sortOption = ref.watch(sortOptionProvider);


  return rawAsync.whenData((members) {
    List<Member> result = List.from(members);

    // 1. Search Filter
    if (query.isNotEmpty) {
      result = result.where((m) {
        return m.fullName.toLowerCase().contains(query) ||
            m.email.toLowerCase().contains(query) ||
            m.village.toLowerCase().contains(query) ||
            m.city.toLowerCase().contains(query) ||
            m.profession.toLowerCase().contains(query) ||
            m.education.toLowerCase().contains(query) ||
            m.company.toLowerCase().contains(query) ||
            m.mobileNumber.replaceAll(' ', '').contains(query);
      }).toList();
    }

    // 2. Attribute Filters
    if (filters.selectedVillages.isNotEmpty) {
      result = result
          .where((m) => filters.selectedVillages.contains(m.village))
          .toList();
    }

    if (filters.selectedCities.isNotEmpty) {
      result =
          result.where((m) => filters.selectedCities.contains(m.city)).toList();
    }

    if (filters.selectedProfessions.isNotEmpty) {
      result = result
          .where((m) => filters.selectedProfessions.contains(m.profession))
          .toList();
    }

    if (filters.selectedEducations.isNotEmpty) {
      result = result
          .where((m) => filters.selectedEducations.contains(m.education))
          .toList();
    }

    if (filters.selectedBusinessCategories.isNotEmpty) {
      result = result
          .where((m) =>
              filters.selectedBusinessCategories.contains(m.businessCategory))
          .toList();
    }

    if (filters.selectedBloodGroups.isNotEmpty) {
      result = result
          .where((m) => filters.selectedBloodGroups.contains(m.bloodGroup))
          .toList();
    }

    if (filters.selectedGenders.isNotEmpty) {
      result = result
          .where((m) => filters.selectedGenders.contains(m.gender))
          .toList();
    }

    if (filters.isVerifiedOnly == true) {
      result = result.where((m) => m.isVerified).toList();
    }

    if (filters.isActiveOnly == true) {
      result = result.where((m) => m.isActive).toList();
    }

    // 3. Sorting
    switch (sortOption) {
      case SortOption.nameAZ:
        result.sort((a, b) =>
            a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
        break;
      case SortOption.nameZA:
        result.sort((a, b) =>
            b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()));
        break;
      case SortOption.profession:
        result.sort((a, b) =>
            a.profession.toLowerCase().compareTo(b.profession.toLowerCase()));
        break;
      case SortOption.city:
        result.sort(
            (a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
        break;
      case SortOption.village:
        result.sort((a, b) =>
            a.village.toLowerCase().compareTo(b.village.toLowerCase()));
        break;
      case SortOption.newestJoined:
        result.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));
        break;
      case SortOption.oldestJoined:
        result.sort((a, b) => a.joinedDate.compareTo(b.joinedDate));
        break;
      case SortOption.verifiedFirst:
        result.sort((a, b) {
          if (a.isVerified && !b.isVerified) return -1;
          if (!a.isVerified && b.isVerified) return 1;
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });
        break;
    }

    return result;
  });
/// Groups the filtered members by their primary uppercase initial character for fast alphabetical navigation.
final groupedMembersProvider =
    Provider<AsyncValue<Map<String, List<Member>>>>((ref) {
  final filteredAsync = ref.watch(filteredMembersProvider);

  return filteredAsync.whenData((members) {
    final Map<String, List<Member>> grouped = {};
    for (final member in members) {
      final letter = member.firstLetter;
      grouped.putIfAbsent(letter, () => []).add(member);
    }
    return grouped;
  });
});


/// Represents the connection/follow state between the authenticated user and other directory members.
class DirectoryConnectionState {
  /// Set of member IDs currently mutually connected or followed.
  final Set<String> connectedMemberIds;

  /// Set of member IDs to whom follow requests have been dispatched and are awaiting approval.
  final Set<String> pendingRequestMemberIds;

  /// True during active network operations.
  final bool isLoading;

  const DirectoryConnectionState({
    this.connectedMemberIds = const {},
    this.pendingRequestMemberIds = const {},
    this.isLoading = false,
  });

  /// Returns a clone of [DirectoryConnectionState] with optional overrides.
  DirectoryConnectionState copyWith({
    Set<String>? connectedMemberIds,
    Set<String>? pendingRequestMemberIds,
    bool? isLoading,
  }) {
    return DirectoryConnectionState(
      connectedMemberIds: connectedMemberIds ?? this.connectedMemberIds,
      pendingRequestMemberIds: pendingRequestMemberIds ?? this.pendingRequestMemberIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// [StateNotifier] managing user connections, outgoing follow requests, and responses.
class DirectoryConnectionNotifier extends StateNotifier<DirectoryConnectionState> {
  DirectoryConnectionNotifier() : super(const DirectoryConnectionState());

  /// Loads confirmed connections and pending outgoing requests for the given [userId].
  Future<void> loadUserConnections(String userId) async {
    if (userId.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/directory/connections/$userId'),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final List connected = data['connectedUserIds'] ?? [];
          final List pending = data['pendingSentIds'] ?? [];
          state = state.copyWith(
            connectedMemberIds: connected.map((e) => e.toString()).toSet(),
            pendingRequestMemberIds: pending.map((e) => e.toString()).toSet(),
          );
        }
      }
    } catch (_) {}
  }

  /// Sends a follow or connection request to [targetMember].
  Future<bool> sendFollowRequest({
    required String senderId,
    required String senderName,
    required String senderEmail,
    required Member targetMember,
  }) async {
    final memberId = targetMember.id;
    final pending = Set<String>.from(state.pendingRequestMemberIds)..add(memberId);
    state = state.copyWith(pendingRequestMemberIds: pending);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/directory/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'senderName': senderName,
          'senderEmail': senderEmail,
          'receiverId': targetMember.id,
          'receiverName': targetMember.fullName,
          'receiverEmail': targetMember.email,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Responds to an incoming connection request with either 'accepted' or 'rejected'.
  Future<bool> respondToRequest(String requestId, String status) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/directory/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestId': requestId,
          'status': status,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Locally confirms an accepted connection request without re-fetching all connections.
  void acceptFollowRequest(String memberId) {
    final pending = Set<String>.from(state.pendingRequestMemberIds)..remove(memberId);
    final connected = Set<String>.from(state.connectedMemberIds)..add(memberId);
    state = state.copyWith(connectedMemberIds: connected, pendingRequestMemberIds: pending);
  }

  /// Returns true if a mutual connection exists with [memberId].
  bool isConnected(String memberId) => state.connectedMemberIds.contains(memberId);

  /// Returns true if an outgoing request to [memberId] is still pending.
  bool isPending(String memberId) => state.pendingRequestMemberIds.contains(memberId);
}

/// Global provider for managing directory member connections and follow status.
final directoryConnectionProvider = StateNotifierProvider<DirectoryConnectionNotifier, DirectoryConnectionState>((ref) {
  return DirectoryConnectionNotifier();
});


