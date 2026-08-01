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
      (Icons.search_rounded, tr(_gu, 'Search Profiles', 'પ્રોફાઇલ શોધો'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Search Profiles', 'પ્રોફાઇલ શોધો'), showSearch: true))),
      (Icons.favorite_rounded, tr(_gu, 'Recommended Matches', 'ભલામણ કરેલ મેચ'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Recommended Matches', 'ભલામણ કરેલ મેચ'), recommended: true))),
      (Icons.view_list_rounded, tr(_gu, 'Browse All Profiles', 'બધી પ્રોફાઇલ જુઓ'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Browse All Profiles', 'બધી પ્રોફાઇલ જુઓ')))),
      (Icons.edit_note_rounded, tr(_gu, 'Create / Update Biodata', 'બાયોડેટા બનાવો / બદલો'), () => _open(BiodataPage(gujarati: _gu))),
      (Icons.mark_email_unread_rounded, tr(_gu, 'Requests Received', 'મળેલી વિનંતીઓ'), () => _open(RequestsPage(gujarati: _gu, received: true))),
      (Icons.outgoing_mail_rounded, tr(_gu, 'Requests Sent', 'મોકલેલી વિનંતીઓ'), () => _open(RequestsPage(gujarati: _gu))),
      (Icons.star_rounded, tr(_gu, 'Shortlisted Profiles', 'પસંદ કરેલી પ્રોફાઇલ'), () => _open(ProfileListPage(gujarati: _gu, title: tr(_gu, 'Shortlisted Profiles', 'પસંદ કરેલી પ્રોફાઇલ'), profiles: _matches.take(2).toList()))),
      (Icons.event_rounded, tr(_gu, 'Marriage Events', 'લગ્ન કાર્યક્રમો'), () => _open(MarriageEventsPage(gujarati: _gu))),
      (Icons.auto_stories_rounded, tr(_gu, 'Success Stories', 'સફળ વાર્તાઓ'), () => _open(SuccessStoriesPage(gujarati: _gu))),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPalette.pink, foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(_gu, 'Matrimony', 'લગ્ન વિષયક'), style: const TextStyle(fontWeight: FontWeight.w800)), Text(tr(_gu, 'Babariawad Darji Samaj', 'બાબરિયાવાડ દરજી સમાજ'), style: const TextStyle(fontSize: 11))]),
        actions: [IconButton(onPressed: _language, icon: const Icon(Icons.language_rounded)), PopupMenuButton<String>(onSelected: (v) { if (v == 'admin') _open(AdminMatrimonyPage(gujarati: _gu)); }, itemBuilder: (_) => [PopupMenuItem(value: 'admin', child: Text(tr(_gu, 'Admin moderation', 'એડમિન મોડરેશન')))])],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFEAF3), borderRadius: BorderRadius.circular(18)), child: Row(children: [const Icon(Icons.shield_outlined, color: AppPalette.pink), const SizedBox(width: 12), Expanded(child: Text(tr(_gu, 'Privacy-first matching. Contact details remain hidden until an interest is accepted or the owner allows it.', 'ગોપનીયતા-પ્રથમ મેચિંગ. રસ સ્વીકારાય અથવા માલિક મંજૂરી આપે ત્યાં સુધી સંપર્ક વિગતો છુપાયેલી રહે છે.'), style: const TextStyle(fontSize: 12.5, height: 1.35)))])),
        const SizedBox(height: 18),
        Text(tr(_gu, 'Find a meaningful connection', 'અર્થપૂર્ણ સંબંધ શોધો'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 4), Text(tr(_gu, 'Family-guided profiles, secure interest requests and verified community matches.', 'પરિવારના માર્ગદર્શન સાથેની પ્રોફાઇલ, સુરક્ષિત વિનંતીઓ અને ચકાસેલ સામાજિક મેચ.'), style: const TextStyle(color: AppPalette.softInk)),
        const SizedBox(height: 18),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.12, children: [for (final f in features) _HubTile(icon: f.$1, label: f.$2, onTap: f.$3)]),
        const SizedBox(height: 22),
        Text(tr(_gu, '❤️ Recommended for you', '❤️ તમારા માટે ભલામણ'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
      if (widget.recommended) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppPalette.forestTint, borderRadius: BorderRadius.circular(14)), child: Text(tr(gu, 'AI recommendations use age, education, occupation, city, village and family preferences.', 'AI ભલામણો ઉંમર, અભ્યાસ, વ્યવસાય, શહેર, ગામ અને પરિવારની પસંદ પર આધારિત છે.'), style: const TextStyle(fontSize: 12, height: 1.35))),
      if (widget.showSearch) TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr(gu, 'Name, village, city, education or occupation', 'નામ, ગામ, શહેર, અભ્યાસ અથવા વ્યવસાય'))),
      if (widget.showSearch) const SizedBox(height: 14),
      ...visibleProfiles.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MatchCard(match: m, gujarati: gu, shortlisted: _shortlisted, onShortlist: () => setState(() => _shortlisted = !_shortlisted), onView: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailPage(gujarati: gu, profile: m)))))),
      if (visibleProfiles.isEmpty) Padding(padding: const EdgeInsets.only(top: 56), child: Center(child: Text(tr(gu, 'No matching profiles found.', 'કોઈ મેળ ખાતી પ્રોફાઇલ મળી નથી.'), style: const TextStyle(color: AppPalette.softInk)))),
    ]));
  }
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.gujarati, required this.onView, this.onShortlist, this.shortlisted = false});
  final DemoMatch match; final bool gujarati, shortlisted; final VoidCallback onView; final VoidCallback? onShortlist;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    CircleAvatar(radius: 34, backgroundColor: match.color, child: Text(match.initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(match.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppPalette.forestTint, borderRadius: BorderRadius.circular(10)), child: Text('${match.match}% ${tr(gujarati, 'Match', 'મેચ')}', style: const TextStyle(color: AppPalette.forest, fontSize: 10, fontWeight: FontWeight.w800)))]), const SizedBox(height: 4), Text('${match.age} ${tr(gujarati, 'years', 'વર્ષ')} · ${match.height} cm · ${match.village}', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), Text('${match.education} · ${match.occupation}', style: const TextStyle(fontSize: 11.5, color: AppPalette.softInk)), const SizedBox(height: 9), Wrap(spacing: 6, children: [TextButton.icon(onPressed: onShortlist, icon: Icon(shortlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 17), label: Text(tr(gujarati, 'Shortlist', 'પસંદ')), style: TextButton.styleFrom(foregroundColor: AppPalette.pink, padding: EdgeInsets.zero)), TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_outlined, size: 17), label: Text(tr(gujarati, 'View', 'જુઓ')), style: TextButton.styleFrom(padding: EdgeInsets.zero)), TextButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gujarati, 'Interest sent. Contact details will remain private until acceptance.', 'રસ મોકલવામાં આવ્યો. સ્વીકાર્યા સુધી સંપર્ક વિગતો ખાનગી રહેશે.')))), icon: const Icon(Icons.outgoing_mail_rounded, size: 17), label: Text(tr(gujarati, 'Interest', 'રસ')), style: TextButton.styleFrom(padding: EdgeInsets.zero))])]))]));
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
    return Scaffold(appBar: AppBar(title: Text(tr(gu, 'Profile', 'પ્રોફાઇલ')), actions: [IconButton(onPressed: () => _report(context, gu), icon: const Icon(Icons.flag_outlined))]), body: ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: CircleAvatar(radius: 52, backgroundColor: p.color, child: Text(p.initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)))), const SizedBox(height: 12),
      Center(child: Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), Center(child: Text('${p.age} ${tr(gu, 'years', 'વર્ષ')} · ${p.village}', style: const TextStyle(color: AppPalette.softInk))), const SizedBox(height: 16),
      VideoIntroduction(profile: p, gujarati: gu), const SizedBox(height: 16),
      _detailSection(tr(gu, 'Personal details', 'વ્યક્તિગત માહિતી'), ['${tr(gu, 'Age', 'ઉંમર')}: ${p.age}', '${tr(gu, 'Height', 'ઊંચાઈ')}: ${p.height} cm', '${tr(gu, 'Blood group', 'બ્લડ ગ્રુપ')}: B+', '${tr(gu, 'Marital status', 'વૈવાહિક સ્થિતિ')}: Never married']),
      _detailSection(tr(gu, 'Education & occupation', 'અભ્યાસ અને વ્યવસાય'), [p.education, p.occupation, '${tr(gu, 'Company', 'કંપની')}: ${p.name.split(' ').first} Group']),
      _detailSection(tr(gu, 'Family details', 'પરિવારની માહિતી'), [tr(gu, 'Father: Maheshbhai · Mother: Kiranben', 'પિતા: મહેશભાઈ · માતા: કિરણબેન'), tr(gu, 'Grandparents featured in introduction video', 'દાદા-દાદી પરિચય વિડિયોમાં દર્શાવ્યા છે'), '${tr(gu, 'Family type', 'પરિવાર પ્રકાર')}: Joint']),
      _detailSection(tr(gu, 'Lifestyle & preferences', 'જીવનશૈલી અને પસંદ'), [tr(gu, 'Vegetarian · Non-smoker · No alcohol', 'શાકાહારી · ધૂમ્રપાન નહીં · દારૂ નહીં'), tr(gu, 'Prefers educated, family-oriented partner', 'ભણેલા, પરિવારલક્ષી જીવનસાથીની પસંદ')]),
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFFFF3E3), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.lock_outline_rounded, color: AppPalette.saffron), const SizedBox(width: 10), Expanded(child: Text(tr(gu, 'Phone, email and address are hidden. They can be shared only after interest acceptance or by this profile owner.', 'ફોન, ઇમેલ અને સરનામું છુપાવેલ છે. રસ સ્વીકાર્યા પછી અથવા પ્રોફાઇલ માલિકની મંજૂરીથી જ શેર થશે.'), style: const TextStyle(fontSize: 11.5, height: 1.35)))])), const SizedBox(height: 14),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => shortlisted = !shortlisted), icon: Icon(shortlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded), label: Text(tr(gu, 'Shortlist', 'પસંદ')))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest sent for family review.', 'પરિવાર સમીક્ષા માટે રસ મોકલ્યો.')))), icon: const Icon(Icons.outgoing_mail_rounded), label: Text(tr(gu, 'Send interest', 'રસ મોકલો')), style: FilledButton.styleFrom(backgroundColor: AppPalette.pink)))])
    ]));
  }
  Widget _detailSection(String title, List<String> rows) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), ...rows.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(e, style: const TextStyle(fontSize: 12.5, color: AppPalette.softInk))))) ])));
  void _report(BuildContext context, bool gu) => showDialog(context: context, builder: (_) => AlertDialog(title: Text(tr(gu, 'Report profile', 'પ્રોફાઇલ રિપોર્ટ કરો')), content: Text(tr(gu, 'Reports are reviewed by community administrators.', 'રિપોર્ટની સમાજ એડમિન દ્વારા સમીક્ષા કરવામાં આવે છે.')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(gu, 'Cancel', 'રદ કરો'))), FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Report submitted.', 'રિપોર્ટ મોકલાયો.')))); }, child: Text(tr(gu, 'Report', 'રિપોર્ટ')))]));
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
    return AnimatedBuilder(animation: _controller, builder: (_, __) { final second = (_controller.value * 30).floor(); final chapter = second < 10 ? tr(gu, 'Profile introduction', 'પ્રોફાઇલ પરિચય') : second < 18 ? tr(gu, 'Parents & family', 'માતા-પિતા અને પરિવાર') : second < 24 ? tr(gu, 'Grandparents & roots', 'દાદા-દાદી અને મૂળ') : tr(gu, 'Education & occupation', 'અભ્યાસ અને વ્યવસાય'); return Container(height: 205, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.profile.color, Color.lerp(widget.profile.color, Colors.black, .48)!]), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 28), const SizedBox(width: 8), Text(tr(gu, '30 sec Family Introduction', '30 સેકન્ડ પરિવાર પરિચય'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const Spacer(), Text('0:${second.toString().padLeft(2, '0')} / 0:30', style: const TextStyle(color: Colors.white, fontSize: 11))]), const Spacer(), Text(chapter, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(_caption(second, gu), style: const TextStyle(color: Colors.white, height: 1.3)), const Spacer(), LinearProgressIndicator(value: _controller.value, backgroundColor: Colors.white38, color: Colors.white), const SizedBox(height: 8), Center(child: IconButton(onPressed: () => _controller.isAnimating ? _controller.stop() : _controller.forward(from: _controller.value == 1 ? 0 : _controller.value), icon: Icon(_controller.isAnimating ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 38)))])); });
  }
  String _caption(int second, bool gu) { if (second < 10) return tr(gu, '${widget.profile.name}, ${widget.profile.age}, from ${widget.profile.village}.', '${widget.profile.name}, ${widget.profile.age}, ${widget.profile.village}થી.'); if (second < 18) return tr(gu, 'Meet the parents and learn about their family values.', 'માતા-પિતાને મળો અને પરિવારના મૂલ્યો જાણો.'); if (second < 24) return tr(gu, 'A glimpse of grandparents and family roots.', 'દાદા-દાદી અને પરિવારના મૂળની ઝલક.'); return tr(gu, '${widget.profile.education} · ${widget.profile.occupation}.', '${widget.profile.education} · ${widget.profile.occupation}.'); }
}

