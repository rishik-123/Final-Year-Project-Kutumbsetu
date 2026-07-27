import 'dart:math';

import 'package:flutter/material.dart';

import 'matrimonial_module.dart';

void main() {
  runApp(const KutumbSetuApp());
}

class AppPalette {
  static const saffron = Color(0xFFF57C00);
  static const saffronDeep = Color(0xFFC85F00);
  static const saffronTint = Color(0xFFFFE3C2);
  static const forest = Color(0xFF2E7D32);
  static const forestTint = Color(0xFFDCEFDD);
  static const peacock = Color(0xFF0288D1);
  static const peacockTint = Color(0xFFDCEFFB);
  static const pink = Color(0xFFC2185B);
  static const gold = Color(0xFFC9A227);
  static const ink = Color(0xFF212121);
  static const softInk = Color(0xFF6B6B6B);
  static const canvas = Color(0xFFFAFAFA);
  static const divider = Color(0xFFECE7DE);
}

String tr(bool gujarati, String english, String gujarati) {
  return gujarati ? gujarati : english;
}

String makeFamilyId() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  final suffix = List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  return 'BDS-${DateTime.now().year}-$suffix';
}

class KutumbSetuApp extends StatefulWidget {
  const KutumbSetuApp({super.key});

  @override
  State<KutumbSetuApp> createState() => _KutumbSetuAppState();
}

class _KutumbSetuAppState extends State<KutumbSetuApp> {
  bool _authenticated = false;
  bool _gujarati = false;
  String _displayName = 'Rajeshbhai Chauhan';
  String _familyId = 'BDS-2026-7M4QK2';

