import 'package:flutter/material.dart';

import 'main.dart' show AppPalette, tr;

class DemoMatch {
  const DemoMatch(this.initials, this.name, this.age, this.height, this.education,
      this.occupation, this.village, this.city, this.match, this.color);
  final String initials, name, education, occupation, village, city;
  final int age, height, match;
  final Color color;
}

const _matches = [
  DemoMatch('NC', 'Nikita Chauhan', 26, 165, 'MBA, Marketing', 'Marketing Manager', 'Karamsad', 'Ahmedabad', 92, AppPalette.pink),
  DemoMatch('KP', 'Kevin Parekh', 29, 178, 'B.E. Civil', 'Civil Engineer', 'Bardoli', 'Surat', 89, AppPalette.peacock),
  DemoMatch('PT', 'Priya Trivedi', 24, 160, 'MBBS', 'Doctor', 'Gondal', 'Rajkot', 86, AppPalette.forest),
  DemoMatch('RJ', 'Rohan Joshi', 31, 175, 'CA', 'Chartered Accountant', 'Dhrol', 'Vadodara', 84, AppPalette.gold),
];

class MatrimonialHubPage extends StatefulWidget {
  const MatrimonialHubPage({super.key, required this.gujarati, required this.onLanguageChanged});
  final bool gujarati;
  final VoidCallback onLanguageChanged;
  @override
  State<MatrimonialHubPage> createState() => _MatrimonialHubPageState();
}

class _MatrimonialHubPageState extends State<MatrimonialHubPage> {
  late bool _gu;
  @override
  void initState() { super.initState(); _gu = widget.gujarati; }
  void _language() { setState(() => _gu = !_gu); widget.onLanguageChanged(); }
  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.search_rounded, tr(_gu, 'Search Profiles', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬╢α½ïα¬ºα½ï'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Search Profiles', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬╢α½ïα¬ºα½ï'), showSearch: true))),
      (Icons.favorite_rounded, tr(_gu, 'Recommended Matches', 'α¬¡α¬▓α¬╛α¬«α¬ú α¬òα¬░α½çα¬▓ α¬«α½çα¬Ü'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Recommended Matches', 'α¬¡α¬▓α¬╛α¬«α¬ú α¬òα¬░α½çα¬▓ α¬«α½çα¬Ü'), recommended: true))),
      (Icons.view_list_rounded, tr(_gu, 'Browse All Profiles', 'α¬¼α¬ºα½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬£α½üα¬ô'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Browse All Profiles', 'α¬¼α¬ºα½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬£α½üα¬ô')))),
      (Icons.edit_note_rounded, tr(_gu, 'Create / Update Biodata', 'α¬¼α¬╛α¬»α½ïα¬íα½çα¬ƒα¬╛ α¬¼α¬¿α¬╛α¬╡α½ï / α¬¼α¬ªα¬▓α½ï'), () => _open(BiodataPage(gujarati: _gu))),
      (Icons.mark_email_unread_rounded, tr(_gu, 'Requests Received', 'α¬«α¬│α½çα¬▓α½Ç α¬╡α¬┐α¬¿α¬éα¬ñα½Çα¬ô'), () => _open(RequestsPage(gujarati: _gu, received: true))),
      (Icons.outgoing_mail_rounded, tr(_gu, 'Requests Sent', 'α¬«α½ïα¬òα¬▓α½çα¬▓α½Ç α¬╡α¬┐α¬¿α¬éα¬ñα½Çα¬ô'), () => _open(RequestsPage(gujarati: _gu))),
      (Icons.star_rounded, tr(_gu, 'Shortlisted Profiles', 'α¬¬α¬╕α¬éα¬ª α¬òα¬░α½çα¬▓α½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Shortlisted Profiles', 'α¬¬α¬╕α¬éα¬ª α¬òα¬░α½çα¬▓α½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓'), profiles: _matches.take(2).toList()))),
      (Icons.event_rounded, tr(_gu, 'Marriage Events', 'α¬▓α¬ùα½ìα¬¿ α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï'), () => _open(MarriageEventsPage(gujarati: _gu))),
      (Icons.auto_stories_rounded, tr(_gu, 'Success Stories', 'α¬╕α¬½α¬│ α¬╡α¬╛α¬░α½ìα¬ñα¬╛α¬ô'), () => _open(SuccessStoriesPage(gujarati: _gu))),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.pink, foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(_gu, 'Matrimony', 'α¬▓α¬ùα½ìα¬¿ α¬╡α¬┐α¬╖α¬»α¬ò'), style: const TextStyle(fontWeight: FontWeight.w800)), Text(tr(_gu, 'Babariawad Darji Samaj', 'α¬¼α¬╛α¬¼α¬░α¬┐α¬»α¬╛α¬╡α¬╛α¬í α¬ªα¬░α¬£α½Ç α¬╕α¬«α¬╛α¬£'), style: const TextStyle(fontSize: 11))]),
        actions: [IconButton(onPressed: _language, icon: const Icon(Icons.language_rounded)), PopupMenuButton<String>(onSelected: (v) { if (v == 'admin') _open(AdminMatrimonyPage(gujarati: _gu)); }, itemBuilder: (_) => [PopupMenuItem(value: 'admin', child: Text(tr(_gu, 'Admin moderation', 'α¬Åα¬íα¬«α¬┐α¬¿ α¬«α½ïα¬íα¬░α½çα¬╢α¬¿')))])],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFEAF3), borderRadius: BorderRadius.circular(18)), child: Row(children: [const Icon(Icons.shield_outlined, color: AppPalette.pink), const SizedBox(width: 12), Expanded(child: Text(tr(_gu, 'Privacy-first matching. Contact details remain hidden until an interest is accepted or the owner allows it.', 'α¬ùα½ïα¬¬α¬¿α½Çα¬»α¬ñα¬╛-α¬¬α½ìα¬░α¬Ñα¬« α¬«α½çα¬Üα¬┐α¬éα¬ù. α¬░α¬╕ α¬╕α½ìα¬╡α½Çα¬òα¬╛α¬░α¬╛α¬» α¬àα¬Ñα¬╡α¬╛ α¬«α¬╛α¬▓α¬┐α¬ò α¬«α¬éα¬£α½éα¬░α½Ç α¬åα¬¬α½ç α¬ñα½ìα¬»α¬╛α¬é α¬╕α½üα¬ºα½Ç α¬╕α¬éα¬¬α¬░α½ìα¬ò α¬╡α¬┐α¬ùα¬ñα½ï α¬¢α½üα¬¬α¬╛α¬»α½çα¬▓α½Ç α¬░α¬╣α½ç α¬¢α½ç.'), style: const TextStyle(fontSize: 12.5, height: 1.35)))])),
        const SizedBox(height: 18),
        Text(tr(_gu, 'Find a meaningful connection', 'α¬àα¬░α½ìα¬Ñα¬¬α½éα¬░α½ìα¬ú α¬╕α¬éα¬¼α¬éα¬º α¬╢α½ïα¬ºα½ï'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 4), Text(tr(_gu, 'Family-guided profiles, secure interest requests and verified community matches.', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α¬╛ α¬«α¬╛α¬░α½ìα¬ùα¬ªα¬░α½ìα¬╢α¬¿ α¬╕α¬╛α¬Ñα½çα¬¿α½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓, α¬╕α½üα¬░α¬òα½ìα¬╖α¬┐α¬ñ α¬╡α¬┐α¬¿α¬éα¬ñα½Çα¬ô α¬àα¬¿α½ç α¬Üα¬òα¬╛α¬╕α½çα¬▓ α¬╕α¬╛α¬«α¬╛α¬£α¬┐α¬ò α¬«α½çα¬Ü.'), style: const TextStyle(color: AppPalette.softInk)),
        const SizedBox(height: 18),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.12, children: [for (final f in features) _HubTile(icon: f.$1, label: f.$2, onTap: f.$3)]),
        const SizedBox(height: 22),
        Text(tr(_gu, 'Γ¥ñ∩╕Å Recommended for you', 'Γ¥ñ∩╕Å α¬ñα¬«α¬╛α¬░α¬╛ α¬«α¬╛α¬ƒα½ç α¬¡α¬▓α¬╛α¬«α¬ú'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 10),
        ..._matches.take(2).map((m) => Padding(padding: const EdgeInsets.only(bottom: 10), child: MatchCard(match: m, gujarati: _gu, onView: () => _open(ProfileDetailPage(gujarati: _gu, profile: m))))),
      ]),
    );
  }
}

