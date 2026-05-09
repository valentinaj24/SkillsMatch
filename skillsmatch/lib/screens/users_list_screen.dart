import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final searchController = TextEditingController();

  String searchQuery = '';
  String selectedFilter = 'Vsi';
  String sortBy = 'Priporočeni';
  bool showClearButton = false;

  static const dark = Color(0xff003c35);
  static const teal = Color(0xff00897b);
  static const bg = Color(0xffeefaf7);

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      final hasText = searchController.text.isNotEmpty;
      if (hasText != showClearButton) {
        setState(() => showClearButton = hasText);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void applySearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => searchQuery = searchController.text.trim());
  }

  void clearSearch() {
    searchController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      searchQuery = '';
      showClearButton = false;
    });
  }

  String _heroTag(Map<String, dynamic> data) {
    return '${data['ime'] ?? ''}-${data['priimek'] ?? ''}-${data['lokacija'] ?? ''}-${data['photoUrl'] ?? ''}';
  }

  Widget _profileImage(Map<String, dynamic> data) {
    final photoUrl = (data['photoUrl'] ?? '').toString();

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff00695c), Color(0xff21b8a7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _initialsBox(data);
                },
              )
            : _initialsBox(data),
      ),
    );
  }

  Widget _initialsBox(Map<String, dynamic> data) {
    return Center(
      child: Text(
        _initials(data),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  bool userMatches(Map<String, dynamic> data, List<dynamic> skills) {
    final query = searchQuery.toLowerCase();

    final fullName = '${data['ime'] ?? ''} ${data['priimek'] ?? ''}'
        .toLowerCase();
    final location = (data['lokacija'] ?? '').toString().toLowerCase();
    final description = (data['opis'] ?? '').toString().toLowerCase();

    final skillsText = skills
        .map(
          (skill) =>
              '${skill['naziv'] ?? ''} ${skill['nivoZnanja'] ?? ''} ${skill['tip'] ?? ''}',
        )
        .join(' ')
        .toLowerCase();

    final searchOk =
        query.isEmpty ||
        fullName.contains(query) ||
        location.contains(query) ||
        description.contains(query) ||
        skillsText.contains(query);

    final filterOk =
        selectedFilter == 'Vsi' ||
        selectedFilter == 'Mentorji' &&
            skills.any((skill) => skill['tip'] == 'Lahko učim druge') ||
        selectedFilter == 'Učenci' &&
            skills.any((skill) => skill['tip'] == 'Želim se naučiti') ||
        selectedFilter == 'Vikend' && data['razpolozljivost'] == 'Vikend';

    return searchOk && filterOk;
  }

  int matchScore(Map<String, dynamic> data, List<dynamic> skills) {
    int score = 42;

    final query = searchQuery.toLowerCase();
    final location = (data['lokacija'] ?? '').toString().toLowerCase();

    final skillsText = skills
        .map((skill) => '${skill['naziv'] ?? ''} ${skill['tip'] ?? ''}')
        .join(' ')
        .toLowerCase();

    if (query.isNotEmpty && skillsText.contains(query)) score += 30;
    if (query.isNotEmpty && location.contains(query)) score += 15;

    if (selectedFilter == 'Mentorji' &&
        skills.any((skill) => skill['tip'] == 'Lahko učim druge')) {
      score += 15;
    }

    if (selectedFilter == 'Učenci' &&
        skills.any((skill) => skill['tip'] == 'Želim se naučiti')) {
      score += 15;
    }

    if (selectedFilter == 'Vikend' && data['razpolozljivost'] == 'Vikend') {
      score += 15;
    }

    return score > 100 ? 100 : score;
  }

  List<QueryDocumentSnapshot> prepareUsers(List<QueryDocumentSnapshot> docs) {
    final users = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final skills = data['vescine'] as List<dynamic>? ?? [];
      return userMatches(data, skills);
    }).toList();

    users.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final skillsA = dataA['vescine'] as List<dynamic>? ?? [];
      final skillsB = dataB['vescine'] as List<dynamic>? ?? [];

      if (sortBy == 'Ime') {
        return '${dataA['ime'] ?? ''} ${dataA['priimek'] ?? ''}'.compareTo(
          '${dataB['ime'] ?? ''} ${dataB['priimek'] ?? ''}',
        );
      }

      if (sortBy == 'Lokacija') {
        return (dataA['lokacija'] ?? '').toString().compareTo(
          (dataB['lokacija'] ?? '').toString(),
        );
      }

      return matchScore(dataB, skillsB).compareTo(matchScore(dataA, skillsA));
    });

    return users;
  }

  String primaryRole(List<dynamic> skills) {
    final teaches = skills.any((skill) => skill['tip'] == 'Lahko učim druge');
    final learns = skills.any((skill) => skill['tip'] == 'Želim se naučiti');

    if (teaches && learns) return 'Mentor in učenec';
    if (teaches) return 'Mentor';
    if (learns) return 'Učenec';
    return 'Član skupnosti';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingSkeleton();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyCommunity();
          }

          final allUsers = snapshot.data!.docs;
          final users = prepareUsers(allUsers);

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _header(allUsers.length)),
              SliverToBoxAdapter(child: _controlPanel(users.length)),
              if (users.isEmpty)
                SliverToBoxAdapter(child: _noResults())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final skills = data['vescine'] as List<dynamic>? ?? [];
                      final score = matchScore(data, skills);

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + index * 55),
                        tween: Tween(begin: 0, end: 1),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 22 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _userCard(context, data, skills, score),
                      );
                    }, childCount: users.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _loadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 64, 18, 120),
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff004d40), Color(0xff009688), Color(0xff40c4b4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 235,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.teal.shade100),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 155,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.teal.shade100),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff003c35), Color(0xff00897b), Color(0xff2ec4b6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -20,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.09),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -38,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 39,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 17),
                        SizedBox(width: 6),
                        Text(
                          'Discover',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Skupnost',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Poišči ljudi, odkrij veščine in se poveži z uporabniki, ki ti najbolj ustrezajo.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _heroStat(Icons.people_alt_rounded, '$count', 'profilov'),
                  const SizedBox(width: 10),
                  _heroStat(Icons.school_rounded, 'Skills', 'match'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.17),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '$value $label',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlPanel(int resultCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.teal.shade100),
          boxShadow: [
            BoxShadow(
              color: teal.withOpacity(0.10),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: teal),
                SizedBox(width: 8),
                Text(
                  'Pametno iskanje',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Vnesi pojem, nato klikni Išči ali pritisni Enter.',
              style: TextStyle(color: Colors.black54, fontSize: 13.5),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => applySearch(),
              decoration: InputDecoration(
                hintText: 'Maribor, Flutter, kuhanje...',
                prefixIcon: const Icon(Icons.search_rounded, color: teal),
                suffixIcon: showClearButton
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xfff7fffd),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 17,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(23),
                  borderSide: BorderSide(color: Colors.teal.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(23),
                  borderSide: BorderSide(color: Colors.teal.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(23),
                  borderSide: const BorderSide(color: teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: applySearch,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text(
                        'Išči',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: clearSearch,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: teal,
                      side: BorderSide(color: Colors.teal.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _filterTabs(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xfff7fffd), Color(0xffecfbf7)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade50),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 20, color: teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      searchQuery.isEmpty
                          ? '$resultCount rezultatov'
                          : '$resultCount rezultatov za "$searchQuery"',
                      style: const TextStyle(
                        color: dark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTabs() {
    final filters = [
      {'label': 'Vsi', 'icon': Icons.grid_view_rounded},
      {'label': 'Mentorji', 'icon': Icons.workspace_premium_rounded},
      {'label': 'Učenci', 'icon': Icons.school_rounded},
      {'label': 'Vikend', 'icon': Icons.weekend_rounded},
    ];

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == filters.length) return _sortCard();

          final item = filters[index];
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final selected = selectedFilter == label;

          return GestureDetector(
            onTap: () => setState(() => selectedFilter = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOut,
              width: selected ? 112 : 102,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xff00695c), Color(0xff00a896)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Color(0xfff3fffb)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: selected
                      ? const Color(0xff00695c)
                      : Colors.teal.shade100,
                  width: selected ? 0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0xff00695c).withOpacity(0.24)
                        : Colors.black.withOpacity(0.045),
                    blurRadius: selected ? 18 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 230),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.22)
                              : const Color(0xffe8f8f4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: selected ? Colors.white : teal,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : dark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sortCard() {
    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => sortBy = value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Priporočeni', child: Text('Priporočeni')),
        PopupMenuItem(value: 'Ime', child: Text('Ime')),
        PopupMenuItem(value: 'Lokacija', child: Text('Lokacija')),
      ],
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xfffffbf2), Color(0xfffff3d9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.orange.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.sort_rounded,
                size: 19,
                color: Colors.orange.shade800,
              ),
            ),
            const Spacer(),
            const Text(
              'Sort',
              style: TextStyle(
                color: dark,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sortBy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(
    BuildContext context,
    Map<String, dynamic> data,
    List<dynamic> skills,
    int score,
  ) {
    final role = primaryRole(skills);
    final visibleSkills = skills.take(3).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(34),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(
              data: data,
              skills: skills,
              score: score,
              role: role,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xfff4fffc)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.teal.shade100),
          boxShadow: [
            BoxShadow(
              color: teal.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(tag: _heroTag(data), child: _profileImage(data)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['ime'] ?? ''} ${data['priimek'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: teal,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              role,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: teal,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: teal,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _miniInfo(
                  Icons.location_on_rounded,
                  data['lokacija'] ?? 'Ni lokacije',
                ),
                const SizedBox(width: 8),
                _miniInfo(
                  Icons.schedule_rounded,
                  data['razpolozljivost'] ?? 'Ni podatka',
                ),
              ],
            ),
            if ((data['opis'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                data['opis'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14.7,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (visibleSkills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...visibleSkills.map((skill) {
                    final name = (skill['naziv'] ?? '').toString();
                    final canTeach = skill['tip'] == 'Lahko učim druge';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: canTeach
                            ? teal.withOpacity(0.10)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        name.isEmpty ? 'Veščina' : name,
                        style: TextStyle(
                          color: canTeach ? teal : Colors.orange.shade800,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    );
                  }),
                  if (skills.length > 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        '+${skills.length - 3}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                _recommendationTag(score),
                const Spacer(),
                const Text(
                  'Poglej profil',
                  style: TextStyle(
                    color: teal,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: teal, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(Map<String, dynamic> data) {
    final ime = (data['ime'] ?? '').toString();
    final priimek = (data['priimek'] ?? '').toString();

    final first = ime.isNotEmpty ? ime[0] : '';
    final second = priimek.isNotEmpty ? priimek[0] : '';

    return '$first$second'.toUpperCase();
  }

  Widget _miniInfo(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xfff7fffd),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.teal.shade50),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: teal),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: dark,
                  fontSize: 12.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationTag(int score) {
    String text = 'Osnovno ujemanje';
    Color color = Colors.grey;

    if (score >= 75) {
      text = 'Top match';
      color = teal;
    } else if (score >= 55) {
      text = 'Dobro ujemanje';
      color = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noResults() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.teal.shade100),
          boxShadow: [
            BoxShadow(
              color: teal.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 58, color: teal),
            const SizedBox(height: 14),
            const Text(
              'Ni najdenih rezultatov',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Poskusi spremeniti iskanje ali izbrani filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: clearSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Počisti filtre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCommunity() {
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.teal.shade100),
              boxShadow: [
                BoxShadow(
                  color: teal.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_rounded, size: 62, color: teal),
                SizedBox(height: 16),
                Text(
                  'Ni dodanih uporabnikov',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ko uporabniki ustvarijo profil, bodo prikazani tukaj.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> skills;
  final int score;
  final String role;

  const UserDetailScreen({
    super.key,
    required this.data,
    required this.skills,
    required this.score,
    required this.role,
  });

  static const dark = Color(0xff003c35);
  static const teal = Color(0xff00897b);
  static const bg = Color(0xffeefaf7);

  String _heroTag() {
    return '${data['ime'] ?? ''}-${data['priimek'] ?? ''}-${data['lokacija'] ?? ''}-${data['photoUrl'] ?? ''}';
  }

  String _initials() {
    final ime = (data['ime'] ?? '').toString();
    final priimek = (data['priimek'] ?? '').toString();

    final first = ime.isNotEmpty ? ime[0] : '';
    final second = priimek.isNotEmpty ? priimek[0] : '';

    return '$first$second'.toUpperCase();
  }

  Widget _detailProfileImage() {
    final photoUrl = (data['photoUrl'] ?? '').toString();

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.17),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _detailInitialsBox();
                },
              )
            : _detailInitialsBox(),
      ),
    );
  }

  Widget _detailInitialsBox() {
    return Center(
      child: Text(
        _initials(),
        style: const TextStyle(
          color: teal,
          fontWeight: FontWeight.w900,
          fontSize: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${data['ime'] ?? ''} ${data['priimek'] ?? ''}';

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _detailHeader(context, fullName),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _matchCard(),
                  const SizedBox(height: 16),
                  _profileSummary(),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Opis uporabnika',
                    icon: Icons.description_outlined,
                    child: Text(
                      (data['opis'] ?? '').toString().isEmpty
                          ? 'Uporabnik še ni dodal opisa.'
                          : data['opis'],
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Veščine',
                    icon: Icons.school_outlined,
                    child: skills.isEmpty
                        ? const Text('Uporabnik še nima dodanih veščin.')
                        : Column(
                            children: skills.map((skill) {
                              final canTeach =
                                  skill['tip'] == 'Lahko učim druge';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: canTeach
                                      ? teal.withOpacity(0.09)
                                      : Colors.orange.withOpacity(0.11),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: canTeach
                                        ? Colors.teal.shade100
                                        : Colors.orange.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        canTeach
                                            ? Icons.volunteer_activism_rounded
                                            : Icons.school_rounded,
                                        color: canTeach
                                            ? teal
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            skill['naziv'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: dark,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${skill['nivoZnanja'] ?? ''} • ${skill['tip'] ?? ''}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _contactButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailHeader(BuildContext context, String fullName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff003c35), Color(0xff00897b), Color(0xff2ec4b6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -25,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Hero(tag: _heroTag(), child: _detailProfileImage()),
              const SizedBox(height: 16),
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.17)),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff00897b), Color(0xff26c6aa)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ujemanje profila',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score% priporočeno glede na filtre in iskanje',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryItem(
            Icons.location_on_outlined,
            'Lokacija',
            data['lokacija'] ?? 'Ni podatka',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryItem(
            Icons.schedule_outlined,
            'Čas',
            data['razpolozljivost'] ?? 'Ni podatka',
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: teal),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, color: dark),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _contactButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Funkcija za pošiljanje sporočil bo dodana v naslednji fazi.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: teal,
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text(
          'Pošlji sporočilo',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}