  void _authenticate({required String name, String? familyId}) {
    setState(() {
      _displayName = name.trim().isEmpty ? 'Rajeshbhai Chauhan' : name.trim();
      _familyId = familyId ?? _familyId;
      _authenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.saffron,
        primary: AppPalette.saffron,
        secondary: AppPalette.forest,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppPalette.canvas,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppPalette.ink,
            displayColor: AppPalette.ink,
            fontFamily: 'Roboto',
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.saffron, width: 1.6),
        ),
      ),
    );

    return MaterialApp(
      title: 'KutumbSetu',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: _authenticated
          ? CommunityShell(
              displayName: _displayName,
              familyId: _familyId,
              gujarati: _gujarati,
              onLanguageChanged: () => setState(() => _gujarati = !_gujarati),
              onLogout: () => setState(() => _authenticated = false),
            )
          : AuthPage(
              gujarati: _gujarati,
              onLanguageChanged: () => setState(() => _gujarati = !_gujarati),
              onAuthenticated: _authenticate,
            ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.gujarati,
    required this.onLanguageChanged,
    required this.onAuthenticated,
  });

  final bool gujarati;
  final VoidCallback onLanguageChanged;
  final void Function({required String name, String? familyId}) onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _family = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _family.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onAuthenticated(
      name: _signUp ? _name.text : (_name.text.isEmpty ? 'Rajeshbhai Chauhan' : _name.text),
      familyId: _signUp ? makeFamilyId() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gu = widget.gujarati;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7EE), Color(0xFFFAFAFA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: widget.onLanguageChanged,
                        icon: const Icon(Icons.language_rounded, size: 18),
                        label: Text(gu ? 'English' : 'ગુજરાતી'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.saffronDeep,
                          side: const BorderSide(color: AppPalette.saffron),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Center(child: _BrandMark(size: 82)),
                    const SizedBox(height: 16),
                    Text(
                      'KutumbSetu',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppPalette.saffronDeep,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(gu, 'Babariawad Darji Samaj', 'બાબરિયાવાડ દરજી સમાજ'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.forest,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        gu,
                        'One place for our families, community and relationships.',
                        'આપણા પરિવાર, સમાજ અને સંબંધો માટે એક જ સ્થળ.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppPalette.softInk, height: 1.45),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Color(0x12000000), blurRadius: 22, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthToggle(
                              signUp: _signUp,
                              gujarati: gu,
                              onChanged: (value) => setState(() => _signUp = value),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              _signUp
                                  ? tr(gu, 'Create your community account', 'તમારું સમાજ ખાતું બનાવો')
                                  : tr(gu, 'Welcome back', 'પાછા આવકાર'),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _signUp
                                  ? tr(gu, 'Your Family ID will be created after sign up.', 'સાઇન અપ પછી તમારું ફેમિલી ID બનશે.')
                                  : tr(gu, 'Sign in to your family and community.', 'તમારા પરિવાર અને સમાજમાં સાઇન ઇન કરો.'),
                              style: const TextStyle(color: AppPalette.softInk, height: 1.35),
                            ),
                            const SizedBox(height: 20),
                            if (_signUp) ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: tr(gu, 'Full name', 'પૂરું નામ'),
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) => value == null || value.trim().length < 2
                                    ? tr(gu, 'Please enter your name', 'કૃપા કરીને તમારું નામ લખો')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _family,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: tr(gu, 'Family / surname', 'પરિવાર / અટક'),
                                  prefixIcon: const Icon(Icons.account_tree_outlined),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty
                                    ? tr(gu, 'Please enter family or surname', 'પરિવાર અથવા અટક લખો')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ] else
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: tr(gu, 'Name or Family ID', 'નામ અથવા ફેમિલી ID'),
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                              ),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: tr(gu, 'Mobile number', 'મોબાઇલ નંબર'),
                                prefixText: '+91  ',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              validator: (value) => value == null || value.replaceAll(RegExp(r'\D'), '').length < 10
                                  ? tr(gu, 'Enter a valid 10-digit number', '10 અંકનો માન્ય નંબર લખો')
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                labelText: tr(gu, 'Password', 'પાસવર્ડ'),
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (value) => value == null || value.length < 4
                                  ? tr(gu, 'Use at least 4 characters', 'ઓછામાં ઓછા 4 અક્ષરો વાપરો')
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppPalette.saffron,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                _signUp ? tr(gu, 'Create account & Family ID', 'ખાતું અને ફેમિલી ID બનાવો') : tr(gu, 'Sign in', 'સાઇન ઇન કરો'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr(
                                gu,
                                'For the prototype, any valid mobile number and password work.',
                                'પ્રોટોટાઇપ માટે કોઈપણ માન્ય મોબાઇલ નંબર અને પાસવર્ડ ચાલશે.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.signUp, required this.gujarati, required this.onChanged});

  final bool signUp;
  final bool gujarati;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFFFF3E3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _toggleButton(context, false, tr(gujarati, 'Sign in', 'સાઇન ઇન')),
          _toggleButton(context, true, tr(gujarati, 'Sign up', 'સાઇન અપ')),
        ],
      ),
    );
  }

  Widget _toggleButton(BuildContext context, bool value, String label) {
    final selected = signUp == value;
    return Expanded(
      child: TextButton(
        onPressed: () => onChanged(value),
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : AppPalette.saffronDeep,
          backgroundColor: selected ? AppPalette.saffron : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class CommunityShell extends StatefulWidget {
  const CommunityShell({
    super.key,
    required this.displayName,
    required this.familyId,
    required this.gujarati,
    required this.onLanguageChanged,
    required this.onLogout,
  });

  final String displayName;
  final String familyId;
  final bool gujarati;
  final VoidCallback onLanguageChanged;
  final VoidCallback onLogout;

  @override
  State<CommunityShell> createState() => _CommunityShellState();
}

class _CommunityShellState extends State<CommunityShell> {
  int _tab = 0;

  void _openMatrimony() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatrimonialHubPage(gujarati: widget.gujarati, onLanguageChanged: widget.onLanguageChanged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        displayName: widget.displayName,
        gujarati: widget.gujarati,
        onLanguageChanged: widget.onLanguageChanged,
        onTabSelected: (tab) => setState(() => _tab = tab),
        onMatrimony: _openMatrimony,
      ),
      FamilyTreePage(gujarati: widget.gujarati),
      CommunityPage(gujarati: widget.gujarati),
      EventsPage(gujarati: widget.gujarati),
      ProfilePage(
        displayName: widget.displayName,
        familyId: widget.familyId,
        gujarati: widget.gujarati,
        onLanguageChanged: widget.onLanguageChanged,
        onLogout: widget.onLogout,
        onOpenTree: () => setState(() => _tab = 1),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        height: 74,
        indicatorColor: AppPalette.saffronTint,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: tr(widget.gujarati, 'Home', 'હોમ')),
          NavigationDestination(icon: const Icon(Icons.account_tree_outlined), selectedIcon: const Icon(Icons.account_tree_rounded), label: tr(widget.gujarati, 'Tree', 'વૃક્ષ')),
          NavigationDestination(icon: const Icon(Icons.groups_2_outlined), selectedIcon: const Icon(Icons.groups_2_rounded), label: tr(widget.gujarati, 'Community', 'સમાજ')),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month_rounded), label: tr(widget.gujarati, 'Events', 'કાર્યક્રમો')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: tr(widget.gujarati, 'Profile', 'પ્રોફાઇલ')),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.displayName,
    required this.gujarati,
    required this.onLanguageChanged,
    required this.onTabSelected,
    required this.onMatrimony,
  });

  final String displayName;
  final bool gujarati;
  final VoidCallback onLanguageChanged;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMatrimony;

  void _showNotice(BuildContext context, String title, String detail) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(detail, style: const TextStyle(color: AppPalette.softInk, height: 1.45)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gu = gujarati;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Jay Shree Krishna 🙏', 'જય શ્રી કૃષ્ણ 🙏'),
            title: displayName,
            subtitle: tr(gu, 'Search families, villages, members…', 'પરિવાર, ગામ, સભ્યો શોધો…'),
            onLanguage: onLanguageChanged,
            onNotifications: () => _showNotice(
              context,
              tr(gu, 'Notifications', 'સૂચનાઓ'),
              tr(gu, 'Your family tree update has been approved. The Blood Donation Camp is in 7 days.', 'તમારું ફેમિલી ટ્રી અપડેટ મંજૂર થયું છે. રક્તદાન કેમ્પ 7 દિવસમાં છે.'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(title: tr(gu, 'Quick actions', 'ઝડપી ક્રિયાઓ')),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: .82,
                  children: [
                    FeatureButton(icon: Icons.account_tree_rounded, label: tr(gu, 'Family Tree', 'કુટુંબ વૃક્ષ'), color: AppPalette.forest, tint: AppPalette.forestTint, onTap: () => onTabSelected(1)),
                    FeatureButton(icon: Icons.contact_page_rounded, label: tr(gu, 'Directory', 'સભ્ય યાદી'), color: AppPalette.peacock, tint: AppPalette.peacockTint, onTap: () => onTabSelected(2)),
                    FeatureButton(icon: Icons.favorite_rounded, label: tr(gu, 'Matrimony', 'લગ્ન વિષયક'), color: AppPalette.pink, tint: const Color(0xFFFCE4EC), onTap: onMatrimony),
                    FeatureButton(icon: Icons.calendar_month_rounded, label: tr(gu, 'Events', 'કાર્યક્રમો'), color: AppPalette.saffron, tint: AppPalette.saffronTint, onTap: () => onTabSelected(3)),
                    FeatureButton(icon: Icons.volunteer_activism_rounded, label: tr(gu, 'Donations', 'દાન પુણ્ય'), color: AppPalette.gold, tint: const Color(0xFFFFF3CD), onTap: () => _showNotice(context, tr(gu, 'Donations', 'દાન પુણ્ય'), tr(gu, 'Scholarship Fund, medical help and community initiatives are open for contributions.', 'શિષ્યવૃત્તિ ફંડ, તબીબી સહાય અને સમાજના કાર્યો માટે યોગદાન આપી શકો છો.'))),
                    FeatureButton(icon: Icons.newspaper_rounded, label: tr(gu, 'News', 'સમાચાર'), color: AppPalette.peacock, tint: const Color(0xFFE1F5FE), onTap: () => _showNotice(context, tr(gu, 'News & notices', 'સમાચાર અને નોટિસ'), tr(gu, 'Annual Trust elections will be held on 29 August at Community Bhavan, Rajkot.', 'વાર્ષિક ટ્રસ્ટ ચૂંટણી 29 ઓગસ્ટે સમાજ ભવન, રાજકોટ ખાતે યોજાશે.'))),
                    FeatureButton(icon: Icons.storefront_rounded, label: tr(gu, 'Business', 'વ્યવસાય'), color: const Color(0xFF5E35B1), tint: const Color(0xFFEDE7F6), onTap: () => onTabSelected(2)),
                    FeatureButton(icon: Icons.more_horiz_rounded, label: tr(gu, 'More', 'વધુ'), color: AppPalette.softInk, tint: const Color(0xFFF4F1EC), onTap: () => _showNotice(context, tr(gu, 'More community services', 'વધુ સમાજ સેવાઓ'), tr(gu, 'Scholarships, volunteer groups, emergency help and trust documents are coming next.', 'શિષ્યવૃત્તિ, સ્વયંસેવક જૂથો, ઇમરજન્સી સહાય અને ટ્રસ્ટ દસ્તાવેજો ટૂંક સમયમાં આવશે.'))),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Recent Samaj News 📰', 'તાજા સમાજ સમાચાર 📰'), action: tr(gu, 'See all', 'બધા જુઓ')),
                const SizedBox(height: 10),
                SurfaceCard(
                  child: Row(
                    children: [
                      Container(width: 4, height: 64, decoration: BoxDecoration(color: AppPalette.saffron, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppPalette.saffronTint, borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.push_pin_rounded, color: AppPalette.saffron),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(gu, 'Trust election notice', 'ટ્રસ્ટ ચૂંટણી નોટિસ'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(tr(gu, 'Annual Trust elections on 29 Aug at Community Bhavan, Rajkot.', 'વાર્ષિક ટ્રસ્ટ ચૂંટણી 29 ઓગસ્ટે સમાજ ભવન, રાજકોટ ખાતે.'), style: const TextStyle(fontSize: 12, color: AppPalette.softInk, height: 1.32)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Upcoming events', 'આગામી કાર્યક્રમો'), action: tr(gu, 'See all', 'બધા જુઓ'), onAction: () => onTabSelected(3)),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _miniEvent(gu, '18', tr(gu, 'Jul', 'જુલાઈ'), tr(gu, 'Samuh Lagna Sammelan', 'સમૂહ લગ્ન સંમેલન'), tr(gu, 'Community Hall, Ahmedabad', 'સમાજ વાડી, અમદાવાદ')),
                      const Divider(height: 1),
                      _miniEvent(gu, '02', tr(gu, 'Aug', 'ઓગસ્ટ'), tr(gu, 'Blood Donation Camp', 'રક્તદાન કેમ્પ'), tr(gu, 'Darji Samaj Bhavan, Surat', 'દરજી સમાજ ભવન, સુરત')),
                      const Divider(height: 1),
                      _miniEvent(gu, '15', tr(gu, 'Aug', 'ઓગસ્ટ'), tr(gu, 'Youth Sports Meet', 'યુવા રમતગમત મહોત્સવ'), tr(gu, 'Rajkot Ground No. 3', 'રાજકોટ ગ્રાઉન્ડ નં. 3')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Featured families', 'મુખ્ય પરિવારો'), action: tr(gu, 'Explore', 'જુઓ')),
                const SizedBox(height: 10),
                SizedBox(
                  height: 154,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FamilyPreview(name: tr(gu, 'Chauhan Parivar', 'ચૌહાણ પરિવાર'), details: tr(gu, 'Vadodara · 6 generations', 'વડોદરા · 6 પેઢી'), count: tr(gu, '240 members', '240 સભ્યો'), color: AppPalette.saffron),
                      FamilyPreview(name: tr(gu, 'Parekh Parivar', 'પારેખ પરિવાર'), details: tr(gu, 'Surat · 5 generations', 'સુરત · 5 પેઢી'), count: tr(gu, '185 members', '185 સભ્યો'), color: AppPalette.forest),
                      FamilyPreview(name: tr(gu, 'Joshi Parivar', 'જોશી પરિવાર'), details: tr(gu, 'Rajkot · 7 generations', 'રાજકોટ · 7 પેઢી'), count: tr(gu, '312 members', '312 સભ્યો'), color: AppPalette.gold),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Community at a glance', 'સમાજ એક નજરે')),
                const SizedBox(height: 10),
                _StatsGrid(gujarati: gu),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Community Posts & Feed', 'સમાજ પોસ્ટ્સ અને ફીડ'), action: tr(gu, '20 posts', '20 પોસ્ટ્સ')),
                const SizedBox(height: 10),
                CommunityPost(
                  initials: 'RC',
                  name: displayName,
                  meta: tr(gu, '2 hours ago · Vadodara', '2 કલાક પહેલા · વડોદરા'),
                  badge: tr(gu, 'Announcement', 'જાહેરાત'),
                  text: tr(gu, 'Jay Shree Krishna to all samaj members! Welcome to our new digital platform KutumbSetu. Stay connected with family, business and events.', 'તમામ સમાજ બંધુઓને જય શ્રી કૃષ્ણ! આપણા નવા ડિજિટલ પ્લેટફોર્મ કુટુંબસેતુ પર આપનું સ્વાગત છે. પરિવાર, વ્યવસાય અને કાર્યક્રમો સાથે જોડાયેલા રહો.'),
                ),
                const SizedBox(height: 12),
                CommunityPost(
                  initials: 'SV',
                  name: tr(gu, 'Sonalben Vaghela', 'સોનલબેન વાઘેલા'),
                  meta: tr(gu, 'Yesterday · Nadiad', 'ગઈકાલે · નડિયાદ'),
                  badge: tr(gu, 'Community', 'સમાજ'),
                  text: tr(gu, 'Our school book collection drive begins this Sunday. Volunteers are welcome.', 'અમારી શાળા પુસ્તક સંગ્રહ ઝુંબેશ આ રવિવારથી શરૂ થાય છે. સ્વયંસેવકોનું સ્વાગત છે.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniEvent(bool gu, String day, String month, String title, String place) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: AppPalette.saffronTint, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.saffronDeep)), Text(month, style: const TextStyle(fontSize: 10, color: AppPalette.saffronDeep))]),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(place, style: const TextStyle(fontSize: 12, color: AppPalette.softInk))])),
        ],
      ),
    );
  }
}

class FamilyTreePage extends StatefulWidget {
  const FamilyTreePage({super.key, required this.gujarati});

  final bool gujarati;

  @override
  State<FamilyTreePage> createState() => _FamilyTreePageState();
}

class _FamilyTreePageState extends State<FamilyTreePage> {
  String _first = 'Rajeshbhai (Me)';
  String _second = 'Nikita (Cousin)';
  String? _result;

  @override
  Widget build(BuildContext context) {
    final gu = widget.gujarati;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _TreeHeader(gujarati: gu),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TreeStats(),
                const SizedBox(height: 16),
                SurfaceCard(
                  color: const Color(0xFFFFF9F2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr(gu, '🔗 Relationship Finder', '🔗 સંબંધ શોધક'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _relationshipMenu(_first, ['Rajeshbhai (Me)', 'Suresh Kaka', 'Kailash Foi'], (v) => setState(() => _first = v!))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(tr(gu, 'to', 'સુધી'), style: const TextStyle(color: AppPalette.softInk))),
                          Expanded(child: _relationshipMenu(_second, ['Nikita (Cousin)', 'Chhotalal (Dadaji)', 'Yash (Nephew)'], (v) => setState(() => _second = v!))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => setState(() => _result = tr(gu, 'Nikita is your first cousin.', 'નિકિતા તમારી પ્રથમ પિતરાઈ બહેન છે.')),
                        style: FilledButton.styleFrom(backgroundColor: AppPalette.saffron, minimumSize: const Size.fromHeight(42)),
                        icon: const Icon(Icons.hub_rounded, size: 18),
                        label: Text(tr(gu, 'Find connection', 'સંબંધ શોધો')),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 10),
                        Text(_result!, style: const TextStyle(color: AppPalette.forest, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(tr(gu, 'Interactive tree · pinch, drag & tap a member', 'ઇન્ટરેક્ટિવ વૃક્ષ · ઝૂમ કરો અને ટેપ કરો'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  height: 435,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPalette.divider)),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    minScale: .65,
                    maxScale: 2.2,
                    boundaryMargin: const EdgeInsets.all(120),
                    child: SizedBox(
                      width: 760,
                      height: 440,
                      child: Stack(
                        children: [
                          const Positioned.fill(child: CustomPaint(painter: _TreeLinesPainter())),
                          _treeNode(left: 90, top: 28, initials: 'CL', name: tr(gu, 'Chhotalal', 'છોટાલાલ'), relation: tr(gu, 'Dadaji', 'દાદાજી'), color: const Color(0xFF8D6E63)),
                          _treeNode(left: 220, top: 28, initials: 'SB', name: tr(gu, 'Savitaben', 'સવિતાબેન'), relation: tr(gu, 'Dadiji', 'દાદીજી'), color: const Color(0xFFAD8B73)),
                          _treeNode(left: 470, top: 28, initials: 'MB', name: tr(gu, 'Manilal', 'મણિલાલ'), relation: tr(gu, 'Nanaji', 'નાનાજી'), color: const Color(0xFF8D6E63)),
                          _treeNode(left: 600, top: 28, initials: 'JB', name: tr(gu, 'Jasuben', 'જસુબેન'), relation: tr(gu, 'Naniji', 'નાનીજી'), color: const Color(0xFFAD8B73)),
                          _treeNode(left: 275, top: 180, initials: 'DC', name: tr(gu, 'Dineshbhai', 'દિનેશભાઈ'), relation: tr(gu, 'Father', 'પિતાજી'), color: AppPalette.saffron),
                          _treeNode(left: 405, top: 180, initials: 'HC', name: tr(gu, 'Hemaben', 'હેમાબેન'), relation: tr(gu, 'Mother', 'માતાજી'), color: const Color(0xFFEF6C00)),
                          _treeNode(left: 80, top: 310, initials: 'NR', name: tr(gu, 'Nikita', 'નિકિતા'), relation: tr(gu, 'Cousin', 'બહેન'), color: AppPalette.forest),
                          _treeNode(left: 210, top: 310, initials: 'AB', name: tr(gu, 'Amitbhai', 'અમિતભાઈ'), relation: tr(gu, 'Brother', 'મોટો ભાઈ'), color: const Color(0xFF388E3C)),
                          _treeNode(left: 350, top: 310, initials: 'RC', name: tr(gu, 'Rajeshbhai', 'રાજેશભાઈ'), relation: tr(gu, 'You', 'તમે'), color: AppPalette.saffron, selected: true),
                          _treeNode(left: 480, top: 310, initials: 'PP', name: tr(gu, 'Priyaben', 'પ્રિયાબેન'), relation: tr(gu, 'Spouse', 'પત્ની'), color: AppPalette.peacock),
                          _treeNode(left: 610, top: 310, initials: 'VJ', name: tr(gu, 'Vishal', 'વિશાલ'), relation: tr(gu, 'Cousin', 'ભાઈ'), color: AppPalette.forest),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 7,
                  children: [
                    _legend(AppPalette.peacock, tr(gu, 'Marriage', 'લગ્ન')),
                    _legend(AppPalette.forest, tr(gu, 'Parent / child', 'માતા-પિતા / સંતાન')),
                    _legend(AppPalette.saffron, tr(gu, 'Family group', 'પરિવાર જૂથ')),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => _AddMemberSheet(gujarati: gu)),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(tr(gu, 'Request to add family member', 'પરિવાર સભ્ય ઉમેરવા વિનંતી')),
                  style: OutlinedButton.styleFrom(foregroundColor: AppPalette.forest, minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _relationshipMenu(String value, List<String> entries, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
      items: entries.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _treeNode({required double left, required double top, required String initials, required String name, required String relation, required Color color, bool selected = false}) {
    return Positioned(
      left: left,
      top: top,
      width: 104,
      child: GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name · $relation'))),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selected ? AppPalette.saffronDeep : Colors.white, width: selected ? 4 : 2), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 5)]),
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
            Text(relation, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppPalette.softInk)),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, color: AppPalette.softInk))]);
}

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key, required this.gujarati});

  final bool gujarati;

  @override
  Widget build(BuildContext context) {
    final gu = gujarati;
    final members = [
      ('KM', tr(gu, 'Kiranbhai Mistry', 'કિરણભાઈ મિસ્ત્રી'), tr(gu, 'Textile Merchant', 'ટેક્સટાઇલ મર્ચન્ટ'), tr(gu, 'Anand, Gujarat', 'આણંદ, ગુજરાત'), AppPalette.saffron),
      ('SV', tr(gu, 'Sonalben Vaghela', 'સોનલબેન વાઘેલા'), tr(gu, 'School Principal', 'શાળા આચાર્યા'), tr(gu, 'Nadiad, Gujarat', 'નડિયાદ, ગુજરાત'), AppPalette.peacock),
      ('PJ', tr(gu, 'Parthbhai Joshi', 'પાર્થભાઈ જોશી'), tr(gu, 'Software Engineer', 'સોફ્ટવેર એન્જિનિયર'), tr(gu, 'Bengaluru', 'બેંગલુરુ'), AppPalette.forest),
      ('RD', tr(gu, 'Rinaben Darji', 'રીનાબેન દરજી'), tr(gu, 'Boutique Owner', 'બુટીક ઓનર'), tr(gu, 'Surat, Gujarat', 'સુરત, ગુજરાત'), AppPalette.pink),
      ('MB', tr(gu, 'Meeraben Bavishi', 'મીરાબેન બાવિશી'), tr(gu, 'Doctor · MBBS', 'ડોક્ટર · એમ.બી.બી.એસ.'), tr(gu, 'Vadodara, Gujarat', 'વડોદરા, ગુજરાત'), const Color(0xFF00897B)),
    ];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Babariawad Darji Samaj', 'બાબરિયાવાડ દરજી સમાજ'),
            title: tr(gu, 'Community Directory', 'સમાજ સભ્ય યાદી'),
            subtitle: tr(gu, 'Search by name, village or profession…', 'નામ, ગામ અથવા વ્યવસાય શોધો…'),
            color: AppPalette.peacock,
            onLanguage: () {},
            onNotifications: () {},
            showActions: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _FilterChip(label: tr(gu, 'All', 'બધા'), active: true),
                _FilterChip(label: tr(gu, 'Village', 'ગામ')),
                _FilterChip(label: tr(gu, 'City', 'શહેર')),
                _FilterChip(label: tr(gu, 'Profession', 'વ્યવસાય')),
                _FilterChip(label: tr(gu, 'Education', 'અભ્યાસ')),
              ]),
              const SizedBox(height: 14),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(children: [for (var i = 0; i < members.length; i++) ...[MemberTile(initials: members[i].$1, name: members[i].$2, occupation: members[i].$3, city: members[i].$4, color: members[i].$5), if (i != members.length - 1) const Divider(height: 1, indent: 70)]),
              ),
              const SizedBox(height: 24),
              SectionHeading(title: tr(gu, 'Business directory', 'બિઝનેસ ડિરેક્ટરી'), action: tr(gu, 'View all', 'બધા જુઓ')),
              const SizedBox(height: 10),
              SizedBox(
                height: 142,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  BusinessPreview(name: tr(gu, 'Shree Textiles', 'શ્રી ટેક્સટાઇલ્સ'), details: tr(gu, 'Surat · Fabric & Tailoring', 'સુરત · કાપડ અને ટેલરિંગ'), color: const Color(0xFF5E35B1)),
                  BusinessPreview(name: tr(gu, 'Bavishi Clinic', 'બાવિશી ક્લિનિક'), details: tr(gu, 'Vadodara · Healthcare', 'વડોદરા · હેલ્થકેર'), color: const Color(0xFF00897B)),
                  BusinessPreview(name: tr(gu, 'Riya Boutique', 'રિયા બુટીક'), details: tr(gu, 'Rajkot · Fashion', 'રાજકોટ · ફેશન'), color: AppPalette.pink),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.gujarati});

  final bool gujarati;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  int _segment = 0;
  final Set<String> _rsvps = {};

  @override
  Widget build(BuildContext context) {
    final gu = widget.gujarati;
    final events = [
      (tr(gu, 'Samuh Lagna Sammelan 2026', 'સમૂહ લગ્ન સંમેલન 2026'), tr(gu, '18 Jul, 10:00 AM', '18 જુલાઈ, 10:00 AM'), tr(gu, 'Ahmedabad', 'અમદાવાદ'), tr(gu, 'Festival', 'મહોત્સવ'), AppPalette.saffron, '340'),
      (tr(gu, 'Blood Donation Camp', 'રક્તદાન કેમ્પ'), tr(gu, '02 Aug, 9:00 AM', '02 ઓગસ્ટ, 9:00 AM'), tr(gu, 'Surat', 'સુરત'), tr(gu, 'Health', 'આરોગ્ય'), AppPalette.pink, '128'),
      (tr(gu, 'Youth Sports Meet', 'યુવા સ્પોર્ટ્સ મીટ'), tr(gu, '15 Aug, 7:30 AM', '15 ઓગસ્ટ, 7:30 AM'), tr(gu, 'Rajkot', 'રાજકોટ'), tr(gu, 'Sports', 'રમતગમત'), AppPalette.peacock, '96'),
      (tr(gu, 'Samaj Trust · Annual Election', 'સમાજ ટ્રસ્ટ · વાર્ષિક ચૂંટણી'), tr(gu, '29 Aug, 5:00 PM', '29 ઓગસ્ટ, 5:00 PM'), tr(gu, 'Rajkot', 'રાજકોટ'), tr(gu, 'Meeting', 'મીટિંગ'), AppPalette.forest, '210'),
    ];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Community', 'સમાજ'),
            title: tr(gu, 'Events & Gatherings', 'કાર્યક્રમો અને સંમેલનો'),
            subtitle: tr(gu, 'Celebrate, serve and connect together', 'ઉજવણી કરો, સેવા કરો અને જોડાઓ'),
            onLanguage: () {},
            onNotifications: () {},
            showActions: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _SegmentButton(label: tr(gu, 'Upcoming', 'આગામી'), selected: _segment == 0, onTap: () => setState(() => _segment = 0)),
                const SizedBox(width: 8),
                _SegmentButton(label: tr(gu, 'Past', 'ભૂતકાળના'), selected: _segment == 1, onTap: () => setState(() => _segment = 1)),
                const SizedBox(width: 8),
                _SegmentButton(label: tr(gu, 'My RSVPs', 'મારા RSVP'), selected: _segment == 2, onTap: () => setState(() => _segment = 2)),
              ]),
              const SizedBox(height: 16),
              for (final event in events.where((e) => _segment != 2 || _rsvps.contains(e.$1))) ...[
                EventCard(
                  title: event.$1,
                  date: event.$2,
                  city: event.$3,
                  category: event.$4,
                  color: event.$5,
                  attending: event.$6,
                  going: _rsvps.contains(event.$1),
                  onRsvp: () => setState(() => _rsvps.add(event.$1)),
                  gujarati: gu,
                ),
                const SizedBox(height: 14),
              ],
              if (_segment == 2 && _rsvps.isEmpty)
                Padding(padding: const EdgeInsets.only(top: 50), child: Center(child: Text(tr(gu, 'No RSVPs yet. Tap RSVP on an event.', 'હજુ કોઈ RSVP નથી. કાર્યક્રમ પર RSVP દબાવો.'), style: const TextStyle(color: AppPalette.softInk)))),
            ]),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.displayName,
    required this.familyId,
    required this.gujarati,
    required this.onLanguageChanged,
    required this.onLogout,
    required this.onOpenTree,
  });

  final String displayName;
  final String familyId;
  final bool gujarati;
  final VoidCallback onLanguageChanged;
  final VoidCallback onLogout;
  final VoidCallback onOpenTree;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _profileTab = 0;

  @override
  Widget build(BuildContext context) {
    final gu = widget.gujarati;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 142,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppPalette.saffron, AppPalette.saffronDeep], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          ),
          Transform.translate(
            offset: const Offset(0, -45),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _InitialAvatar(initials: _initials(widget.displayName), color: AppPalette.saffron, size: 88, border: 4),
                  const SizedBox(width: 13),
                  Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.displayName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Row(children: [const Icon(Icons.verified_rounded, size: 16, color: AppPalette.peacock), const SizedBox(width: 4), Text(tr(gu, 'Verified member', 'પ્રમાણિત સભ્ય'), style: const TextStyle(fontSize: 12, color: AppPalette.peacock, fontWeight: FontWeight.w700))])]))),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 7, children: [_ProfileTag(tr(gu, 'Chauhan Parivar', 'ચૌહાણ પરિવાર')), _ProfileTag(tr(gu, 'Vadodara', 'વડોદરા')), _ProfileTag(tr(gu, 'Software Architect', 'સોફ્ટવેર આર્કિટેક્ટ'))]),
                const SizedBox(height: 18),
                _CommunityIdCard(familyId: widget.familyId, gujarati: gu),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF4F1EC), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    _profileToggle(0, tr(gu, 'About', 'માહિતી')),
                    _profileToggle(1, tr(gu, 'Family', 'પરિવાર')),
                    _profileToggle(2, tr(gu, 'Contributions', 'યોગદાન')),
                  ]),
                ),
                const SizedBox(height: 14),
                if (_profileTab == 0) _about(gu),
                if (_profileTab == 1) _family(gu),
                if (_profileTab == 2) _contributions(gu),
                const SizedBox(height: 20),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    ListTile(leading: const Icon(Icons.language_rounded, color: AppPalette.saffron), title: Text(tr(gu, 'Language', 'ભાષા')), subtitle: Text(gu ? 'ગુજરાતી' : 'English'), trailing: const Icon(Icons.chevron_right_rounded), onTap: widget.onLanguageChanged),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.logout_rounded, color: AppPalette.pink), title: Text(tr(gu, 'Sign out', 'સાઇન આઉટ')), onTap: widget.onLogout),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileToggle(int index, String label) {
    final active = _profileTab == index;
    return Expanded(child: TextButton(onPressed: () => setState(() => _profileTab = index), style: TextButton.styleFrom(foregroundColor: active ? Colors.white : AppPalette.softInk, backgroundColor: active ? AppPalette.saffron : Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))));
  }

  Widget _about(bool gu) {
    final rows = [
      (tr(gu, 'Occupation', 'વ્યવસાય'), tr(gu, 'Software Architect', 'સોફ્ટવેર આર્કિટેક્ટ')),
      (tr(gu, 'Education', 'અભ્યાસ'), tr(gu, 'B.E. Computer Engineering', 'બી.ઈ. કમ્પ્યુટર એન્જિનિયરિંગ')),
      (tr(gu, 'Village', 'વતન / ગામ'), tr(gu, 'Karamsad', 'કરમસદ')),
      (tr(gu, 'City', 'હાલ રહેઠાણ'), tr(gu, 'Vadodara, Gujarat', 'વડોદરા, ગુજરાત')),
      (tr(gu, 'Blood group', 'બ્લડ ગ્રુપ'), 'B+'),
      (tr(gu, 'Contact', 'સંપર્ક'), '+91 98••• •••42'),
    ];
    return SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < rows.length; i++) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Expanded(child: Text(rows[i].$1, style: const TextStyle(color: AppPalette.softInk, fontSize: 13))), Expanded(child: Text(rows[i].$2, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))])), if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16)]));
  }

  Widget _family(bool gu) {
    final family = [('DC', tr(gu, 'Dineshbhai Chauhan', 'દિનેશભાઈ ચૌહાણ'), tr(gu, 'Father', 'પિતાજી'), AppPalette.saffron), ('HC', tr(gu, 'Hemaben Chauhan', 'હેમાબેન ચૌહાણ'), tr(gu, 'Mother', 'માતાજી'), const Color(0xFFEF6C00)), ('PP', tr(gu, 'Priyaben Chauhan', 'પ્રિયાબેન ચૌહાણ'), tr(gu, 'Spouse', 'પત્ની'), AppPalette.peacock), ('AB', tr(gu, 'Amitbhai Chauhan', 'અમિતભાઈ ચૌહાણ'), tr(gu, 'Brother', 'મોટો ભાઈ'), AppPalette.forest)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionHeading(title: tr(gu, 'Family tree preview', 'કુટુંબ વૃક્ષ ઝલક'), action: tr(gu, 'Open tree', 'વૃક્ષ ખોલો'), onAction: widget.onOpenTree), const SizedBox(height: 8), SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < family.length; i++) ...[MemberTile(initials: family[i].$1, name: family[i].$2, occupation: family[i].$3, city: '', color: family[i].$4, compact: true), if (i != family.length - 1) const Divider(height: 1, indent: 70)]]))]);
  }

  Widget _contributions(bool gu) {
    final rows = [('🏆', tr(gu, 'Scholarship Fund', 'શિષ્યવૃત્તિ ફંડ'), tr(gu, '₹25,000 donated', '₹25,000 દાન')), ('🎓', tr(gu, 'Mentorship', 'માર્ગદર્શન'), tr(gu, '6 students guided', '6 વિદ્યાર્થીઓને માર્ગદર્શન')), ('🩸', tr(gu, 'Blood camps', 'રક્તદાન કેમ્પ'), tr(gu, '4 camps organized', '4 કેમ્પનું આયોજન'))];
    return SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < rows.length; i++) ...[ListTile(leading: Text(rows[i].$1, style: const TextStyle(fontSize: 21)), title: Text(rows[i].$2, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: Text(rows[i].$3, style: const TextStyle(fontSize: 12, color: AppPalette.forest, fontWeight: FontWeight.w700)), if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16)]]));
  }
}