class ProfileListPage extends StatefulWidget {
  const ProfileListPage({super.key, required this.gujarati, required this.title, this.profiles = _matches, this.recommended = false, this.showSearch = false});
  final bool gujarati, recommended, showSearch;
  final String title;
  final List<DemoMatch> profiles;
  @override
  State<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends State<ProfileListPage> {
  final _search = TextEditingController();
  bool _shortlisted = false;
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final gu = widget.gujarati;
    final query = _search.text.trim().toLowerCase();
    final visibleProfiles = query.isEmpty
        ? widget.profiles
        : widget.profiles.where((m) => '${m.name} ${m.village} ${m.city} ${m.education} ${m.occupation}'.toLowerCase().contains(query)).toList();
    return Scaffold(appBar: AppBar(title: Text(widget.title), actions: [IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () => showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => AdvancedFilters(gujarati: gu)))]), body: ListView(padding: const EdgeInsets.all(16), children: [
      if (widget.recommended) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppPalette.forestTint, borderRadius: BorderRadius.circular(14)), child: Text(tr(gu, 'AI recommendations use age, education, occupation, city, village and family preferences.', 'AI α¬¡α¬▓α¬╛α¬«α¬úα½ï α¬ëα¬éα¬«α¬░, α¬àα¬¡α½ìα¬»α¬╛α¬╕, α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬», α¬╢α¬╣α½çα¬░, α¬ùα¬╛α¬« α¬àα¬¿α½ç α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α½Ç α¬¬α¬╕α¬éα¬ª α¬¬α¬░ α¬åα¬ºα¬╛α¬░α¬┐α¬ñ α¬¢α½ç.'), style: const TextStyle(fontSize: 12, height: 1.35))),
      if (widget.showSearch) TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr(gu, 'Name, village, city, education or occupation', 'α¬¿α¬╛α¬«, α¬ùα¬╛α¬«, α¬╢α¬╣α½çα¬░, α¬àα¬¡α½ìα¬»α¬╛α¬╕ α¬àα¬Ñα¬╡α¬╛ α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'))),
      if (widget.showSearch) const SizedBox(height: 14),
      ...visibleProfiles.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MatchCard(match: m, gujarati: gu, shortlisted: _shortlisted, onShortlist: () => setState(() => _shortlisted = !_shortlisted), onView: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailPage(gujarati: gu, profile: m)))))),
      if (visibleProfiles.isEmpty) Padding(padding: const EdgeInsets.only(top: 56), child: Center(child: Text(tr(gu, 'No matching profiles found.', 'α¬òα½ïα¬ê α¬«α½çα¬│ α¬ûα¬╛α¬ñα½Ç α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬«α¬│α½Ç α¬¿α¬Ñα½Ç.'), style: const TextStyle(color: AppPalette.softInk)))),
    ]));
  }
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.gujarati, required this.onView, this.onShortlist, this.shortlisted = false});
  final DemoMatch match; final bool gujarati, shortlisted; final VoidCallback onView; final VoidCallback? onShortlist;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    CircleAvatar(radius: 34, backgroundColor: match.color, child: Text(match.initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(match.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppPalette.forestTint, borderRadius: BorderRadius.circular(10)), child: Text('${match.match}% ${tr(gujarati, 'Match', 'α¬«α½çα¬Ü')}', style: const TextStyle(color: AppPalette.forest, fontSize: 10, fontWeight: FontWeight.w800)))]), const SizedBox(height: 4), Text('${match.age} ${tr(gujarati, 'years', 'α¬╡α¬░α½ìα¬╖')} ┬╖ ${match.height} cm ┬╖ ${match.village}', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), Text('${match.education} ┬╖ ${match.occupation}', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), const SizedBox(height: 9), Wrap(spacing: 6, children: [TextButton.icon(onPressed: onShortlist, icon: Icon(shortlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 17), label: Text(tr(gujarati, 'Shortlist', 'α¬¬α¬╕α¬éα¬ª')), style: TextButton.styleFrom(foregroundColor: AppPalette.pink, padding: EdgeInsets.zero)), TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_outlined, size: 17), label: Text(tr(gujarati, 'View', 'α¬£α½üα¬ô')), style: TextButton.styleFrom(padding: EdgeInsets.zero)), TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gujarati, 'Interest sent. Contact details will remain private until acceptance.', 'α¬░α¬╕ α¬«α½ïα¬òα¬▓α¬╡α¬╛α¬«α¬╛α¬é α¬åα¬╡α½ìα¬»α½ï. α¬╕α½ìα¬╡α½Çα¬òα¬╛α¬░α½ìα¬»α¬╛ α¬╕α½üα¬ºα½Ç α¬╕α¬éα¬¬α¬░α½ìα¬ò α¬╡α¬┐α¬ùα¬ñα½ï α¬ûα¬╛α¬¿α¬ùα½Ç α¬░α¬╣α½çα¬╢α½ç.')))), icon: const Icon(Icons.outgoing_mail_rounded, size: 17), label: Text(tr(gujarati, 'Interest', 'α¬░α¬╕')), style: TextButton.styleFrom(padding: EdgeInsets.zero))])]))]));
}

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key, required this.gujarati, required this.profile});
  final bool gujarati; final DemoMatch profile;
  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool shortlisted = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.profile; final gu = widget.gujarati;
    return Scaffold(appBar: AppBar(title: Text(tr(gu, 'Profile', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓')), actions: [IconButton(onPressed: () => _report(context, gu), icon: const Icon(Icons.flag_outlined))]), body: ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: CircleAvatar(radius: 52, backgroundColor: p.color, child: Text(p.initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)))), const SizedBox(height: 12),
      Center(child: Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), Center(child: Text('${p.age} ${tr(gu, 'years', 'α¬╡α¬░α½ìα¬╖')} ┬╖ ${p.village}', style: const TextStyle(color: AppPalette.softInk))), const SizedBox(height: 16),
      VideoIntroduction(profile: p, gujarati: gu), const SizedBox(height: 16),
      _detailSection(tr(gu, 'Personal details', 'α¬╡α½ìα¬»α¬òα½ìα¬ñα¬┐α¬ùα¬ñ α¬«α¬╛α¬╣α¬┐α¬ñα½Ç'), ['${tr(gu, 'Age', 'α¬ëα¬éα¬«α¬░')}: ${p.age}', '${tr(gu, 'Height', 'α¬èα¬éα¬Üα¬╛α¬ê')}: ${p.height} cm', '${tr(gu, 'Blood group', 'α¬¼α½ìα¬▓α¬í α¬ùα½ìα¬░α½üα¬¬')}: B+', '${tr(gu, 'Marital status', 'α¬╡α½êα¬╡α¬╛α¬╣α¬┐α¬ò α¬╕α½ìα¬Ñα¬┐α¬ñα¬┐')}: Never married']),
      _detailSection(tr(gu, 'Education & occupation', 'α¬àα¬¡α½ìα¬»α¬╛α¬╕ α¬àα¬¿α½ç α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'), [p.education, p.occupation, '${tr(gu, 'Company', 'α¬òα¬éα¬¬α¬¿α½Ç')}: ${p.name.split(' ').first} Group']),
      _detailSection(tr(gu, 'Family details', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α½Ç α¬«α¬╛α¬╣α¬┐α¬ñα½Ç'), [tr(gu, 'Father: Maheshbhai ┬╖ Mother: Kiranben', 'α¬¬α¬┐α¬ñα¬╛: α¬«α¬╣α½çα¬╢α¬¡α¬╛α¬ê ┬╖ α¬«α¬╛α¬ñα¬╛: α¬òα¬┐α¬░α¬úα¬¼α½çα¬¿'), tr(gu, 'Grandparents featured in introduction video', 'α¬ªα¬╛α¬ªα¬╛-α¬ªα¬╛α¬ªα½Ç α¬¬α¬░α¬┐α¬Üα¬» α¬╡α¬┐α¬íα¬┐α¬»α½ïα¬«α¬╛α¬é α¬ªα¬░α½ìα¬╢α¬╛α¬╡α½ìα¬»α¬╛ α¬¢α½ç'), '${tr(gu, 'Family type', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬¬α½ìα¬░α¬òα¬╛α¬░')}: Joint']),
      _detailSection(tr(gu, 'Lifestyle & preferences', 'α¬£α½Çα¬╡α¬¿α¬╢α½êα¬▓α½Ç α¬àα¬¿α½ç α¬¬α¬╕α¬éα¬ª'), [tr(gu, 'Vegetarian ┬╖ Non-smoker ┬╖ No alcohol', 'α¬╢α¬╛α¬òα¬╛α¬╣α¬╛α¬░α½Ç ┬╖ α¬ºα½éα¬«α½ìα¬░α¬¬α¬╛α¬¿ α¬¿α¬╣α½Çα¬é ┬╖ α¬ªα¬╛α¬░α½é α¬¿α¬╣α½Çα¬é'), tr(gu, 'Prefers educated, family-oriented partner', 'α¬¡α¬úα½çα¬▓α¬╛, α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬▓α¬òα½ìα¬╖α½Ç α¬£α½Çα¬╡α¬¿α¬╕α¬╛α¬Ñα½Çα¬¿α½Ç α¬¬α¬╕α¬éα¬ª')]),
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFFFF3E3), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.lock_outline_rounded, color: AppPalette.saffron), const SizedBox(width: 10), Expanded(child: Text(tr(gu, 'Phone, email and address are hidden. They can be shared only after interest acceptance or by this profile owner.', 'α¬½α½ïα¬¿, α¬çα¬«α½çα¬▓ α¬àα¬¿α½ç α¬╕α¬░α¬¿α¬╛α¬«α½üα¬é α¬¢α½üα¬¬α¬╛α¬╡α½çα¬▓ α¬¢α½ç. α¬░α¬╕ α¬╕α½ìα¬╡α½Çα¬òα¬╛α¬░α½ìα¬»α¬╛ α¬¬α¬¢α½Ç α¬àα¬Ñα¬╡α¬╛ α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬«α¬╛α¬▓α¬┐α¬òα¬¿α½Ç α¬«α¬éα¬£α½éα¬░α½Çα¬Ñα½Ç α¬£ α¬╢α½çα¬░ α¬Ñα¬╢α½ç.'), style: const TextStyle(fontSize: 11.5, height: 1.35)))])), const SizedBox(height: 14),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => shortlisted = !shortlisted), icon: Icon(shortlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded), label: Text(tr(gu, 'Shortlist', 'α¬¬α¬╕α¬éα¬ª')))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest sent for family review.', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬╕α¬«α½Çα¬òα½ìα¬╖α¬╛ α¬«α¬╛α¬ƒα½ç α¬░α¬╕ α¬«α½ïα¬òα¬▓α½ìα¬»α½ï.')))), icon: const Icon(Icons.outgoing_mail_rounded), label: Text(tr(gu, 'Send interest', 'α¬░α¬╕ α¬«α½ïα¬òα¬▓α½ï')), style: FilledButton.styleFrom(backgroundColor: AppPalette.pink)))])
    ]));
  }
  Widget _detailSection(String title, List<String> rows) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), ...rows.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: const TextStyle(fontSize: 12.5, color: AppPalette.softInk))))) ])));
  void _report(BuildContext context, bool gu) => showDialog(context: context, builder: (_) => AlertDialog(title: Text(tr(gu, 'Report profile', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬░α¬┐α¬¬α½ïα¬░α½ìα¬ƒ α¬òα¬░α½ï')), content: Text(tr(gu, 'Reports are reviewed by community administrators.', 'α¬░α¬┐α¬¬α½ïα¬░α½ìα¬ƒα¬¿α½Ç α¬╕α¬«α¬╛α¬£ α¬Åα¬íα¬«α¬┐α¬¿ α¬ªα½ìα¬╡α¬╛α¬░α¬╛ α¬╕α¬«α½Çα¬òα½ìα¬╖α¬╛ α¬òα¬░α¬╡α¬╛α¬«α¬╛α¬é α¬åα¬╡α½ç α¬¢α½ç.')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(gu, 'Cancel', 'α¬░α¬ª α¬òα¬░α½ï'))), FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Report submitted.', 'α¬░α¬┐α¬¬α½ïα¬░α½ìα¬ƒ α¬«α½ïα¬òα¬▓α¬╛α¬»α½ï.')))); }, child: Text(tr(gu, 'Report', 'α¬░α¬┐α¬¬α½ïα¬░α½ìα¬ƒ')))]));
}