class BiodataPage extends StatefulWidget { const BiodataPage({super.key, required this.gujarati}); final bool gujarati; @override State<BiodataPage> createState() => _BiodataPageState(); }
class _BiodataPageState extends State<BiodataPage> {
  bool phone = false, email = false, address = false;
  @override Widget build(BuildContext context) { final gu = widget.gujarati; return Scaffold(appBar: AppBar(title: Text(tr(gu, 'Create / Update Biodata', 'બાયોડેટા બનાવો / બદલો'))), body: ListView(padding: const EdgeInsets.all(16), children: [
    _formGroup(tr(gu, 'Personal information', 'વ્યક્તિગત માહિતી'), [tr(gu, 'Full name', 'પૂરું નામ'), tr(gu, 'Profile photo', 'પ્રોફાઇલ ફોટો'), tr(gu, 'Date of birth (age is auto calculated)', 'જન્મ તારીખ (ઉંમર આપમેળે)'), tr(gu, 'Gender', 'લિંગ'), tr(gu, 'Height / Weight', 'ઊંચાઈ / વજન'), tr(gu, 'Blood group', 'બ્લડ ગ્રુપ'), tr(gu, 'Marital status', 'વૈવાહિક સ્થિતિ'), tr(gu, 'Disability, if any', 'દિવ્યાંગતા, જો હોય તો')]),
    _formGroup(tr(gu, 'Education & work', 'અભ્યાસ અને કાર્ય'), [tr(gu, 'Highest qualification', 'સર્વોચ્ચ લાયકાત'), tr(gu, 'College', 'કોલેજ'), tr(gu, 'Profession / Occupation', 'વ્યવસાય / નોકરી'), tr(gu, 'Company', 'કંપની'), tr(gu, 'Annual income', 'વાર્ષિક આવક')]),
    _formGroup(tr(gu, 'Family information', 'પરિવારની માહિતી'), [tr(gu, "Father's name", 'પિતાનું નામ'), tr(gu, "Mother's name", 'માતાનું નામ'), tr(gu, 'Family name', 'પરિવારનું નામ'), tr(gu, 'Native village / Current city', 'વતન ગામ / હાલનું શહેર'), tr(gu, 'Family type', 'પરિવાર પ્રકાર'), tr(gu, 'Brothers / Sisters', 'ભાઈઓ / બહેનો')]),
    _formGroup(tr(gu, 'Lifestyle', 'જીવનશૈલી'), [tr(gu, 'Diet', 'આહાર'), tr(gu, 'Smoking / Drinking', 'ધૂમ્રપાન / દારૂ'), tr(gu, 'Hobbies', 'શોખ'), tr(gu, 'Languages known', 'આવડતી ભાષાઓ')]),
    _formGroup(tr(gu, 'Partner preferences', 'જીવનસાથી પસંદગી'), [tr(gu, 'Preferred age range / height', 'પસંદની ઉંમર / ઊંચાઈ'), tr(gu, 'Preferred education / occupation', 'પસંદનો અભ્યાસ / વ્યવસાય'), tr(gu, 'Preferred city / village', 'પસંદનું શહેર / ગામ'), tr(gu, 'Preferred marital status', 'પસંદની વૈવાહિક સ્થિતિ')]),
    Card(child: Column(children: [SwitchListTile(value: phone, onChanged: (v) => setState(() => phone = v), title: Text(tr(gu, 'Show phone number', 'ફોન નંબર બતાવો'))), SwitchListTile(value: email, onChanged: (v) => setState(() => email = v), title: Text(tr(gu, 'Show email', 'ઇમેલ બતાવો'))), SwitchListTile(value: address, onChanged: (v) => setState(() => address = v), title: Text(tr(gu, 'Show address', 'સરનામું બતાવો')))])), const SizedBox(height: 14), FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Biodata submitted for admin approval.', 'બાયોડેટા એડમિન મંજૂરી માટે મોકલાયો.')))), style: FilledButton.styleFrom(backgroundColor: AppPalette.pink, minimumSize: const Size.fromHeight(50)), child: Text(tr(gu, 'Submit biodata', 'બાયોડેટા મોકલો')))
  ])); }
  Widget _formGroup(String title, List<String> labels) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...labels.map((e) => Padding(padding: const EdgeInsets.only(bottom: 9), child: TextField(decoration: InputDecoration(labelText: e, isDense: true))))])));
}