class MatrimonyPage extends StatefulWidget {
  const MatrimonyPage({super.key, required this.gujarati, required this.onLanguageChanged});

  final bool gujarati;
  final VoidCallback onLanguageChanged;

  @override
  State<MatrimonyPage> createState() => _MatrimonyPageState();
}

class _MatrimonyPageState extends State<MatrimonyPage> {
  String _filter = 'All';
  late bool _gujarati;

  @override
  void initState() {
    super.initState();
    _gujarati = widget.gujarati;
  }

  void _changeLanguage() {
    setState(() => _gujarati = !_gujarati);
    widget.onLanguageChanged();
  }

  @override
  Widget build(BuildContext context) {
    final gu = _gujarati;
    final profiles = [
      ('NC', tr(gu, 'Nikita Chauhan', 'નિકિતા ચૌહાણ'), tr(gu, '26 · Marketing Manager', '26 · માર્કેટિંગ મેનેજર'), tr(gu, 'Ahmedabad', 'અમદાવાદ'), AppPalette.pink),
      ('KP', tr(gu, 'Kevin Parekh', 'કેવિન પારેખ'), tr(gu, '29 · Civil Engineer', '29 · સિવિલ એન્જિનિયર'), tr(gu, 'Surat', 'સુરત'), AppPalette.peacock),
      ('PT', tr(gu, 'Priya Trivedi', 'પ્રિયા ત્રિવેદી'), tr(gu, '24 · Doctor, MBBS', '24 · ડોક્ટર, એમ.બી.બી.એસ.'), tr(gu, 'Rajkot', 'રાજકોટ'), AppPalette.forest),
      ('RJ', tr(gu, 'Rohan Joshi', 'રોહન જોશી'), tr(gu, '31 · Chartered Accountant', '31 · ચાર્ટર્ડ એકાઉન્ટન્ટ'), tr(gu, 'Vadodara', 'વડોદરા'), AppPalette.gold),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(padding: EdgeInsets.zero, children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Matrimony', 'લગ્ન વિષયક'),
            title: tr(gu, 'Find a match', 'યોગ્ય જીવનસાથી શોધો'),
            subtitle: tr(gu, 'Search by age, city or profession…', 'ઉંમર, શહેર અથવા વ્યવસાય શોધો…'),
            color: AppPalette.pink,
            onLanguage: _changeLanguage,
            onNotifications: () {},
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final label in ['All', 'Age', 'City', 'Education', 'Profession']) Padding(padding: const EdgeInsets.only(right: 8), child: _FilterChip(label: tr(gu, label, _guFilter(label)), active: _filter == label, onTap: () => setState(() => _filter = label)))])),
              const SizedBox(height: 12),
              Text(tr(gu, '🎥 Profiles with a family introduction video are marked', '🎥 ફેમિલી ઇન્ટ્રો વિડિયો ધરાવતી પ્રોફાઇલ ચિહ્નિત છે'), style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .67),
                itemBuilder: (context, index) => MatchCard(initials: profiles[index].$1, name: profiles[index].$2, details: profiles[index].$3, city: profiles[index].$4, color: profiles[index].$5, onTap: () => _openProfile(context, profiles[index].$2, gu)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  String _guFilter(String english) {
    switch (english) {
      case 'All': return 'બધા';
      case 'Age': return 'ઉંમર';
      case 'City': return 'શહેર';
      case 'Education': return 'અભ્યાસ';
      default: return 'વ્યવસાય';
    }
  }

  void _openProfile(BuildContext context, String name, bool gu) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(tr(gu, 'This profile is verified by the family. Send interest to begin a family-guided introduction.', 'આ પ્રોફાઇલ પરિવાર દ્વારા પ્રમાણિત છે. પરિવારના માર્ગદર્શન સાથે પરિચય શરૂ કરવા રસ મોકલો.'), style: const TextStyle(color: AppPalette.softInk, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () { Navigator.pop(sheetContext); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest sent to the family.', 'પરિવારને રસ મોકલવામાં આવ્યો.')))); }, style: FilledButton.styleFrom(backgroundColor: AppPalette.pink, minimumSize: const Size.fromHeight(48)), icon: const Icon(Icons.favorite_rounded), label: Text(tr(gu, 'Send interest', 'રસ મોકલો'))),
        ]),
      ),
    );
  }
}

