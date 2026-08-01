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
                        label: Text(gu ? 'English' : 'α¬ùα½üα¬£α¬░α¬╛α¬ñα½Ç'),
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
                      tr(gu, 'Babariawad Darji Samaj', 'α¬¼α¬╛α¬¼α¬░α¬┐α¬»α¬╛α¬╡α¬╛α¬í α¬ªα¬░α¬£α½Ç α¬╕α¬«α¬╛α¬£'),
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
                        'α¬åα¬¬α¬úα¬╛ α¬¬α¬░α¬┐α¬╡α¬╛α¬░, α¬╕α¬«α¬╛α¬£ α¬àα¬¿α½ç α¬╕α¬éα¬¼α¬éα¬ºα½ï α¬«α¬╛α¬ƒα½ç α¬Åα¬ò α¬£ α¬╕α½ìα¬Ñα¬│.',
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
                                  ? tr(gu, 'Create your community account', 'α¬ñα¬«α¬╛α¬░α½üα¬é α¬╕α¬«α¬╛α¬£ α¬ûα¬╛α¬ñα½üα¬é α¬¼α¬¿α¬╛α¬╡α½ï')
                                  : tr(gu, 'Welcome back', 'α¬¬α¬╛α¬¢α¬╛ α¬åα¬╡α¬òα¬╛α¬░'),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _signUp
                                  ? tr(gu, 'Your Family ID will be created after sign up.', 'α¬╕α¬╛α¬çα¬¿ α¬àα¬¬ α¬¬α¬¢α½Ç α¬ñα¬«α¬╛α¬░α½üα¬é α¬½α½çα¬«α¬┐α¬▓α½Ç ID α¬¼α¬¿α¬╢α½ç.')
                                  : tr(gu, 'Sign in to your family and community.', 'α¬ñα¬«α¬╛α¬░α¬╛ α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬àα¬¿α½ç α¬╕α¬«α¬╛α¬£α¬«α¬╛α¬é α¬╕α¬╛α¬çα¬¿ α¬çα¬¿ α¬òα¬░α½ï.'),
                              style: const TextStyle(color: AppPalette.softInk, height: 1.35),
                            ),
                            const SizedBox(height: 20),
                            if (_signUp) ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: tr(gu, 'Full name', 'α¬¬α½éα¬░α½üα¬é α¬¿α¬╛α¬«'),
                                  prefixIcon: const Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) => value == null || value.trim().length < 2
                                    ? tr(gu, 'Please enter your name', 'α¬òα½âα¬¬α¬╛ α¬òα¬░α½Çα¬¿α½ç α¬ñα¬«α¬╛α¬░α½üα¬é α¬¿α¬╛α¬« α¬▓α¬ûα½ï')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _family,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: tr(gu, 'Family / surname', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ / α¬àα¬ƒα¬ò'),
                                  prefixIcon: const Icon(Icons.account_tree_outlined),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty
                                    ? tr(gu, 'Please enter family or surname', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬àα¬Ñα¬╡α¬╛ α¬àα¬ƒα¬ò α¬▓α¬ûα½ï')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ] else
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: tr(gu, 'Name or Family ID', 'α¬¿α¬╛α¬« α¬àα¬Ñα¬╡α¬╛ α¬½α½çα¬«α¬┐α¬▓α½Ç ID'),
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                              ),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: tr(gu, 'Mobile number', 'α¬«α½ïα¬¼α¬╛α¬çα¬▓ α¬¿α¬éα¬¼α¬░'),
                                prefixText: '+91  ',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              validator: (value) => value == null || value.replaceAll(RegExp(r'\D'), '').length < 10
                                  ? tr(gu, 'Enter a valid 10-digit number', '10 α¬àα¬éα¬òα¬¿α½ï α¬«α¬╛α¬¿α½ìα¬» α¬¿α¬éα¬¼α¬░ α¬▓α¬ûα½ï')
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                labelText: tr(gu, 'Password', 'α¬¬α¬╛α¬╕α¬╡α¬░α½ìα¬í'),
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (value) => value == null || value.length < 4
                                  ? tr(gu, 'Use at least 4 characters', 'α¬ôα¬¢α¬╛α¬«α¬╛α¬é α¬ôα¬¢α¬╛ 4 α¬àα¬òα½ìα¬╖α¬░α½ï α¬╡α¬╛α¬¬α¬░α½ï')
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
                                _signUp ? tr(gu, 'Create account & Family ID', 'α¬ûα¬╛α¬ñα½üα¬é α¬àα¬¿α½ç α¬½α½çα¬«α¬┐α¬▓α½Ç ID α¬¼α¬¿α¬╛α¬╡α½ï') : tr(gu, 'Sign in', 'α¬╕α¬╛α¬çα¬¿ α¬çα¬¿ α¬òα¬░α½ï'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr(
                                gu,
                                'For the prototype, any valid mobile number and password work.',
                                'α¬¬α½ìα¬░α½ïα¬ƒα½ïα¬ƒα¬╛α¬çα¬¬ α¬«α¬╛α¬ƒα½ç α¬òα½ïα¬êα¬¬α¬ú α¬«α¬╛α¬¿α½ìα¬» α¬«α½ïα¬¼α¬╛α¬çα¬▓ α¬¿α¬éα¬¼α¬░ α¬àα¬¿α½ç α¬¬α¬╛α¬╕α¬╡α¬░α½ìα¬í α¬Üα¬╛α¬▓α¬╢α½ç.',
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
          _toggleButton(context, false, tr(gujarati, 'Sign in', 'α¬╕α¬╛α¬çα¬¿ α¬çα¬¿')),
          _toggleButton(context, true, tr(gujarati, 'Sign up', 'α¬╕α¬╛α¬çα¬¿ α¬àα¬¬')),
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
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: tr(widget.gujarati, 'Home', 'α¬╣α½ïα¬«')),
          NavigationDestination(icon: const Icon(Icons.account_tree_outlined), selectedIcon: const Icon(Icons.account_tree_rounded), label: tr(widget.gujarati, 'Tree', 'α¬╡α½âα¬òα½ìα¬╖')),
          NavigationDestination(icon: const Icon(Icons.groups_2_outlined), selectedIcon: const Icon(Icons.groups_2_rounded), label: tr(widget.gujarati, 'Community', 'α¬╕α¬«α¬╛α¬£')),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month_rounded), label: tr(widget.gujarati, 'Events', 'α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: tr(widget.gujarati, 'Profile', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓')),
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
            eyebrow: tr(gu, 'Jay Shree Krishna ≡ƒÖÅ', 'α¬£α¬» α¬╢α½ìα¬░α½Ç α¬òα½âα¬╖α½ìα¬ú ≡ƒÖÅ'),
            title: displayName,
            subtitle: tr(gu, 'Search families, villages, membersΓÇª', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░, α¬ùα¬╛α¬«, α¬╕α¬¡α½ìα¬»α½ï α¬╢α½ïα¬ºα½ïΓÇª'),
            onLanguage: onLanguageChanged,
            onNotifications: () => _showNotice(
              context,
              tr(gu, 'Notifications', 'α¬╕α½éα¬Üα¬¿α¬╛α¬ô'),
              tr(gu, 'Your family tree update has been approved. The Blood Donation Camp is in 7 days.', 'α¬ñα¬«α¬╛α¬░α½üα¬é α¬½α½çα¬«α¬┐α¬▓α½Ç α¬ƒα½ìα¬░α½Ç α¬àα¬¬α¬íα½çα¬ƒ α¬«α¬éα¬£α½éα¬░ α¬Ñα¬»α½üα¬é α¬¢α½ç. α¬░α¬òα½ìα¬ñα¬ªα¬╛α¬¿ α¬òα½çα¬«α½ìα¬¬ 7 α¬ªα¬┐α¬╡α¬╕α¬«α¬╛α¬é α¬¢α½ç.'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(title: tr(gu, 'Quick actions', 'α¬¥α¬íα¬¬α½Ç α¬òα½ìα¬░α¬┐α¬»α¬╛α¬ô')),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  childAspectRatio: .82,
                  children: [
                    FeatureButton(icon: Icons.account_tree_rounded, label: tr(gu, 'Family Tree', 'α¬òα½üα¬ƒα½üα¬éα¬¼ α¬╡α½âα¬òα½ìα¬╖'), color: AppPalette.forest, tint: AppPalette.forestTint, onTap: () => onTabSelected(1)),
                    FeatureButton(icon: Icons.contact_page_rounded, label: tr(gu, 'Directory', 'α¬╕α¬¡α½ìα¬» α¬»α¬╛α¬ªα½Ç'), color: AppPalette.peacock, tint: AppPalette.peacockTint, onTap: () => onTabSelected(2)),
                    FeatureButton(icon: Icons.favorite_rounded, label: tr(gu, 'Matrimony', 'α¬▓α¬ùα½ìα¬¿ α¬╡α¬┐α¬╖α¬»α¬ò'), color: AppPalette.pink, tint: const Color(0xFFFCE4EC), onTap: onMatrimony),
                    FeatureButton(icon: Icons.calendar_month_rounded, label: tr(gu, 'Events', 'α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï'), color: AppPalette.saffron, tint: AppPalette.saffronTint, onTap: () => onTabSelected(3)),
                    FeatureButton(icon: Icons.volunteer_activism_rounded, label: tr(gu, 'Donations', 'α¬ªα¬╛α¬¿ α¬¬α½üα¬úα½ìα¬»'), color: AppPalette.gold, tint: const Color(0xFFFFF3CD), onTap: () => _showNotice(context, tr(gu, 'Donations', 'α¬ªα¬╛α¬¿ α¬¬α½üα¬úα½ìα¬»'), tr(gu, 'Scholarship Fund, medical help and community initiatives are open for contributions.', 'α¬╢α¬┐α¬╖α½ìα¬»α¬╡α½âα¬ñα½ìα¬ñα¬┐ α¬½α¬éα¬í, α¬ñα¬¼α½Çα¬¼α½Ç α¬╕α¬╣α¬╛α¬» α¬àα¬¿α½ç α¬╕α¬«α¬╛α¬£α¬¿α¬╛ α¬òα¬╛α¬░α½ìα¬»α½ï α¬«α¬╛α¬ƒα½ç α¬»α½ïα¬ùα¬ªα¬╛α¬¿ α¬åα¬¬α½Ç α¬╢α¬òα½ï α¬¢α½ï.'))),
                    FeatureButton(icon: Icons.newspaper_rounded, label: tr(gu, 'News', 'α¬╕α¬«α¬╛α¬Üα¬╛α¬░'), color: AppPalette.peacock, tint: const Color(0xFFE1F5FE), onTap: () => _showNotice(context, tr(gu, 'News & notices', 'α¬╕α¬«α¬╛α¬Üα¬╛α¬░ α¬àα¬¿α½ç α¬¿α½ïα¬ƒα¬┐α¬╕'), tr(gu, 'Annual Trust elections will be held on 29 August at Community Bhavan, Rajkot.', 'α¬╡α¬╛α¬░α½ìα¬╖α¬┐α¬ò α¬ƒα½ìα¬░α¬╕α½ìα¬ƒ α¬Üα½éα¬éα¬ƒα¬úα½Ç 29 α¬ôα¬ùα¬╕α½ìα¬ƒα½ç α¬╕α¬«α¬╛α¬£ α¬¡α¬╡α¬¿, α¬░α¬╛α¬£α¬òα½ïα¬ƒ α¬ûα¬╛α¬ñα½ç α¬»α½ïα¬£α¬╛α¬╢α½ç.'))),
                    FeatureButton(icon: Icons.storefront_rounded, label: tr(gu, 'Business', 'α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'), color: const Color(0xFF5E35B1), tint: const Color(0xFFEDE7F6), onTap: () => onTabSelected(2)),
                    FeatureButton(icon: Icons.more_horiz_rounded, label: tr(gu, 'More', 'α¬╡α¬ºα½ü'), color: AppPalette.softInk, tint: const Color(0xFFF4F1EC), onTap: () => _showNotice(context, tr(gu, 'More community services', 'α¬╡α¬ºα½ü α¬╕α¬«α¬╛α¬£ α¬╕α½çα¬╡α¬╛α¬ô'), tr(gu, 'Scholarships, volunteer groups, emergency help and trust documents are coming next.', 'α¬╢α¬┐α¬╖α½ìα¬»α¬╡α½âα¬ñα½ìα¬ñα¬┐, α¬╕α½ìα¬╡α¬»α¬éα¬╕α½çα¬╡α¬ò α¬£α½éα¬Ñα½ï, α¬çα¬«α¬░α¬£α¬¿α½ìα¬╕α½Ç α¬╕α¬╣α¬╛α¬» α¬àα¬¿α½ç α¬ƒα½ìα¬░α¬╕α½ìα¬ƒ α¬ªα¬╕α½ìα¬ñα¬╛α¬╡α½çα¬£α½ï α¬ƒα½éα¬éα¬ò α¬╕α¬«α¬»α¬«α¬╛α¬é α¬åα¬╡α¬╢α½ç.'))),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Recent Samaj News ≡ƒô░', 'α¬ñα¬╛α¬£α¬╛ α¬╕α¬«α¬╛α¬£ α¬╕α¬«α¬╛α¬Üα¬╛α¬░ ≡ƒô░'), action: tr(gu, 'See all', 'α¬¼α¬ºα¬╛ α¬£α½üα¬ô')),
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
                            Text(tr(gu, 'Trust election notice', 'α¬ƒα½ìα¬░α¬╕α½ìα¬ƒ α¬Üα½éα¬éα¬ƒα¬úα½Ç α¬¿α½ïα¬ƒα¬┐α¬╕'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(tr(gu, 'Annual Trust elections on 29 Aug at Community Bhavan, Rajkot.', 'α¬╡α¬╛α¬░α½ìα¬╖α¬┐α¬ò α¬ƒα½ìα¬░α¬╕α½ìα¬ƒ α¬Üα½éα¬éα¬ƒα¬úα½Ç 29 α¬ôα¬ùα¬╕α½ìα¬ƒα½ç α¬╕α¬«α¬╛α¬£ α¬¡α¬╡α¬¿, α¬░α¬╛α¬£α¬òα½ïα¬ƒ α¬ûα¬╛α¬ñα½ç.'), style: const TextStyle(fontSize: 12, color: AppPalette.softInk, height: 1.32)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Upcoming events', 'α¬åα¬ùα¬╛α¬«α½Ç α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï'), action: tr(gu, 'See all', 'α¬¼α¬ºα¬╛ α¬£α½üα¬ô'), onAction: () => onTabSelected(3)),
                const SizedBox(height: 10),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _miniEvent(gu, '18', tr(gu, 'Jul', 'α¬£α½üα¬▓α¬╛α¬ê'), tr(gu, 'Samuh Lagna Sammelan', 'α¬╕α¬«α½éα¬╣ α¬▓α¬ùα½ìα¬¿ α¬╕α¬éα¬«α½çα¬▓α¬¿'), tr(gu, 'Community Hall, Ahmedabad', 'α¬╕α¬«α¬╛α¬£ α¬╡α¬╛α¬íα½Ç, α¬àα¬«α¬ªα¬╛α¬╡α¬╛α¬ª')),
                      const Divider(height: 1),
                      _miniEvent(gu, '02', tr(gu, 'Aug', 'α¬ôα¬ùα¬╕α½ìα¬ƒ'), tr(gu, 'Blood Donation Camp', 'α¬░α¬òα½ìα¬ñα¬ªα¬╛α¬¿ α¬òα½çα¬«α½ìα¬¬'), tr(gu, 'Darji Samaj Bhavan, Surat', 'α¬ªα¬░α¬£α½Ç α¬╕α¬«α¬╛α¬£ α¬¡α¬╡α¬¿, α¬╕α½üα¬░α¬ñ')),
                      const Divider(height: 1),
                      _miniEvent(gu, '15', tr(gu, 'Aug', 'α¬ôα¬ùα¬╕α½ìα¬ƒ'), tr(gu, 'Youth Sports Meet', 'α¬»α½üα¬╡α¬╛ α¬░α¬«α¬ñα¬ùα¬«α¬ñ α¬«α¬╣α½ïα¬ñα½ìα¬╕α¬╡'), tr(gu, 'Rajkot Ground No. 3', 'α¬░α¬╛α¬£α¬òα½ïα¬ƒ α¬ùα½ìα¬░α¬╛α¬ëα¬¿α½ìα¬í α¬¿α¬é. 3')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Featured families', 'α¬«α½üα¬ûα½ìα¬» α¬¬α¬░α¬┐α¬╡α¬╛α¬░α½ï'), action: tr(gu, 'Explore', 'α¬£α½üα¬ô')),
                const SizedBox(height: 10),
                SizedBox(
                  height: 154,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FamilyPreview(name: tr(gu, 'Chauhan Parivar', 'α¬Üα½îα¬╣α¬╛α¬ú α¬¬α¬░α¬┐α¬╡α¬╛α¬░'), details: tr(gu, 'Vadodara ┬╖ 6 generations', 'α¬╡α¬íα½ïα¬ªα¬░α¬╛ ┬╖ 6 α¬¬α½çα¬óα½Ç'), count: tr(gu, '240 members', '240 α¬╕α¬¡α½ìα¬»α½ï'), color: AppPalette.saffron),
                      FamilyPreview(name: tr(gu, 'Parekh Parivar', 'α¬¬α¬╛α¬░α½çα¬û α¬¬α¬░α¬┐α¬╡α¬╛α¬░'), details: tr(gu, 'Surat ┬╖ 5 generations', 'α¬╕α½üα¬░α¬ñ ┬╖ 5 α¬¬α½çα¬óα½Ç'), count: tr(gu, '185 members', '185 α¬╕α¬¡α½ìα¬»α½ï'), color: AppPalette.forest),
                      FamilyPreview(name: tr(gu, 'Joshi Parivar', 'α¬£α½ïα¬╢α½Ç α¬¬α¬░α¬┐α¬╡α¬╛α¬░'), details: tr(gu, 'Rajkot ┬╖ 7 generations', 'α¬░α¬╛α¬£α¬òα½ïα¬ƒ ┬╖ 7 α¬¬α½çα¬óα½Ç'), count: tr(gu, '312 members', '312 α¬╕α¬¡α½ìα¬»α½ï'), color: AppPalette.gold),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Community at a glance', 'α¬╕α¬«α¬╛α¬£ α¬Åα¬ò α¬¿α¬£α¬░α½ç')),
                const SizedBox(height: 10),
                _StatsGrid(gujarati: gu),
                const SizedBox(height: 24),
                SectionHeading(title: tr(gu, 'Community Posts & Feed', 'α¬╕α¬«α¬╛α¬£ α¬¬α½ïα¬╕α½ìα¬ƒα½ìα¬╕ α¬àα¬¿α½ç α¬½α½Çα¬í'), action: tr(gu, '20 posts', '20 α¬¬α½ïα¬╕α½ìα¬ƒα½ìα¬╕')),
                const SizedBox(height: 10),
                CommunityPost(
                  initials: 'RC',
                  name: displayName,
                  meta: tr(gu, '2 hours ago ┬╖ Vadodara', '2 α¬òα¬▓α¬╛α¬ò α¬¬α¬╣α½çα¬▓α¬╛ ┬╖ α¬╡α¬íα½ïα¬ªα¬░α¬╛'),
                  badge: tr(gu, 'Announcement', 'α¬£α¬╛α¬╣α½çα¬░α¬╛α¬ñ'),
                  text: tr(gu, 'Jay Shree Krishna to all samaj members! Welcome to our new digital platform KutumbSetu. Stay connected with family, business and events.', 'α¬ñα¬«α¬╛α¬« α¬╕α¬«α¬╛α¬£ α¬¼α¬éα¬ºα½üα¬ôα¬¿α½ç α¬£α¬» α¬╢α½ìα¬░α½Ç α¬òα½âα¬╖α½ìα¬ú! α¬åα¬¬α¬úα¬╛ α¬¿α¬╡α¬╛ α¬íα¬┐α¬£α¬┐α¬ƒα¬▓ α¬¬α½ìα¬▓α½çα¬ƒα¬½α½ïα¬░α½ìα¬« α¬òα½üα¬ƒα½üα¬éα¬¼α¬╕α½çα¬ñα½ü α¬¬α¬░ α¬åα¬¬α¬¿α½üα¬é α¬╕α½ìα¬╡α¬╛α¬ùα¬ñ α¬¢α½ç. α¬¬α¬░α¬┐α¬╡α¬╛α¬░, α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬» α¬àα¬¿α½ç α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï α¬╕α¬╛α¬Ñα½ç α¬£α½ïα¬íα¬╛α¬»α½çα¬▓α¬╛ α¬░α¬╣α½ï.'),
                ),
                const SizedBox(height: 12),
                CommunityPost(
                  initials: 'SV',
                  name: tr(gu, 'Sonalben Vaghela', 'α¬╕α½ïα¬¿α¬▓α¬¼α½çα¬¿ α¬╡α¬╛α¬ÿα½çα¬▓α¬╛'),
                  meta: tr(gu, 'Yesterday ┬╖ Nadiad', 'α¬ùα¬êα¬òα¬╛α¬▓α½ç ┬╖ α¬¿α¬íα¬┐α¬»α¬╛α¬ª'),
                  badge: tr(gu, 'Community', 'α¬╕α¬«α¬╛α¬£'),
                  text: tr(gu, 'Our school book collection drive begins this Sunday. Volunteers are welcome.', 'α¬àα¬«α¬╛α¬░α½Ç α¬╢α¬╛α¬│α¬╛ α¬¬α½üα¬╕α½ìα¬ñα¬ò α¬╕α¬éα¬ùα½ìα¬░α¬╣ α¬¥α½üα¬éα¬¼α½çα¬╢ α¬å α¬░α¬╡α¬┐α¬╡α¬╛α¬░α¬Ñα½Ç α¬╢α¬░α½é α¬Ñα¬╛α¬» α¬¢α½ç. α¬╕α½ìα¬╡α¬»α¬éα¬╕α½çα¬╡α¬òα½ïα¬¿α½üα¬é α¬╕α½ìα¬╡α¬╛α¬ùα¬ñ α¬¢α½ç.'),
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
                      Text(tr(gu, '≡ƒöù Relationship Finder', '≡ƒöù α¬╕α¬éα¬¼α¬éα¬º α¬╢α½ïα¬ºα¬ò'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _relationshipMenu(_first, ['Rajeshbhai (Me)', 'Suresh Kaka', 'Kailash Foi'], (v) => setState(() => _first = v!))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(tr(gu, 'to', 'α¬╕α½üα¬ºα½Ç'), style: const TextStyle(color: AppPalette.softInk))),
                          Expanded(child: _relationshipMenu(_second, ['Nikita (Cousin)', 'Chhotalal (Dadaji)', 'Yash (Nephew)'], (v) => setState(() => _second = v!))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => setState(() => _result = tr(gu, 'Nikita is your first cousin.', 'α¬¿α¬┐α¬òα¬┐α¬ñα¬╛ α¬ñα¬«α¬╛α¬░α½Ç α¬¬α½ìα¬░α¬Ñα¬« α¬¬α¬┐α¬ñα¬░α¬╛α¬ê α¬¼α¬╣α½çα¬¿ α¬¢α½ç.')),
                        style: FilledButton.styleFrom(backgroundColor: AppPalette.saffron, minimumSize: const Size.fromHeight(42)),
                        icon: const Icon(Icons.hub_rounded, size: 18),
                        label: Text(tr(gu, 'Find connection', 'α¬╕α¬éα¬¼α¬éα¬º α¬╢α½ïα¬ºα½ï')),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 10),
                        Text(_result!, style: const TextStyle(color: AppPalette.forest, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(tr(gu, 'Interactive tree ┬╖ pinch, drag & tap a member', 'α¬çα¬¿α½ìα¬ƒα¬░α½çα¬òα½ìα¬ƒα¬┐α¬╡ α¬╡α½âα¬òα½ìα¬╖ ┬╖ α¬¥α½éα¬« α¬òα¬░α½ï α¬àα¬¿α½ç α¬ƒα½çα¬¬ α¬òα¬░α½ï'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                          _treeNode(left: 90, top: 28, initials: 'CL', name: tr(gu, 'Chhotalal', 'α¬¢α½ïα¬ƒα¬╛α¬▓α¬╛α¬▓'), relation: tr(gu, 'Dadaji', 'α¬ªα¬╛α¬ªα¬╛α¬£α½Ç'), color: const Color(0xFF8D6E63)),
                          _treeNode(left: 220, top: 28, initials: 'SB', name: tr(gu, 'Savitaben', 'α¬╕α¬╡α¬┐α¬ñα¬╛α¬¼α½çα¬¿'), relation: tr(gu, 'Dadiji', 'α¬ªα¬╛α¬ªα½Çα¬£α½Ç'), color: const Color(0xFFAD8B73)),
                          _treeNode(left: 470, top: 28, initials: 'MB', name: tr(gu, 'Manilal', 'α¬«α¬úα¬┐α¬▓α¬╛α¬▓'), relation: tr(gu, 'Nanaji', 'α¬¿α¬╛α¬¿α¬╛α¬£α½Ç'), color: const Color(0xFF8D6E63)),
                          _treeNode(left: 600, top: 28, initials: 'JB', name: tr(gu, 'Jasuben', 'α¬£α¬╕α½üα¬¼α½çα¬¿'), relation: tr(gu, 'Naniji', 'α¬¿α¬╛α¬¿α½Çα¬£α½Ç'), color: const Color(0xFFAD8B73)),
                          _treeNode(left: 275, top: 180, initials: 'DC', name: tr(gu, 'Dineshbhai', 'α¬ªα¬┐α¬¿α½çα¬╢α¬¡α¬╛α¬ê'), relation: tr(gu, 'Father', 'α¬¬α¬┐α¬ñα¬╛α¬£α½Ç'), color: AppPalette.saffron),
                          _treeNode(left: 405, top: 180, initials: 'HC', name: tr(gu, 'Hemaben', 'α¬╣α½çα¬«α¬╛α¬¼α½çα¬¿'), relation: tr(gu, 'Mother', 'α¬«α¬╛α¬ñα¬╛α¬£α½Ç'), color: const Color(0xFFEF6C00)),
                          _treeNode(left: 80, top: 310, initials: 'NR', name: tr(gu, 'Nikita', 'α¬¿α¬┐α¬òα¬┐α¬ñα¬╛'), relation: tr(gu, 'Cousin', 'α¬¼α¬╣α½çα¬¿'), color: AppPalette.forest),
                          _treeNode(left: 210, top: 310, initials: 'AB', name: tr(gu, 'Amitbhai', 'α¬àα¬«α¬┐α¬ñα¬¡α¬╛α¬ê'), relation: tr(gu, 'Brother', 'α¬«α½ïα¬ƒα½ï α¬¡α¬╛α¬ê'), color: const Color(0xFF388E3C)),
                          _treeNode(left: 350, top: 310, initials: 'RC', name: tr(gu, 'Rajeshbhai', 'α¬░α¬╛α¬£α½çα¬╢α¬¡α¬╛α¬ê'), relation: tr(gu, 'You', 'α¬ñα¬«α½ç'), color: AppPalette.saffron, selected: true),
                          _treeNode(left: 480, top: 310, initials: 'PP', name: tr(gu, 'Priyaben', 'α¬¬α½ìα¬░α¬┐α¬»α¬╛α¬¼α½çα¬¿'), relation: tr(gu, 'Spouse', 'α¬¬α¬ñα½ìα¬¿α½Ç'), color: AppPalette.peacock),
                          _treeNode(left: 610, top: 310, initials: 'VJ', name: tr(gu, 'Vishal', 'α¬╡α¬┐α¬╢α¬╛α¬▓'), relation: tr(gu, 'Cousin', 'α¬¡α¬╛α¬ê'), color: AppPalette.forest),
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
                    _legend(AppPalette.peacock, tr(gu, 'Marriage', 'α¬▓α¬ùα½ìα¬¿')),
                    _legend(AppPalette.forest, tr(gu, 'Parent / child', 'α¬«α¬╛α¬ñα¬╛-α¬¬α¬┐α¬ñα¬╛ / α¬╕α¬éα¬ñα¬╛α¬¿')),
                    _legend(AppPalette.saffron, tr(gu, 'Family group', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬£α½éα¬Ñ')),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => _AddMemberSheet(gujarati: gu)),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(tr(gu, 'Request to add family member', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬╕α¬¡α½ìα¬» α¬ëα¬«α½çα¬░α¬╡α¬╛ α¬╡α¬┐α¬¿α¬éα¬ñα½Ç')),
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
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name ┬╖ $relation'))),
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
      ('KM', tr(gu, 'Kiranbhai Mistry', 'α¬òα¬┐α¬░α¬úα¬¡α¬╛α¬ê α¬«α¬┐α¬╕α½ìα¬ñα½ìα¬░α½Ç'), tr(gu, 'Textile Merchant', 'α¬ƒα½çα¬òα½ìα¬╕α¬ƒα¬╛α¬çα¬▓ α¬«α¬░α½ìα¬Üα¬¿α½ìα¬ƒ'), tr(gu, 'Anand, Gujarat', 'α¬åα¬úα¬éα¬ª, α¬ùα½üα¬£α¬░α¬╛α¬ñ'), AppPalette.saffron),
      ('SV', tr(gu, 'Sonalben Vaghela', 'α¬╕α½ïα¬¿α¬▓α¬¼α½çα¬¿ α¬╡α¬╛α¬ÿα½çα¬▓α¬╛'), tr(gu, 'School Principal', 'α¬╢α¬╛α¬│α¬╛ α¬åα¬Üα¬╛α¬░α½ìα¬»α¬╛'), tr(gu, 'Nadiad, Gujarat', 'α¬¿α¬íα¬┐α¬»α¬╛α¬ª, α¬ùα½üα¬£α¬░α¬╛α¬ñ'), AppPalette.peacock),
      ('PJ', tr(gu, 'Parthbhai Joshi', 'α¬¬α¬╛α¬░α½ìα¬Ñα¬¡α¬╛α¬ê α¬£α½ïα¬╢α½Ç'), tr(gu, 'Software Engineer', 'α¬╕α½ïα¬½α½ìα¬ƒα¬╡α½çα¬░ α¬Åα¬¿α½ìα¬£α¬┐α¬¿α¬┐α¬»α¬░'), tr(gu, 'Bengaluru', 'α¬¼α½çα¬éα¬ùα¬▓α½üα¬░α½ü'), AppPalette.forest),
      ('RD', tr(gu, 'Rinaben Darji', 'α¬░α½Çα¬¿α¬╛α¬¼α½çα¬¿ α¬ªα¬░α¬£α½Ç'), tr(gu, 'Boutique Owner', 'α¬¼α½üα¬ƒα½Çα¬ò α¬ôα¬¿α¬░'), tr(gu, 'Surat, Gujarat', 'α¬╕α½üα¬░α¬ñ, α¬ùα½üα¬£α¬░α¬╛α¬ñ'), AppPalette.pink),
      ('MB', tr(gu, 'Meeraben Bavishi', 'α¬«α½Çα¬░α¬╛α¬¼α½çα¬¿ α¬¼α¬╛α¬╡α¬┐α¬╢α½Ç'), tr(gu, 'Doctor ┬╖ MBBS', 'α¬íα½ïα¬òα½ìα¬ƒα¬░ ┬╖ α¬Åα¬«.α¬¼α½Ç.α¬¼α½Ç.α¬Åα¬╕.'), tr(gu, 'Vadodara, Gujarat', 'α¬╡α¬íα½ïα¬ªα¬░α¬╛, α¬ùα½üα¬£α¬░α¬╛α¬ñ'), const Color(0xFF00897B)),
    ];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Babariawad Darji Samaj', 'α¬¼α¬╛α¬¼α¬░α¬┐α¬»α¬╛α¬╡α¬╛α¬í α¬ªα¬░α¬£α½Ç α¬╕α¬«α¬╛α¬£'),
            title: tr(gu, 'Community Directory', 'α¬╕α¬«α¬╛α¬£ α¬╕α¬¡α½ìα¬» α¬»α¬╛α¬ªα½Ç'),
            subtitle: tr(gu, 'Search by name, village or professionΓÇª', 'α¬¿α¬╛α¬«, α¬ùα¬╛α¬« α¬àα¬Ñα¬╡α¬╛ α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬» α¬╢α½ïα¬ºα½ïΓÇª'),
            color: AppPalette.peacock,
            onLanguage: () {},
            onNotifications: () {},
            showActions: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _FilterChip(label: tr(gu, 'All', 'α¬¼α¬ºα¬╛'), active: true),
                _FilterChip(label: tr(gu, 'Village', 'α¬ùα¬╛α¬«')),
                _FilterChip(label: tr(gu, 'City', 'α¬╢α¬╣α½çα¬░')),
                _FilterChip(label: tr(gu, 'Profession', 'α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»')),
                _FilterChip(label: tr(gu, 'Education', 'α¬àα¬¡α½ìα¬»α¬╛α¬╕')),
              ]),
              const SizedBox(height: 14),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(children: [for (var i = 0; i < members.length; i++) ...[MemberTile(initials: members[i].$1, name: members[i].$2, occupation: members[i].$3, city: members[i].$4, color: members[i].$5), if (i != members.length - 1) const Divider(height: 1, indent: 70)]),
              ),
              const SizedBox(height: 24),
              SectionHeading(title: tr(gu, 'Business directory', 'α¬¼α¬┐α¬¥α¬¿α½çα¬╕ α¬íα¬┐α¬░α½çα¬òα½ìα¬ƒα¬░α½Ç'), action: tr(gu, 'View all', 'α¬¼α¬ºα¬╛ α¬£α½üα¬ô')),
              const SizedBox(height: 10),
              SizedBox(
                height: 142,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  BusinessPreview(name: tr(gu, 'Shree Textiles', 'α¬╢α½ìα¬░α½Ç α¬ƒα½çα¬òα½ìα¬╕α¬ƒα¬╛α¬çα¬▓α½ìα¬╕'), details: tr(gu, 'Surat ┬╖ Fabric & Tailoring', 'α¬╕α½üα¬░α¬ñ ┬╖ α¬òα¬╛α¬¬α¬í α¬àα¬¿α½ç α¬ƒα½çα¬▓α¬░α¬┐α¬éα¬ù'), color: const Color(0xFF5E35B1)),
                  BusinessPreview(name: tr(gu, 'Bavishi Clinic', 'α¬¼α¬╛α¬╡α¬┐α¬╢α½Ç α¬òα½ìα¬▓α¬┐α¬¿α¬┐α¬ò'), details: tr(gu, 'Vadodara ┬╖ Healthcare', 'α¬╡α¬íα½ïα¬ªα¬░α¬╛ ┬╖ α¬╣α½çα¬▓α½ìα¬Ñα¬òα½çα¬░'), color: const Color(0xFF00897B)),
                  BusinessPreview(name: tr(gu, 'Riya Boutique', 'α¬░α¬┐α¬»α¬╛ α¬¼α½üα¬ƒα½Çα¬ò'), details: tr(gu, 'Rajkot ┬╖ Fashion', 'α¬░α¬╛α¬£α¬òα½ïα¬ƒ ┬╖ α¬½α½çα¬╢α¬¿'), color: AppPalette.pink),
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
      (tr(gu, 'Samuh Lagna Sammelan 2026', 'α¬╕α¬«α½éα¬╣ α¬▓α¬ùα½ìα¬¿ α¬╕α¬éα¬«α½çα¬▓α¬¿ 2026'), tr(gu, '18 Jul, 10:00 AM', '18 α¬£α½üα¬▓α¬╛α¬ê, 10:00 AM'), tr(gu, 'Ahmedabad', 'α¬àα¬«α¬ªα¬╛α¬╡α¬╛α¬ª'), tr(gu, 'Festival', 'α¬«α¬╣α½ïα¬ñα½ìα¬╕α¬╡'), AppPalette.saffron, '340'),
      (tr(gu, 'Blood Donation Camp', 'α¬░α¬òα½ìα¬ñα¬ªα¬╛α¬¿ α¬òα½çα¬«α½ìα¬¬'), tr(gu, '02 Aug, 9:00 AM', '02 α¬ôα¬ùα¬╕α½ìα¬ƒ, 9:00 AM'), tr(gu, 'Surat', 'α¬╕α½üα¬░α¬ñ'), tr(gu, 'Health', 'α¬åα¬░α½ïα¬ùα½ìα¬»'), AppPalette.pink, '128'),
      (tr(gu, 'Youth Sports Meet', 'α¬»α½üα¬╡α¬╛ α¬╕α½ìα¬¬α½ïα¬░α½ìα¬ƒα½ìα¬╕ α¬«α½Çα¬ƒ'), tr(gu, '15 Aug, 7:30 AM', '15 α¬ôα¬ùα¬╕α½ìα¬ƒ, 7:30 AM'), tr(gu, 'Rajkot', 'α¬░α¬╛α¬£α¬òα½ïα¬ƒ'), tr(gu, 'Sports', 'α¬░α¬«α¬ñα¬ùα¬«α¬ñ'), AppPalette.peacock, '96'),
      (tr(gu, 'Samaj Trust ┬╖ Annual Election', 'α¬╕α¬«α¬╛α¬£ α¬ƒα½ìα¬░α¬╕α½ìα¬ƒ ┬╖ α¬╡α¬╛α¬░α½ìα¬╖α¬┐α¬ò α¬Üα½éα¬éα¬ƒα¬úα½Ç'), tr(gu, '29 Aug, 5:00 PM', '29 α¬ôα¬ùα¬╕α½ìα¬ƒ, 5:00 PM'), tr(gu, 'Rajkot', 'α¬░α¬╛α¬£α¬òα½ïα¬ƒ'), tr(gu, 'Meeting', 'α¬«α½Çα¬ƒα¬┐α¬éα¬ù'), AppPalette.forest, '210'),
    ];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Community', 'α¬╕α¬«α¬╛α¬£'),
            title: tr(gu, 'Events & Gatherings', 'α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï α¬àα¬¿α½ç α¬╕α¬éα¬«α½çα¬▓α¬¿α½ï'),
            subtitle: tr(gu, 'Celebrate, serve and connect together', 'α¬ëα¬£α¬╡α¬úα½Ç α¬òα¬░α½ï, α¬╕α½çα¬╡α¬╛ α¬òα¬░α½ï α¬àα¬¿α½ç α¬£α½ïα¬íα¬╛α¬ô'),
            onLanguage: () {},
            onNotifications: () {},
            showActions: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _SegmentButton(label: tr(gu, 'Upcoming', 'α¬åα¬ùα¬╛α¬«α½Ç'), selected: _segment == 0, onTap: () => setState(() => _segment = 0)),
                const SizedBox(width: 8),
                _SegmentButton(label: tr(gu, 'Past', 'α¬¡α½éα¬ñα¬òα¬╛α¬│α¬¿α¬╛'), selected: _segment == 1, onTap: () => setState(() => _segment = 1)),
                const SizedBox(width: 8),
                _SegmentButton(label: tr(gu, 'My RSVPs', 'α¬«α¬╛α¬░α¬╛ RSVP'), selected: _segment == 2, onTap: () => setState(() => _segment = 2)),
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
                Padding(padding: const EdgeInsets.only(top: 50), child: Center(child: Text(tr(gu, 'No RSVPs yet. Tap RSVP on an event.', 'α¬╣α¬£α½ü α¬òα½ïα¬ê RSVP α¬¿α¬Ñα½Ç. α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬« α¬¬α¬░ RSVP α¬ªα¬¼α¬╛α¬╡α½ï.'), style: const TextStyle(color: AppPalette.softInk)))),
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
                  Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 5), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.displayName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Row(children: [const Icon(Icons.verified_rounded, size: 16, color: AppPalette.peacock), const SizedBox(width: 4), Text(tr(gu, 'Verified member', 'α¬¬α½ìα¬░α¬«α¬╛α¬úα¬┐α¬ñ α¬╕α¬¡α½ìα¬»'), style: const TextStyle(fontSize: 12, color: AppPalette.peacock, fontWeight: FontWeight.w700))])]))),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 7, children: [_ProfileTag(tr(gu, 'Chauhan Parivar', 'α¬Üα½îα¬╣α¬╛α¬ú α¬¬α¬░α¬┐α¬╡α¬╛α¬░')), _ProfileTag(tr(gu, 'Vadodara', 'α¬╡α¬íα½ïα¬ªα¬░α¬╛')), _ProfileTag(tr(gu, 'Software Architect', 'α¬╕α½ïα¬½α½ìα¬ƒα¬╡α½çα¬░ α¬åα¬░α½ìα¬òα¬┐α¬ƒα½çα¬òα½ìα¬ƒ'))]),
                const SizedBox(height: 18),
                _CommunityIdCard(familyId: widget.familyId, gujarati: gu),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFFF4F1EC), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    _profileToggle(0, tr(gu, 'About', 'α¬«α¬╛α¬╣α¬┐α¬ñα½Ç')),
                    _profileToggle(1, tr(gu, 'Family', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░')),
                    _profileToggle(2, tr(gu, 'Contributions', 'α¬»α½ïα¬ùα¬ªα¬╛α¬¿')),
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
                    ListTile(leading: const Icon(Icons.language_rounded, color: AppPalette.saffron), title: Text(tr(gu, 'Language', 'α¬¡α¬╛α¬╖α¬╛')), subtitle: Text(gu ? 'α¬ùα½üα¬£α¬░α¬╛α¬ñα½Ç' : 'English'), trailing: const Icon(Icons.chevron_right_rounded), onTap: widget.onLanguageChanged),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.logout_rounded, color: AppPalette.pink), title: Text(tr(gu, 'Sign out', 'α¬╕α¬╛α¬çα¬¿ α¬åα¬ëα¬ƒ')), onTap: widget.onLogout),
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
      (tr(gu, 'Occupation', 'α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'), tr(gu, 'Software Architect', 'α¬╕α½ïα¬½α½ìα¬ƒα¬╡α½çα¬░ α¬åα¬░α½ìα¬òα¬┐α¬ƒα½çα¬òα½ìα¬ƒ')),
      (tr(gu, 'Education', 'α¬àα¬¡α½ìα¬»α¬╛α¬╕'), tr(gu, 'B.E. Computer Engineering', 'α¬¼α½Ç.α¬ê. α¬òα¬«α½ìα¬¬α½ìα¬»α½üα¬ƒα¬░ α¬Åα¬¿α½ìα¬£α¬┐α¬¿α¬┐α¬»α¬░α¬┐α¬éα¬ù')),
      (tr(gu, 'Village', 'α¬╡α¬ñα¬¿ / α¬ùα¬╛α¬«'), tr(gu, 'Karamsad', 'α¬òα¬░α¬«α¬╕α¬ª')),
      (tr(gu, 'City', 'α¬╣α¬╛α¬▓ α¬░α¬╣α½çα¬áα¬╛α¬ú'), tr(gu, 'Vadodara, Gujarat', 'α¬╡α¬íα½ïα¬ªα¬░α¬╛, α¬ùα½üα¬£α¬░α¬╛α¬ñ')),
      (tr(gu, 'Blood group', 'α¬¼α½ìα¬▓α¬í α¬ùα½ìα¬░α½üα¬¬'), 'B+'),
      (tr(gu, 'Contact', 'α¬╕α¬éα¬¬α¬░α½ìα¬ò'), '+91 98ΓÇóΓÇóΓÇó ΓÇóΓÇóΓÇó42'),
    ];
    return SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < rows.length; i++) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Expanded(child: Text(rows[i].$1, style: const TextStyle(color: AppPalette.softInk, fontSize: 13))), Expanded(child: Text(rows[i].$2, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))])), if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16)]));
  }

  Widget _family(bool gu) {
    final family = [('DC', tr(gu, 'Dineshbhai Chauhan', 'α¬ªα¬┐α¬¿α½çα¬╢α¬¡α¬╛α¬ê α¬Üα½îα¬╣α¬╛α¬ú'), tr(gu, 'Father', 'α¬¬α¬┐α¬ñα¬╛α¬£α½Ç'), AppPalette.saffron), ('HC', tr(gu, 'Hemaben Chauhan', 'α¬╣α½çα¬«α¬╛α¬¼α½çα¬¿ α¬Üα½îα¬╣α¬╛α¬ú'), tr(gu, 'Mother', 'α¬«α¬╛α¬ñα¬╛α¬£α½Ç'), const Color(0xFFEF6C00)), ('PP', tr(gu, 'Priyaben Chauhan', 'α¬¬α½ìα¬░α¬┐α¬»α¬╛α¬¼α½çα¬¿ α¬Üα½îα¬╣α¬╛α¬ú'), tr(gu, 'Spouse', 'α¬¬α¬ñα½ìα¬¿α½Ç'), AppPalette.peacock), ('AB', tr(gu, 'Amitbhai Chauhan', 'α¬àα¬«α¬┐α¬ñα¬¡α¬╛α¬ê α¬Üα½îα¬╣α¬╛α¬ú'), tr(gu, 'Brother', 'α¬«α½ïα¬ƒα½ï α¬¡α¬╛α¬ê'), AppPalette.forest)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionHeading(title: tr(gu, 'Family tree preview', 'α¬òα½üα¬ƒα½üα¬éα¬¼ α¬╡α½âα¬òα½ìα¬╖ α¬¥α¬▓α¬ò'), action: tr(gu, 'Open tree', 'α¬╡α½âα¬òα½ìα¬╖ α¬ûα½ïα¬▓α½ï'), onAction: widget.onOpenTree), const SizedBox(height: 8), SurfaceCard(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < family.length; i++) ...[MemberTile(initials: family[i].$1, name: family[i].$2, occupation: family[i].$3, city: '', color: family[i].$4, compact: true), if (i != family.length - 1) const Divider(height: 1, indent: 70)]]))]);
  }

  Widget _contributions(bool gu) {
    final rows = [('≡ƒÅå', tr(gu, 'Scholarship Fund', 'α¬╢α¬┐α¬╖α½ìα¬»α¬╡α½âα¬ñα½ìα¬ñα¬┐ α¬½α¬éα¬í'), tr(gu, 'Γé╣25,000 donated', 'Γé╣25,000 α¬ªα¬╛α¬¿')), ('≡ƒÄô', tr(gu, 'Mentorship', 'α¬«α¬╛α¬░α½ìα¬ùα¬ªα¬░α½ìα¬╢α¬¿'), tr(gu, '6 students guided', '6 α¬╡α¬┐α¬ªα½ìα¬»α¬╛α¬░α½ìα¬Ñα½Çα¬ôα¬¿α½ç α¬«α¬╛α¬░α½ìα¬ùα¬ªα¬░α½ìα¬╢α¬¿')), ('≡ƒ⌐╕', tr(gu, 'Blood camps', 'α¬░α¬òα½ìα¬ñα¬ªα¬╛α¬¿ α¬òα½çα¬«α½ìα¬¬'), tr(gu, '4 camps organized', '4 α¬òα½çα¬«α½ìα¬¬α¬¿α½üα¬é α¬åα¬»α½ïα¬£α¬¿'))];
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
      ('NC', tr(gu, 'Nikita Chauhan', 'α¬¿α¬┐α¬òα¬┐α¬ñα¬╛ α¬Üα½îα¬╣α¬╛α¬ú'), tr(gu, '26 ┬╖ Marketing Manager', '26 ┬╖ α¬«α¬╛α¬░α½ìα¬òα½çα¬ƒα¬┐α¬éα¬ù α¬«α½çα¬¿α½çα¬£α¬░'), tr(gu, 'Ahmedabad', 'α¬àα¬«α¬ªα¬╛α¬╡α¬╛α¬ª'), AppPalette.pink),
      ('KP', tr(gu, 'Kevin Parekh', 'α¬òα½çα¬╡α¬┐α¬¿ α¬¬α¬╛α¬░α½çα¬û'), tr(gu, '29 ┬╖ Civil Engineer', '29 ┬╖ α¬╕α¬┐α¬╡α¬┐α¬▓ α¬Åα¬¿α½ìα¬£α¬┐α¬¿α¬┐α¬»α¬░'), tr(gu, 'Surat', 'α¬╕α½üα¬░α¬ñ'), AppPalette.peacock),
      ('PT', tr(gu, 'Priya Trivedi', 'α¬¬α½ìα¬░α¬┐α¬»α¬╛ α¬ñα½ìα¬░α¬┐α¬╡α½çα¬ªα½Ç'), tr(gu, '24 ┬╖ Doctor, MBBS', '24 ┬╖ α¬íα½ïα¬òα½ìα¬ƒα¬░, α¬Åα¬«.α¬¼α½Ç.α¬¼α½Ç.α¬Åα¬╕.'), tr(gu, 'Rajkot', 'α¬░α¬╛α¬£α¬òα½ïα¬ƒ'), AppPalette.forest),
      ('RJ', tr(gu, 'Rohan Joshi', 'α¬░α½ïα¬╣α¬¿ α¬£α½ïα¬╢α½Ç'), tr(gu, '31 ┬╖ Chartered Accountant', '31 ┬╖ α¬Üα¬╛α¬░α½ìα¬ƒα¬░α½ìα¬í α¬Åα¬òα¬╛α¬ëα¬¿α½ìα¬ƒα¬¿α½ìα¬ƒ'), tr(gu, 'Vadodara', 'α¬╡α¬íα½ïα¬ªα¬░α¬╛'), AppPalette.gold),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(padding: EdgeInsets.zero, children: [
          _SaffronHeader(
            eyebrow: tr(gu, 'Matrimony', 'α¬▓α¬ùα½ìα¬¿ α¬╡α¬┐α¬╖α¬»α¬ò'),
            title: tr(gu, 'Find a match', 'α¬»α½ïα¬ùα½ìα¬» α¬£α½Çα¬╡α¬¿α¬╕α¬╛α¬Ñα½Ç α¬╢α½ïα¬ºα½ï'),
            subtitle: tr(gu, 'Search by age, city or professionΓÇª', 'α¬ëα¬éα¬«α¬░, α¬╢α¬╣α½çα¬░ α¬àα¬Ñα¬╡α¬╛ α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬» α¬╢α½ïα¬ºα½ïΓÇª'),
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
              Text(tr(gu, '≡ƒÄÑ Profiles with a family introduction video are marked', '≡ƒÄÑ α¬½α½çα¬«α¬┐α¬▓α½Ç α¬çα¬¿α½ìα¬ƒα½ìα¬░α½ï α¬╡α¬┐α¬íα¬┐α¬»α½ï α¬ºα¬░α¬╛α¬╡α¬ñα½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬Üα¬┐α¬╣α½ìα¬¿α¬┐α¬ñ α¬¢α½ç'), style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)),
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
      case 'All': return 'α¬¼α¬ºα¬╛';
      case 'Age': return 'α¬ëα¬éα¬«α¬░';
      case 'City': return 'α¬╢α¬╣α½çα¬░';
      case 'Education': return 'α¬àα¬¡α½ìα¬»α¬╛α¬╕';
      default: return 'α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»';
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
          Text(tr(gu, 'This profile is verified by the family. Send interest to begin a family-guided introduction.', 'α¬å α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬ªα½ìα¬╡α¬╛α¬░α¬╛ α¬¬α½ìα¬░α¬«α¬╛α¬úα¬┐α¬ñ α¬¢α½ç. α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α¬╛ α¬«α¬╛α¬░α½ìα¬ùα¬ªα¬░α½ìα¬╢α¬¿ α¬╕α¬╛α¬Ñα½ç α¬¬α¬░α¬┐α¬Üα¬» α¬╢α¬░α½é α¬òα¬░α¬╡α¬╛ α¬░α¬╕ α¬«α½ïα¬òα¬▓α½ï.'), style: const TextStyle(color: AppPalette.softInk, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () { Navigator.pop(sheetContext); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest sent to the family.', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α½ç α¬░α¬╕ α¬«α½ïα¬òα¬▓α¬╡α¬╛α¬«α¬╛α¬é α¬åα¬╡α½ìα¬»α½ï.')))); }, style: FilledButton.styleFrom(backgroundColor: AppPalette.pink, minimumSize: const Size.fromHeight(48)), icon: const Icon(Icons.favorite_rounded), label: Text(tr(gu, 'Send interest', 'α¬░α¬╕ α¬«α½ïα¬òα¬▓α½ï'))),
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
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(gujarati, '≡ƒî│ Family Tree', '≡ƒî│ α¬òα½üα¬ƒα½üα¬éα¬¼ α¬╡α½âα¬òα½ìα¬╖'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(tr(gujarati, 'Chauhan Parivar ┬╖ Vadodara lineage', 'α¬Üα½îα¬╣α¬╛α¬ú α¬¬α¬░α¬┐α¬╡α¬╛α¬░ ┬╖ α¬╡α¬íα½ïα¬ªα¬░α¬╛ α¬╡α¬éα¬╢α¬╛α¬╡α¬▓α½Ç'), style: const TextStyle(fontSize: 12, color: AppPalette.softInk))])), Container(width: 38, height: 38, decoration: const BoxDecoration(color: AppPalette.forestTint, shape: BoxShape.circle), child: const Icon(Icons.search_rounded, color: AppPalette.forest))]),
        const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _FilterChip(label: tr(gujarati, 'Full Tree', 'α¬╕α¬éα¬¬α½éα¬░α½ìα¬ú α¬╡α½âα¬òα½ìα¬╖'), active: true),
          const SizedBox(width: 8), _FilterChip(label: tr(gujarati, 'My Family', 'α¬«α¬╛α¬░α½ï α¬¬α¬░α¬┐α¬╡α¬╛α¬░')),
          const SizedBox(width: 8), _FilterChip(label: tr(gujarati, "Father's Side", 'α¬¬α¬┐α¬ñα½â α¬¬α¬òα½ìα¬╖')),
          const SizedBox(width: 8), _FilterChip(label: tr(gujarati, "Mother's Side", 'α¬«α¬╛α¬ñα½â α¬¬α¬òα½ìα¬╖')),
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
  Widget build(BuildContext context) => Container(width: 178, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.divider)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 68, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .35)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), alignment: Alignment.topRight, padding: const EdgeInsets.all(8), child: const CircleAvatar(radius: 13, backgroundColor: Colors.white, child: Text('Γÿà', style: TextStyle(color: AppPalette.gold, fontSize: 15))),), Padding(padding: const EdgeInsets.all(11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]))]));
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
  Widget build(BuildContext context) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .96, children: [_StatBox(number: '1,240', label: tr(gujarati, 'Families', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α½ï')), _StatBox(number: '18.6K', label: tr(gujarati, 'Members', 'α¬╕α¬¡α½ìα¬»α½ï')), _StatBox(number: '86', label: tr(gujarati, 'Villages', 'α¬ùα¬╛α¬«α½ï')), _StatBox(number: '9', label: tr(gujarati, 'Generations', 'α¬¬α½çα¬óα½Çα¬ô'))]);
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
  Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), leading: _InitialAvatar(initials: initials, color: color, size: 43), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(occupation, style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), if (city.isNotEmpty) Text('≡ƒôì $city', style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]), trailing: compact ? null : IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message request sent to $name'))), icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppPalette.peacock)));
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
  Widget build(BuildContext context) => SurfaceCard(padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 76, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .35)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))), padding: const EdgeInsets.all(11), alignment: Alignment.topLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(10)), child: Text(category, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10.5)))), Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 6), Wrap(spacing: 14, runSpacing: 4, children: [Text('≡ƒôà $date', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), Text('≡ƒôì $city', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk))]), const SizedBox(height: 12), Row(children: [Expanded(child: Text('≡ƒæÑ $attending ${tr(gujarati, 'attending', 'α¬╕α¬¡α½ìα¬»α½ï α¬╣α¬╛α¬£α¬░')}', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk))), FilledButton(onPressed: going ? null : onRsvp, style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: const Size(0, 36)), child: Text(going ? tr(gujarati, 'Going Γ£ô', 'α¬╣α¬╛α¬£α¬░ Γ£ô') : tr(gujarati, 'RSVP', 'RSVP'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))])]))]));
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
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF155218)]), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x262E7D32), blurRadius: 16, offset: Offset(0, 6))]), child: Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('KUTUMB\nSETU', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, height: 1.0)), SizedBox(height: 16), Text('Digital Community ID', style: TextStyle(color: Color(0xDFFFFFFF), fontSize: 10.5))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(width: 43, height: 43, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)), child: const Icon(Icons.qr_code_2_rounded, color: AppPalette.forest, size: 34)), const SizedBox(height: 12), Text(familyId, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(gujarati ? 'α¬¼α¬╛α¬¼α¬░α¬┐α¬»α¬╛α¬╡α¬╛α¬í α¬ªα¬░α¬£α½Ç α¬╕α¬«α¬╛α¬£' : 'Babariawad Darji Samaj', style: const TextStyle(color: Color(0xDFFFFFFF), fontSize: 10))])])));
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
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppPalette.divider)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, .32)!]), borderRadius: const BorderRadius.vertical(top: Radius.circular(17))), alignment: Alignment.center, child: Stack(alignment: Alignment.center, children: [Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)), Positioned(right: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(7)), child: const Text('≡ƒÄÑ 0:30', style: TextStyle(color: Colors.white, fontSize: 9)))])])), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)), const SizedBox(height: 3), Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk)), const SizedBox(height: 4), Text('≡ƒôì $city', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppPalette.softInk))]))])));
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
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(gujarati, 'Add family member', 'α¬¿α¬╡α¬╛ α¬╕α¬¡α½ìα¬» α¬ëα¬«α½çα¬░α½ï'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(tr(gujarati, 'Family-head or administrator approval is required. Submit the personΓÇÖs name and relationship to start the review.', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α¬╛ α¬«α½üα¬ûα½ìα¬» α¬╕α¬¡α½ìα¬» α¬àα¬Ñα¬╡α¬╛ α¬Åα¬íα¬«α¬┐α¬¿α¬¿α½Ç α¬«α¬éα¬£α½éα¬░α½Ç α¬£α¬░α½éα¬░α½Ç α¬¢α½ç. α¬╡α½ìα¬»α¬òα½ìα¬ñα¬┐α¬¿α½üα¬é α¬¿α¬╛α¬« α¬àα¬¿α½ç α¬╕α¬éα¬¼α¬éα¬º α¬åα¬¬α½Ç α¬╕α¬«α½Çα¬òα½ìα¬╖α¬╛ α¬╢α¬░α½é α¬òα¬░α½ï.'), style: const TextStyle(color: AppPalette.softInk, height: 1.4)), const SizedBox(height: 15), FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gujarati, 'Request form opened.', 'α¬╡α¬┐α¬¿α¬éα¬ñα½Ç α¬½α½ïα¬░α½ìα¬« α¬ûα½ïα¬▓α¬╛α¬»α½üα¬é.')))); }, style: FilledButton.styleFrom(backgroundColor: AppPalette.forest, minimumSize: const Size.fromHeight(46)), child: Text(tr(gujarati, 'Start request', 'α¬╡α¬┐α¬¿α¬éα¬ñα½Ç α¬╢α¬░α½é α¬òα¬░α½ï')))]));
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