class VideoIntroduction extends StatefulWidget {
  const VideoIntroduction({super.key, required this.profile, required this.gujarati});
  final DemoMatch profile; final bool gujarati;
  @override
  State<VideoIntroduction> createState() => _VideoIntroductionState();
}

class _VideoIntroductionState extends State<VideoIntroduction> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30)); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final gu = widget.gujarati;
    return AnimatedBuilder(animation: _controller, builder: (_, __) { final second = (_controller.value * 30).floor(); final chapter = second < 10 ? tr(gu, 'Profile introduction', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬¬α¬░α¬┐α¬Üα¬»') : second < 18 ? tr(gu, 'Parents & family', 'α¬«α¬╛α¬ñα¬╛-α¬¬α¬┐α¬ñα¬╛ α¬àα¬¿α½ç α¬¬α¬░α¬┐α¬╡α¬╛α¬░') : second < 24 ? tr(gu, 'Grandparents & roots', 'α¬ªα¬╛α¬ªα¬╛-α¬ªα¬╛α¬ªα½Ç α¬àα¬¿α½ç α¬«α½éα¬│') : tr(gu, 'Education & occupation', 'α¬àα¬¡α½ìα¬»α¬╛α¬╕ α¬àα¬¿α½ç α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'); return Container(height: 205, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.profile.color, Color.lerp(widget.profile.color, Colors.black, .48)!]), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 28), const SizedBox(width: 8), Text(tr(gu, '30 sec Family Introduction', '30 α¬╕α½çα¬òα¬¿α½ìα¬í α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬¬α¬░α¬┐α¬Üα¬»'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const Spacer(), Text('0:${second.toString().padLeft(2, '0')} / 0:30', style: const TextStyle(color: Colors.white, fontSize: 11))]), const Spacer(), Text(chapter, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(_caption(second, gu), style: const TextStyle(color: Colors.white, height: 1.3)), const Spacer(), LinearProgressIndicator(value: _controller.value, backgroundColor: Colors.white38, color: Colors.white), const SizedBox(height: 8), Center(child: IconButton(onPressed: () => _controller.isAnimating ? _controller.stop() : _controller.forward(from: _controller.value == 1 ? 0 : _controller.value), icon: Icon(_controller.isAnimating ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 38)))])); });
  }
  String _caption(int second, bool gu) { if (second < 10) return tr(gu, '${widget.profile.name}, ${widget.profile.age}, from ${widget.profile.village}.', '${widget.profile.name}, ${widget.profile.age}, ${widget.profile.village}α¬Ñα½Ç.'); if (second < 18) return tr(gu, 'Meet the parents and learn about their family values.', 'α¬«α¬╛α¬ñα¬╛-α¬¬α¬┐α¬ñα¬╛α¬¿α½ç α¬«α¬│α½ï α¬àα¬¿α½ç α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α¬╛ α¬«α½éα¬▓α½ìα¬»α½ï α¬£α¬╛α¬úα½ï.'); if (second < 24) return tr(gu, 'A glimpse of grandparents and family roots.', 'α¬ªα¬╛α¬ªα¬╛-α¬ªα¬╛α¬ªα½Ç α¬àα¬¿α½ç α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α¬╛ α¬«α½éα¬│α¬¿α½Ç α¬¥α¬▓α¬ò.'); return tr(gu, '${widget.profile.education} ┬╖ ${widget.profile.occupation}.', '${widget.profile.education} ┬╖ ${widget.profile.occupation}.'); }
}

class BiodataPage extends StatefulWidget { const BiodataPage({super.key, required this.gujarati}); final bool gujarati; @override State<BiodataPage> createState() => _BiodataPageState(); }
class _BiodataPageState extends State<BiodataPage> {
  bool phone = false, email = false, address = false;
  @override Widget build(BuildContext context) { final gu = widget.gujarati; return Scaffold(appBar: AppBar(title: Text(tr(gu, 'Create / Update Biodata', 'α¬¼α¬╛α¬»α½ïα¬íα½çα¬ƒα¬╛ α¬¼α¬¿α¬╛α¬╡α½ï / α¬¼α¬ªα¬▓α½ï'))), body: ListView(padding: const EdgeInsets.all(16), children: [
    _formGroup(tr(gu, 'Personal information', 'α¬╡α½ìα¬»α¬òα½ìα¬ñα¬┐α¬ùα¬ñ α¬«α¬╛α¬╣α¬┐α¬ñα½Ç'), [tr(gu, 'Full name', 'α¬¬α½éα¬░α½üα¬é α¬¿α¬╛α¬«'), tr(gu, 'Profile photo', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬½α½ïα¬ƒα½ï'), tr(gu, 'Date of birth (age is auto calculated)', 'α¬£α¬¿α½ìα¬« α¬ñα¬╛α¬░α½Çα¬û (α¬ëα¬éα¬«α¬░ α¬åα¬¬α¬«α½çα¬│α½ç)'), tr(gu, 'Gender', 'α¬▓α¬┐α¬éα¬ù'), tr(gu, 'Height / Weight', 'α¬èα¬éα¬Üα¬╛α¬ê / α¬╡α¬£α¬¿'), tr(gu, 'Blood group', 'α¬¼α½ìα¬▓α¬í α¬ùα½ìα¬░α½üα¬¬'), tr(gu, 'Marital status', 'α¬╡α½êα¬╡α¬╛α¬╣α¬┐α¬ò α¬╕α½ìα¬Ñα¬┐α¬ñα¬┐'), tr(gu, 'Disability, if any', 'α¬ªα¬┐α¬╡α½ìα¬»α¬╛α¬éα¬ùα¬ñα¬╛, α¬£α½ï α¬╣α½ïα¬» α¬ñα½ï')]),
    _formGroup(tr(gu, 'Education & work', 'α¬àα¬¡α½ìα¬»α¬╛α¬╕ α¬àα¬¿α½ç α¬òα¬╛α¬░α½ìα¬»'), [tr(gu, 'Highest qualification', 'α¬╕α¬░α½ìα¬╡α½ïα¬Üα½ìα¬Ü α¬▓α¬╛α¬»α¬òα¬╛α¬ñ'), tr(gu, 'College', 'α¬òα½ïα¬▓α½çα¬£'), tr(gu, 'Profession / Occupation', 'α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬» / α¬¿α½ïα¬òα¬░α½Ç'), tr(gu, 'Company', 'α¬òα¬éα¬¬α¬¿α½Ç'), tr(gu, 'Annual income', 'α¬╡α¬╛α¬░α½ìα¬╖α¬┐α¬ò α¬åα¬╡α¬ò')]),
    _formGroup(tr(gu, 'Family information', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α½Ç α¬«α¬╛α¬╣α¬┐α¬ñα½Ç'), [tr(gu, "Father's name", 'α¬¬α¬┐α¬ñα¬╛α¬¿α½üα¬é α¬¿α¬╛α¬«'), tr(gu, "Mother's name", 'α¬«α¬╛α¬ñα¬╛α¬¿α½üα¬é α¬¿α¬╛α¬«'), tr(gu, 'Family name', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α½üα¬é α¬¿α¬╛α¬«'), tr(gu, 'Native village / Current city', 'α¬╡α¬ñα¬¿ α¬ùα¬╛α¬« / α¬╣α¬╛α¬▓α¬¿α½üα¬é α¬╢α¬╣α½çα¬░'), tr(gu, 'Family type', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬¬α½ìα¬░α¬òα¬╛α¬░'), tr(gu, 'Brothers / Sisters', 'α¬¡α¬╛α¬êα¬ô / α¬¼α¬╣α½çα¬¿α½ï')]),
    _formGroup(tr(gu, 'Lifestyle', 'α¬£α½Çα¬╡α¬¿α¬╢α½êα¬▓α½Ç'), [tr(gu, 'Diet', 'α¬åα¬╣α¬╛α¬░'), tr(gu, 'Smoking / Drinking', 'α¬ºα½éα¬«α½ìα¬░α¬¬α¬╛α¬¿ / α¬ªα¬╛α¬░α½é'), tr(gu, 'Hobbies', 'α¬╢α½ïα¬û'), tr(gu, 'Languages known', 'α¬åα¬╡α¬íα¬ñα½Ç α¬¡α¬╛α¬╖α¬╛α¬ô')]),
    _formGroup(tr(gu, 'Partner preferences', 'α¬£α½Çα¬╡α¬¿α¬╕α¬╛α¬Ñα½Ç α¬¬α¬╕α¬éα¬ªα¬ùα½Ç'), [tr(gu, 'Preferred age range / height', 'α¬¬α¬╕α¬éα¬ªα¬¿α½Ç α¬ëα¬éα¬«α¬░ / α¬èα¬éα¬Üα¬╛α¬ê'), tr(gu, 'Preferred education / occupation', 'α¬¬α¬╕α¬éα¬ªα¬¿α½ï α¬àα¬¡α½ìα¬»α¬╛α¬╕ / α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'), tr(gu, 'Preferred city / village', 'α¬¬α¬╕α¬éα¬ªα¬¿α½üα¬é α¬╢α¬╣α½çα¬░ / α¬ùα¬╛α¬«'), tr(gu, 'Preferred marital status', 'α¬¬α¬╕α¬éα¬ªα¬¿α½Ç α¬╡α½êα¬╡α¬╛α¬╣α¬┐α¬ò α¬╕α½ìα¬Ñα¬┐α¬ñα¬┐')]),
    Card(child: Column(children: [SwitchListTile(value: phone, onChanged: (v) => setState(() => phone = v), title: Text(tr(gu, 'Show phone number', 'α¬½α½ïα¬¿ α¬¿α¬éα¬¼α¬░ α¬¼α¬ñα¬╛α¬╡α½ï'))), SwitchListTile(value: email, onChanged: (v) => setState(() => email = v), title: Text(tr(gu, 'Show email', 'α¬çα¬«α½çα¬▓ α¬¼α¬ñα¬╛α¬╡α½ï'))), SwitchListTile(value: address, onChanged: (v) => setState(() => address = v), title: Text(tr(gu, 'Show address', 'α¬╕α¬░α¬¿α¬╛α¬«α½üα¬é α¬¼α¬ñα¬╛α¬╡α½ï')))])), const SizedBox(height: 14), FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Biodata submitted for admin approval.', 'α¬¼α¬╛α¬»α½ïα¬íα½çα¬ƒα¬╛ α¬Åα¬íα¬«α¬┐α¬¿ α¬«α¬éα¬£α½éα¬░α½Ç α¬«α¬╛α¬ƒα½ç α¬«α½ïα¬òα¬▓α¬╛α¬»α½ï.')))), style: FilledButton.styleFrom(backgroundColor: AppPalette.pink, minimumSize: const Size.fromHeight(50)), child: Text(tr(gu, 'Submit biodata', 'α¬¼α¬╛α¬»α½ïα¬íα½çα¬ƒα¬╛ α¬«α½ïα¬òα¬▓α½ï')))
  ])); }
  Widget _formGroup(String title, List<String> labels) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...labels.map((e) => Padding(padding: const EdgeInsets.only(bottom: 9), child: TextField(decoration: InputDecoration(labelText: e, isDense: true))))])));
}

class AdvancedFilters extends StatelessWidget { const AdvancedFilters({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) { final labels = [tr(gujarati, 'Age and height', 'α¬ëα¬éα¬«α¬░ α¬àα¬¿α½ç α¬èα¬éα¬Üα¬╛α¬ê'), tr(gujarati, 'Education and occupation', 'α¬àα¬¡α½ìα¬»α¬╛α¬╕ α¬àα¬¿α½ç α¬╡α½ìα¬»α¬╡α¬╕α¬╛α¬»'), tr(gujarati, 'Income', 'α¬åα¬╡α¬ò'), tr(gujarati, 'City and village', 'α¬╢α¬╣α½çα¬░ α¬àα¬¿α½ç α¬ùα¬╛α¬«'), tr(gujarati, 'Marital status and family type', 'α¬╡α½êα¬╡α¬╛α¬╣α¬┐α¬ò α¬╕α½ìα¬Ñα¬┐α¬ñα¬┐ α¬àα¬¿α½ç α¬¬α¬░α¬┐α¬╡α¬╛α¬░ α¬¬α½ìα¬░α¬òα¬╛α¬░'), tr(gujarati, 'Diet', 'α¬åα¬╣α¬╛α¬░')]; return Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(gujarati, 'Advanced filters', 'α¬àα¬ªα½ìα¬»α¬ñα¬¿ α¬½α¬┐α¬▓α½ìα¬ƒα¬░'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...labels.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(decoration: InputDecoration(labelText: e, isDense: true)))), FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr(gujarati, 'Apply filters', 'α¬½α¬┐α¬▓α½ìα¬ƒα¬░ α¬▓α¬╛α¬ùα½ü α¬òα¬░α½ï')))])); } }