class _SaffronHeader extends StatelessWidget {
  const _SaffronHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onLanguage,
    required this.onNotifications,
    this.color = AppPalette.saffron,
    this.leading,
    this.showActions = true,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onLanguage;
  final VoidCallback onNotifications;
  final Widget? leading;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .2)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(children: [
        const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _PatternPainter()))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (leading != null) Padding(padding: const EdgeInsets.only(right: 6), child: leading!),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow, style: const TextStyle(color: Colors.white, fontSize: 12.5)), const SizedBox(height: 3), Text(title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))])),
              if (showActions) ...[
                _roundIcon(Icons.language_rounded, onLanguage),
                const SizedBox(width: 7),
                _roundIcon(Icons.notifications_none_rounded, onNotifications, dot: true),
              ],
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [const Icon(Icons.search_rounded, color: AppPalette.softInk, size: 20), const SizedBox(width: 9), Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppPalette.softInk)))]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap, {bool dot = false}) => Stack(clipBehavior: Clip.none, children: [InkWell(onTap: onTap, borderRadius: BorderRadius.circular(25), child: Ink(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.28))), child: Icon(icon, color: Colors.white, size: 19))), if (dot) const Positioned(top: 2, right: 2, child: CircleAvatar(radius: 4, backgroundColor: Color(0xFFC2185B)))]);
}