class AdvancedFilters extends StatelessWidget { const AdvancedFilters({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) { final labels = [tr(gujarati, 'Age and height', 'ઉંમર અને ઊંચાઈ'), tr(gujarati, 'Education and occupation', 'અભ્યાસ અને વ્યવસાય'), tr(gujarati, 'Income', 'આવક'), tr(gujarati, 'City and village', 'શહેર અને ગામ'), tr(gujarati, 'Marital status and family type', 'વૈવાહિક સ્થિતિ અને પરિવાર પ્રકાર'), tr(gujarati, 'Diet', 'આહાર')]; return Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(gujarati, 'Advanced filters', 'અદ્યતન ફિલ્ટર'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...labels.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(decoration: InputDecoration(labelText: e, isDense: true)))), FilledButton(onPressed: () => Navigator.pop(context), child: Text(tr(gujarati, 'Apply filters', 'ફિલ્ટર લાગુ કરો')))])); } }

class RequestsPage extends StatefulWidget { const RequestsPage({super.key, required this.gujarati, this.received = false}); final bool gujarati, received; @override State<RequestsPage> createState() => _RequestsPageState(); }
class _RequestsPageState extends State<RequestsPage> with SingleTickerProviderStateMixin { late TabController tabs; @override void initState() { super.initState(); tabs = TabController(length: 5, vsync: this, initialIndex: widget.received ? 0 : 1); } @override void dispose() { tabs.dispose(); super.dispose(); } @override Widget build(BuildContext context) { final gu = widget.gujarati; final labels = [tr(gu, 'Received', 'મળેલી'), tr(gu, 'Sent', 'મોકલેલી'), tr(gu, 'Pending', 'બાકી'), tr(gu, 'Accepted', 'સ્વીકારેલી'), tr(gu, 'Rejected', 'નકારેલી')]; return Scaffold(appBar: AppBar(title: Text(tr(gu, 'Interest requests', 'રસ વિનંતીઓ')), bottom: TabBar(controller: tabs, isScrollable: true, tabs: [for(final x in labels) Tab(text: x)])), body: TabBarView(controller: tabs, children: [for (var i=0;i<5;i++) ListView(padding: const EdgeInsets.all(16), children: [Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AppPalette.pink, child: Text('NC', style: TextStyle(color: Colors.white))), title: const Text('Nikita Chauhan'), subtitle: Text(i == 0 ? tr(gu, 'Wants to connect through family-guided introduction.', 'પરિવારના માર્ગદર્શનથી પરિચય ઈચ્છે છે.') : tr(gu, 'Interest request status', 'રસ વિનંતીની સ્થિતિ')), trailing: i == 0 ? Wrap(spacing: 2, children: [IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest accepted. You may share contact details according to policy.', 'રસ સ્વીકાર્યો. નીતિ અનુસાર સંપર્ક વિગતો શેર કરી શકો છો.')))), icon: const Icon(Icons.check_circle_rounded, color: AppPalette.forest)), IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gu, 'Interest rejected.', 'રસ નકાર્યો.')))), icon: const Icon(Icons.cancel_rounded, color: AppPalette.pink))]) : null))]) ])); } }

class MarriageEventsPage extends StatelessWidget { const MarriageEventsPage({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) { final events = [tr(gujarati, 'Samuh Lagna Sammelan · 18 July', 'સમૂહ લગ્ન સંમેલન · 18 જુલાઈ'), tr(gujarati, 'Matrimonial Meet · 9 August', 'મેટ્રિમોનિયલ મીટ · 9 ઓગસ્ટ'), tr(gujarati, 'Community Gathering · 24 August', 'સમાજ મિલન · 24 ઓગસ્ટ')]; return Scaffold(appBar: AppBar(title: Text(tr(gujarati, 'Marriage events', 'લગ્ન કાર્યક્રમો'))), body: ListView(padding: const EdgeInsets.all(16), children: [for(final e in events) Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AppPalette.saffron, child: Icon(Icons.event_rounded, color: Colors.white)), title: Text(e, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(tr(gujarati, 'Community event · RSVP available', 'સમાજ કાર્યક્રમ · RSVP ઉપલબ્ધ')), trailing: FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(gujarati, 'RSVP recorded.', 'RSVP નોંધાયો.')))), child: Text(tr(gujarati, 'RSVP', 'RSVP'))))])); } }

class SuccessStoriesPage extends StatelessWidget { const SuccessStoriesPage({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(tr(gujarati, 'Success stories', 'સફળ વાર્તાઓ'))), body: ListView(padding: const EdgeInsets.all(16), children: [for(final e in [('P', 'Priya ❤️ Rohan', '12 February 2026'), ('N', 'Nikita ❤️ Krupal', '23 November 2025')]) Card(child: ListTile(leading: CircleAvatar(backgroundColor: AppPalette.pink, child: Text(e.$1, style: const TextStyle(color: Colors.white))), title: Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${tr(gujarati, 'Married', 'લગ્ન')}: ${e.$3}'))])); }

class AdminMatrimonyPage extends StatelessWidget { const AdminMatrimonyPage({super.key, required this.gujarati}); final bool gujarati; @override Widget build(BuildContext context) { final rows=[tr(gujarati, 'Approve profiles', 'પ્રોફાઇલ મંજૂર કરો'),tr(gujarati, 'Review fake or inactive accounts', 'નકલી અથવા નિષ્ક્રિય ખાતાઓ તપાસો'),tr(gujarati, 'Moderate reports', 'રિપોર્ટની સમીક્ષા કરો'),tr(gujarati, 'View matching statistics', 'મેચિંગ આંકડા જુઓ')]; return Scaffold(appBar: AppBar(title: Text(tr(gujarati, 'Matrimony admin', 'મેટ્રિમોની એડમિન'))), body: ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppPalette.peacockTint,borderRadius: BorderRadius.circular(14)), child: Text(tr(gujarati, 'Admin controls are restricted to authorised community moderators.', 'એડમિન નિયંત્રણ માત્ર અધિકૃત સમાજ મોડરેટર્સ માટે છે.'))), const SizedBox(height: 12), for(final r in rows) Card(child: ListTile(title: Text(r), trailing: const Icon(Icons.chevron_right_rounded)))])); } }

class _HubTile extends StatelessWidget { const _HubTile({required this.icon, required this.label, required this.onTap}); final IconData icon; final String label; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Ink(decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.divider)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(backgroundColor: const Color(0xFFFFEAF3), child: Icon(icon,color: AppPalette.pink)), const Spacer(), Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))])))); }