class RequestsPage extends StatefulWidget { const RequestsPage({super.key, required this.gujarati, this.received = false}); final bool gujarati, received; @override State<RequestsPage> createState() => _RequestsPageState(); }
class _RequestsPageState extends State<RequestsPage> with SingleTickerProviderStateMixin { late TabController tabs; @override void initState() { super.initState(); tabs = TabController(length: 5, vsync: this, initialIndex: widget.received ? 0 : 1); } @override void dispose() { tabs.dispose(); super.dispose(); } @override Widget build(BuildContext context) { final gu = widget.gujarati; final labels = [tr(gu, 'Received', 'α¬«α¬│α½çα¬▓α½Ç'), tr(gu, 'Sent', 'α¬«α½ïα¬òα¬▓α½çα¬▓α½Ç'), tr(gu, 'Pending', 'α¬¼α¬╛α¬òα½Ç'), tr(gu, 'Accepted', 'α¬╕α½ìα¬╡α½Çα¬òα¬╛α¬░α½çα¬▓α½Ç'), tr(gu, 'Rejected', 'α¬¿α¬òα¬╛α¬░α½çα¬▓α½Ç')]; return Scaffold(appBar: AppBar(title: Text(tr(gu, 'Interest requests', 'α¬░α¬╕ α¬╡α¬┐α¬¿α¬éα¬ñα½Çα¬ô')), bottom: TabBar(controller: tabs, isScrollable: true, tabs: [for(final x in labels) Tab(text: x)])), body: TabBarView(controller: tabs, children: [for (var i=0;i<5;i++) ListView(padding: const EdgeInsets.all(16), children: [Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AppPalette.pink, child: Text('NC', style: TextStyle(color: Colors.white))), title: const Text('Nikita Chauhan'), subtitle: Text(i == 0 ? tr(gu, 'Wants to connect through family-guided introduction.', 'α¬¬α¬░α¬┐α¬╡α¬╛α¬░α¬¿α¬╛ α¬«α¬╛α¬░α½ìα¬ùα¬ªα¬░α½ìα¬╢α¬¿α¬Ñα½Ç α¬¬α¬░α¬┐α¬Üα¬» α¬êα¬Üα½ìα¬¢α½ç α¬¢α½ç.') : tr(gu, 'Interest request status', 'α¬░α¬╕ α¬╡α¬┐α¬¿α¬éα¬ñα½Çα¬¿α½Ç α¬╕α½ìα¬Ñα¬┐α¬ñα¬┐')), trailing: i == 0 ? Wrap(spacing: 2, children: [IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest accepted. You may share contact details according to policy.', 'α¬░α¬╕ α¬╕α½ìα¬╡α½Çα¬òα¬╛α¬░α½ìα¬»α½ï. α¬¿α½Çα¬ñα¬┐ α¬àα¬¿α½üα¬╕α¬╛α¬░ α¬╕α¬éα¬¬α¬░α½ìα¬ò α¬╡α¬┐α¬ùα¬ñα½ï α¬╢α½çα¬░ α¬òα¬░α½Ç α¬╢α¬òα½ï α¬¢α½ï.')))), icon: const Icon(Icons.check_circle_rounded, color: AppPalette.forest)), IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest rejected.', 'α¬░α¬╕ α¬¿α¬òα¬╛α¬░α½ìα¬»α½ï.')))), icon: const Icon(Icons.cancel_rounded, color: AppPalette.pink))]) : null))]) ])); } }