class _TreeHeader extends StatelessWidget {
  const _TreeHeader({required this.gujarati});

  final bool gujarati;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppPalette.divider))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(gujarati, '🌳 Family Tree', '🌳 કુટુંબ વૃક્ષ'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(tr(gujarati, 'Chauhan Parivar · Vadodara lineage', 'ચૌહાણ પરિવાર · વડોદરા વંશાવલી'), style: const TextStyle(fontSize: 12, color: AppPalette.softInk))])), Container(width: 38, height: 38, decoration: const BoxDecoration(color: AppPalette.forestTint, shape: BoxShape.circle), child: const Icon(Icons.search_rounded, color: AppPalette.forest))]),
        const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _FilterChip(label: tr(gujarati, 'Full Tree', 'સંપૂર્ણ વૃક્ષ'), active: true),
          const SizedBox(width: 8), _FilterChip(label: tr(gujarati, 'My Family', 'મારો પરિવાર')),
          const SizedBox(width: 8), _FilterChip(label: tr(gujarati, "Father's Side", 'પિતૃ પક્ષ')),
          const SizedBox(width: 8), _FilterChip(label: tr(gujarati, "Mother's Side", 'માતૃ પક્ષ')),
        ])),
      ]),
    );
  }
}

class FeatureButton extends StatelessWidget {
  const FeatureButton({super.key, required this.icon, required this.label, required this.color, required this.tint, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 25)), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.12))]),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), if (action != null) TextButton(onPressed: onAction, style: TextButton.styleFrom(foregroundColor: AppPalette.saffron, padding: EdgeInsets.zero, minimumSize: const Size(0, 30)), child: Text(action!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]);
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color = Colors.white});

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.divider), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3))]), child: child);
}

