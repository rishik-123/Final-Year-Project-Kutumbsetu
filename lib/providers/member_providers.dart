import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_model.dart';
import '../repository/member_repository.dart';

enum SortOption {
  nameAZ,
  nameZA,
  profession,
  city,
  village,
  newestJoined,
  oldestJoined,
  verifiedFirst,
}

extension SortOptionExtension on SortOption {
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

class MemberFilterState {
  final Set<String> selectedVillages;
  final Set<String> selectedCities;
  final Set<String> selectedProfessions;
  final Set<String> selectedEducations;
  final Set<String> selectedBusinessCategories;
  final Set<String> selectedBloodGroups;
  final Set<String> selectedGenders;
  final bool? isVerifiedOnly;
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

class FavoriteNotifier extends StateNotifier<Set<String>> {
  FavoriteNotifier() : super({});

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

// Providers definition
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return LocalMemberRepository();
});

final rawMemberListProvider = FutureProvider<List<Member>>((ref) async {
  final repo = ref.watch(memberRepositoryProvider);
  return repo.getMembers();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final sortOptionProvider =
    StateNotifierProvider<SortNotifier, SortOption>((ref) {
  return SortNotifier();
});

class SortNotifier extends StateNotifier<SortOption> {
  SortNotifier() : super(SortOption.nameAZ);

  void setSortOption(SortOption option) {
    state = option;
  }
}

final activeFiltersProvider =
    StateNotifierProvider<MemberFilterNotifier, MemberFilterState>((ref) {
  return MemberFilterNotifier();
});

final favoriteMemberIdsProvider =
    StateNotifierProvider<FavoriteNotifier, Set<String>>((ref) {
  return FavoriteNotifier();
});

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
});

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

// Directory Connected / Followed Members State Management
class DirectoryConnectionState {
  final Set<String> connectedMemberIds;
  final Set<String> pendingRequestMemberIds;

  const DirectoryConnectionState({
    this.connectedMemberIds = const {},
    this.pendingRequestMemberIds = const {},
  });

  DirectoryConnectionState copyWith({
    Set<String>? connectedMemberIds,
    Set<String>? pendingRequestMemberIds,
  }) {
    return DirectoryConnectionState(
      connectedMemberIds: connectedMemberIds ?? this.connectedMemberIds,
      pendingRequestMemberIds: pendingRequestMemberIds ?? this.pendingRequestMemberIds,
    );
  }
}

class DirectoryConnectionNotifier extends StateNotifier<DirectoryConnectionState> {
  DirectoryConnectionNotifier() : super(const DirectoryConnectionState());

  void sendFollowRequest(String memberId) {
    final pending = Set<String>.from(state.pendingRequestMemberIds)..add(memberId);
    state = state.copyWith(pendingRequestMemberIds: pending);
  }

  void acceptFollowRequest(String memberId) {
    final pending = Set<String>.from(state.pendingRequestMemberIds)..remove(memberId);
    final connected = Set<String>.from(state.connectedMemberIds)..add(memberId);
    state = state.copyWith(connectedMemberIds: connected, pendingRequestMemberIds: pending);
  }

  bool isConnected(String memberId) => state.connectedMemberIds.contains(memberId);
  bool isPending(String memberId) => state.pendingRequestMemberIds.contains(memberId);
}

final directoryConnectionProvider = StateNotifierProvider<DirectoryConnectionNotifier, DirectoryConnectionState>((ref) {
  return DirectoryConnectionNotifier();
});