class MarriageEventsPage extends StatelessWidget { const MarriageEventsPage({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) { final events = [tr(gujarati, 'Samuh Lagna Sammelan ┬╖ 18 July', 'α¬╕α¬«α½éα¬╣ α¬▓α¬ùα½ìα¬¿ α¬╕α¬éα¬«α½çα¬▓α¬¿ ┬╖ 18 α¬£α½üα¬▓α¬╛α¬ê'), tr(gujarati, 'Matrimonial Meet ┬╖ 9 August', 'α¬«α½çα¬ƒα½ìα¬░α¬┐α¬«α½ïα¬¿α¬┐α¬»α¬▓ α¬«α½Çα¬ƒ ┬╖ 9 α¬ôα¬ùα¬╕α½ìα¬ƒ'), tr(gujarati, 'Community Gathering ┬╖ 24 August', 'α¬╕α¬«α¬╛α¬£ α¬«α¬┐α¬▓α¬¿ ┬╖ 24 α¬ôα¬ùα¬╕α½ìα¬ƒ')]; return Scaffold(appBar: AppBar(title: Text(tr(gujarati, 'Marriage events', 'α¬▓α¬ùα½ìα¬¿ α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬«α½ï'))), body: ListView(padding: const EdgeInsets.all(16), children: [for(final e in events) Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AppPalette.saffron, child: Icon(Icons.event_rounded, color: Colors.white)), title: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(tr(gujarati, 'Community event ┬╖ RSVP available', 'α¬╕α¬«α¬╛α¬£ α¬òα¬╛α¬░α½ìα¬»α¬òα½ìα¬░α¬« ┬╖ RSVP α¬ëα¬¬α¬▓α¬¼α½ìα¬º')), trailing: FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gujarati, 'RSVP recorded.', 'RSVP α¬¿α½ïα¬éα¬ºα¬╛α¬»α½ï.')))), child: Text(tr(gujarati, 'RSVP', 'RSVP'))))])); } }