class FamilyPreview extends StatelessWidget {
  const FamilyPreview({super.key, required this.name, required this.details, required this.count, required this.color});
  final String name;
  final String details;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: 178, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.divider)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 78, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .3)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), alignment: Alignment.topRight, padding: const EdgeInsets.all(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 9.5))),), Padding(padding: const EdgeInsets.fromLTRB(11, 9, 11, 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]))]));
}

class BusinessPreview extends StatelessWidget {
  const BusinessPreview({super.key, required this.name, required this.details, required this.color});
  final String name;
  final String details;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 178, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.divider)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 68, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .35)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), alignment: Alignment.topRight, padding: const EdgeInsets.all(8), child: const CircleAvatar(radius: 13, backgroundColor: Colors.white, child: Text('★', style: TextStyle(color: AppPalette.gold, fontSize: 15))),), Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]))]));
}

class CommunityPost extends StatelessWidget {
  const CommunityPost({super.key, required this.initials, required this.name, required this.meta, required this.badge, required this.text});
  final String initials;
  final String name;
  final String meta;
  final String badge;
  final String text;
  @override
  Widget build(BuildContext context) => SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [_InitialAvatar(initials: initials, color: AppPalette.saffron, size: 40), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(meta, style: const TextStyle(fontSize: 11, color: AppPalette.softInk))])), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: AppPalette.saffronTint, borderRadius: BorderRadius.circular(9)), child: Text(badge, style: const TextStyle(color: AppPalette.saffronDeep, fontSize: 10, fontWeight: FontWeight.w700)))]), const SizedBox(height: 12), Text(text, style: const TextStyle(fontSize: 13, height: 1.4)), const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 7), const Row(children: [Expanded(child: _PostAction(icon: Icons.favorite_border_rounded, label: 'Like')), Expanded(child: _PostAction(icon: Icons.mode_comment_outlined, label: 'Comment')), Expanded(child: _PostAction(icon: Icons.share_outlined, label: 'Share'))]) ]));
}

class _PostAction extends StatelessWidget {
  const _PostAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label action recorded'))), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 17, color: AppPalette.softInk), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, color: AppPalette.softInk))])));
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.gujarati});
  final bool gujarati;
  @override
  Widget build(BuildContext context) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .96, children: [_StatBox(number: '1,240', label: tr(gujarati, 'Families', 'પરિવારો')), _StatBox(number: '18.6K', label: tr(gujarati, 'Members', 'સભ્યો')), _StatBox(number: '86', label: tr(gujarati, 'Villages', 'ગામો')), _StatBox(number: '9', label: tr(gujarati, 'Generations', 'પેઢીઓ'))]);
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.number, required this.label});
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppPalette.divider)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(number, style: const TextStyle(fontWeight: FontWeight.w800, color: AppPalette.saffronDeep, fontSize: 15)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppPalette.softInk))]));
}

class _TreeStats extends StatelessWidget {
  const _TreeStats();
  @override
  Widget build(BuildContext context) => Row(children: const [Expanded(child: _TreeStat(number: '240', label: 'Total members')), Expanded(child: _TreeStat(number: '6', label: 'Generations')), Expanded(child: _TreeStat(number: '1892', label: 'Oldest record')), Expanded(child: _TreeStat(number: '14', label: 'Added this month'))]);
}

class _TreeStat extends StatelessWidget {
  const _TreeStat({required this.number, required this.label});
  final String number;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [Text(number, style: const TextStyle(fontWeight: FontWeight.w800, color: AppPalette.forest, fontSize: 16)), const SizedBox(height: 2), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppPalette.softInk, height: 1.08))]);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.active = false, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: active ? AppPalette.saffron : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? AppPalette.saffron : AppPalette.divider)), child: Text(label, style: TextStyle(fontSize: 11.5, color: active ? Colors.white : AppPalette.softInk, fontWeight: FontWeight.w700))));
}