class SuccessStoriesPage extends StatelessWidget { const SuccessStoriesPage({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(tr(gujarati, 'Success stories', 'α¬╕α¬½α¬│ α¬╡α¬╛α¬░α½ìα¬ñα¬╛α¬ô'))), body: ListView(padding: const EdgeInsets.all(16), children: [for(final e in [('P', 'Priya Γ¥ñ∩╕Å Rohan', '12 February 2026'), ('N', 'Nikita Γ¥ñ∩╕Å Krupal', '23 November 2025')]) Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppPalette.pink, child: Text(e.$1, style: const TextStyle(color: Colors.white))), title: Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${tr(gujarati, 'Married', 'α¬▓α¬ùα½ìα¬¿')}: ${e.$3}'))])); }

class AdminMatrimonyPage extends StatelessWidget { const AdminMatrimonyPage({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) { final rows=[tr(gujarati, 'Approve profiles', 'α¬¬α½ìα¬░α½ïα¬½α¬╛α¬çα¬▓ α¬«α¬éα¬£α½éα¬░ α¬òα¬░α½ï'),tr(gujarati, 'Review fake or inactive accounts', 'α¬¿α¬òα¬▓α½Ç α¬àα¬Ñα¬╡α¬╛ α¬¿α¬┐α¬╖α½ìα¬òα½ìα¬░α¬┐α¬» α¬ûα¬╛α¬ñα¬╛α¬ô α¬ñα¬¬α¬╛α¬╕α½ï'),tr(gujarati, 'Moderate reports', 'α¬░α¬┐α¬¬α½ïα¬░α½ìα¬ƒα¬¿α½Ç α¬╕α¬«α½Çα¬òα½ìα¬╖α¬╛ α¬òα¬░α½ï'),tr(gujarati, 'View matching statistics', 'α¬«α½çα¬Üα¬┐α¬éα¬ù α¬åα¬éα¬òα¬íα¬╛ α¬£α½üα¬ô')]; return Scaffold(appBar: AppBar(title: Text(tr(gujarati, 'Matrimony admin', 'α¬«α½çα¬ƒα½ìα¬░α¬┐α¬«α½ïα¬¿α½Ç α¬Åα¬íα¬«α¬┐α¬¿'))), body: ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppPalette.peacockTint,borderRadius: BorderRadius.circular(14)), child: Text(tr(gujarati, 'Admin controls are restricted to authorised community moderators.', 'α¬Åα¬íα¬«α¬┐α¬¿ α¬¿α¬┐α¬»α¬éα¬ñα½ìα¬░α¬ú α¬«α¬╛α¬ñα½ìα¬░ α¬àα¬ºα¬┐α¬òα½âα¬ñ α¬╕α¬«α¬╛α¬£ α¬«α½ïα¬íα¬░α½çα¬ƒα¬░α½ìα¬╕ α¬«α¬╛α¬ƒα½ç α¬¢α½ç.'))), const SizedBox(height: 12), for(final r in rows) Card(child: ListTile(title: Text(r), trailing: const Icon(Icons.chevron_right_rounded)))])); } }

class _HubTile extends StatelessWidget { const _HubTile({required this.icon, required this.label, required this.onTap}); final IconData icon; final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Ink(decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.divider)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(backgroundColor: const Color(0xFFFFEAF3), child: Icon(icon,color: AppPalette.pink)), const Spacer(), Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))])))); }