class MemberTile extends StatelessWidget {
  const MemberTile({super.key, required this.initials, required this.name, required this.occupation, required this.city, required this.color, this.compact = false});
  final String initials;
  final String name;
  final String occupation;
  final String city;
  final Color color;
  final bool compact;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), leading: _InitialAvatar(initials: initials, color: color, size: 43), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(occupation, style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), if (city.isNotEmpty) Text('📍 $city', style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]), trailing: compact ? null : IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message request sent to $name'))), icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppPalette.peacock)));
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.title, required this.date, required this.city, required this.category, required this.color, required this.attending, required this.going, required this.onRsvp, required this.gujarati});
  final String title;
  final String date;
  final String city;
  final String category;
  final Color color;
  final String attending;
  final bool going;
  final VoidCallback onRsvp;
  final bool gujarati;
  @override
  Widget build(BuildContext context) => SurfaceCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 76, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .35)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), padding: const EdgeInsets.all(11), alignment: Alignment.topLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(10)), child: Text(category, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10.5)))), Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 6), Wrap(spacing: 14, runSpacing: 4, children: [Text('📅 $date', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), Text('📍 $city', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk))]), const SizedBox(height: 12), Row(children: [Expanded(child: Text('👥 $attending ${tr(gujarati, 'attending', 'સભ્યો હાજર')}', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk))), FilledButton(onPressed: going ? null : onRsvp, style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: const Size(0, 36)), child: Text(going ? tr(gujarati, 'Going ✓', 'હાજર ✓') : tr(gujarati, 'RSVP', 'RSVP'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))])]))]));
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: TextButton(onPressed: onTap, style: TextButton.styleFrom(foregroundColor: selected ? Colors.white : AppPalette.saffronDeep, backgroundColor: selected ? AppPalette.saffron : AppPalette.saffronTint, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))));
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initials, required this.color, required this.size, this.border = 0});
  final String initials;
  final Color color;
  final double size;
  final double border;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, alignment: Alignment.center, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: border == 0 ? null : Border.all(color: Colors.white, width: border), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 6)]), child: Text(initials, style: TextStyle(color: Colors.white, fontSize: size * .28, fontWeight: FontWeight.w800)));
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: AppPalette.saffronTint, borderRadius: BorderRadius.circular(10)), child: Text(label, style: const TextStyle(fontSize: 10.5, color: AppPalette.saffronDeep, fontWeight: FontWeight.w700)));
}

class _CommunityIdCard extends StatelessWidget {
  const _CommunityIdCard({required this.familyId, required this.gujarati});
  final String familyId;
  final bool gujarati;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF155218)]), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x262E7D32), blurRadius: 16, offset: Offset(0, 6))]), child: Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('KUTUMB\nSETU', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, height: 1.0)), SizedBox(height: 16), Text('Digital Community ID', style: TextStyle(color: Color(0xDFFFFFFF), fontSize: 10.5))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(width: 43, height: 43, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)), child: const Icon(Icons.qr_code_2_rounded, color: AppPalette.forest, size: 34)), const SizedBox(height: 12), Text(familyId, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(gujarati ? 'બાબરિયાવાડ દરજી સમાજ' : 'Babariawad Darji Samaj', style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 10))])])));
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.initials, required this.name, required this.details, required this.city, required this.color, required this.onTap});
  final String initials;
  final String name;
  final String details;
  final String city;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppPalette.divider)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .32)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(17))), alignment: Alignment.center, child: Stack(alignment: Alignment.center, children: [Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)), Positioned(right: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(7)), child: const Text('🎥 0:30', style: TextStyle(color: Colors.white, fontSize: 9)))])])), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)), const SizedBox(height: 3), Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk)), const SizedBox(height: 4), Text('📍 $city', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]))])));
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppPalette.saffron, AppPalette.saffronDeep]), borderRadius: BorderRadius.circular(size * .3), boxShadow: const [BoxShadow(color: Color(0x33F57C00), blurRadius: 18, offset: Offset(0, 7))]), child: Stack(alignment: Alignment.center, children: [const Icon(Icons.account_tree_rounded, color: Colors.white, size: 40), Positioned(bottom: 9, child: Text('KS', style: TextStyle(color: Colors.white.withOpacity(.9), fontWeight: FontWeight.w900, fontSize: 11)))]));
}

class _AddMemberSheet extends StatelessWidget {
  const _AddMemberSheet({required this.gujarati});
  final bool gujarati;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(gujarati, 'Add family member', 'નવા સભ્ય ઉમેરો'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(tr(gujarati, 'Family-head or administrator approval is required. Submit the person’s name and relationship to start the review.', 'પરિવારના મુખ્ય સભ્ય અથવા એડમિનની મંજૂરી જરૂરી છે. વ્યક્તિનું નામ અને સંબંધ આપી સમીક્ષા શરૂ કરો.'), style: const TextStyle(color: AppPalette.softInk, height: 1.4)), const SizedBox(height: 15), FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gujarati, 'Request form opened.', 'વિનંતી ફોર્મ ખોલાયું.')))); }, style: FilledButton.styleFrom(backgroundColor: AppPalette.forest, minimumSize: const Size.fromHeight(46)), child: Text(tr(gujarati, 'Start request', 'વિનંતી શરૂ કરો')))]));
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(.13)..style = PaintingStyle.stroke..strokeWidth = 1.3;
    for (double x = -10; x < size.width + 30; x += 48) {
      for (double y = 2; y < size.height; y += 48) {
        canvas.drawCircle(Offset(x + (y ~/ 48 % 2) * 20, y), 14, paint);
        canvas.drawCircle(Offset(x + (y ~/ 48 % 2) * 20, y), 5, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TreeLinesPainter extends CustomPainter {
  const _TreeLinesPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final marriage = Paint()..color = AppPalette.peacock..strokeWidth = 2.5;
    final descent = Paint()..color = AppPalette.forest..strokeWidth = 2.2;
    final group = Paint()..color = AppPalette.saffron..strokeWidth = 1.6;
    canvas.drawLine(const Offset(140, 52), const Offset(244, 52), marriage);
    canvas.drawLine(const Offset(520, 52), const Offset(624, 52), marriage);
    canvas.drawLine(const Offset(325, 203), const Offset(429, 203), marriage);
    canvas.drawLine(const Offset(400, 222), const Offset(400, 274), descent);
    canvas.drawLine(const Offset(400, 274), const Offset(130, 274), descent);
    canvas.drawLine(const Offset(400, 274), const Offset(660, 274), descent);
    final path = Path()..moveTo(140, 128)..lineTo(140, 150)..lineTo(455, 150)..lineTo(455, 180);
    canvas.drawPath(path, descent);
    final groupPath = Path()..moveTo(130, 298)..lineTo(130, 287)..lineTo(660, 287)..lineTo(660, 298);
    canvas.drawPath(groupPath, group);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return 'KS';
  if (words.length == 1) return words.first.substring(0, min(2, words.first.length)).toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
