import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../providers/auth_provider.dart';

class FamilyTreeNode {
  final String id;
  final String name;
  final String photo;
  final String relation;
  final String? parentId;
  final bool isDeceased;
  final List<FamilyTreeNode> children;

  FamilyTreeNode({
    required this.id,
    required this.name,
    required this.photo,
    required this.relation,
    this.parentId,
    required this.isDeceased,
    required this.children,
  });

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) {
    var childrenJson = json['children'] as List? ?? [];
    List<FamilyTreeNode> childrenList = childrenJson
        .map((c) => FamilyTreeNode.fromJson(c as Map<String, dynamic>))
        .toList();
    return FamilyTreeNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      parentId: json['parentId'] as String?,
      isDeceased: json['isDeceased'] as bool? ?? false,
      children: childrenList,
    );
  }
}

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  FamilyTreeNode? _rootNode;
  FamilyTreeNode? _focalNode;
  Map<String, Offset> _positions = {};
  final Map<String, FamilyTreeNode> _nodesMap = {};
  final Map<String, String> _parentMap = {};
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFamilyTree();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _fetchFamilyTree() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to view your family tree.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/family/my-tree'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-phone': user.phoneNumber,
          'x-user-email': user.email,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['tree'] != null) {
            final root = FamilyTreeNode.fromJson(data['tree']);
            setState(() {
              _rootNode = root;
              _nodesMap.clear();
              _parentMap.clear();
              _mapNodes(root, null);
              
              FamilyTreeNode? selfNode;
              for (var n in _nodesMap.values) {
                if (n.relation.toLowerCase() == 'self') {
                  selfNode = n;
                  break;
                }
              }
              _focalNode = selfNode ?? root;
              _isLoading = false;
            });
            
            // Auto-center the tree on startup
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Canvas width is 1600, center is 800. Center the view on 800.
                final double xTranslation = (screenWidth / 2) - 800;
                _transformationController.value = Matrix4.identity()..setTranslationRaw(xTranslation, 100.0, 0.0);
              }
            });
          } else {
            setState(() {
              _rootNode = null;
              _errorMessage = data['message'] ?? 'No family tree records found.';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load family tree.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server returned status code ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _mapNodes(FamilyTreeNode node, String? parentId) {
    _nodesMap[node.id] = node;
    if (parentId != null) {
      _parentMap[node.id] = parentId;
    }
    for (var child in node.children) {
      _mapNodes(child, node.id);
    }
  }

  // Layout mapping algorithm
  Map<String, Offset> _calculatePositions(FamilyTreeNode root) {
    final Map<String, Offset> positions = {};
    final List<List<FamilyTreeNode>> levels = List.generate(5, (_) => []);
    final Set<String> visited = {};

    void traverse(FamilyTreeNode node, int level) {
      if (level >= 5 || visited.contains(node.id)) return;
      visited.add(node.id);
      levels[level].add(node);

      // Spouse matches placed on same level
      for (var child in node.children) {
        if (isSpouseRelation(node.relation, child.relation)) {
          traverse(child, level);
        }
      }

      // regular child descendants placed on next level down
      for (var child in node.children) {
        if (!isSpouseRelation(node.relation, child.relation)) {
          traverse(child, level + 1);
        }
      }
    }

    traverse(root, 0);

    const double centerX = 800.0; // 1600 total width virtual canvas
    
    for (int lvl = 0; lvl < 5; lvl++) {
      final list = levels[lvl];
      if (list.isEmpty) continue;

      final double y = 100.0 + lvl * 180.0;

      // Group spouses together in sequence
      final List<FamilyTreeNode> sortedList = [];
      final Set<String> positioned = {};

      for (var node in list) {
        if (positioned.contains(node.id)) continue;
        sortedList.add(node);
        positioned.add(node.id);

        FamilyTreeNode? spouse;
        for (var other in list) {
          if (positioned.contains(other.id)) continue;
          if (isSpouseRelation(node.relation, other.relation)) {
            spouse = other;
            break;
          }
        }

        if (spouse != null) {
          sortedList.add(spouse);
          positioned.add(spouse.id);
        }
      }

      final int count = sortedList.length;
      const double nodeWidth = 150.0;
      const double gap = 50.0;
      final double totalWidth = count * nodeWidth + (count - 1) * gap;
      final double startX = centerX - totalWidth / 2 + nodeWidth / 2;

      for (int i = 0; i < count; i++) {
        final node = sortedList[i];
        positions[node.id] = Offset(startX + i * (nodeWidth + gap), y);
      }
    }

    // Centering alignment for single child subtrees
    void adjustSubtree(FamilyTreeNode node) {
      FamilyTreeNode? spouseNode;
      for (var child in node.children) {
        if (isSpouseRelation(node.relation, child.relation)) {
          spouseNode = child;
          break;
        }
      }

      final List<FamilyTreeNode> descendants = [];
      for (var child in node.children) {
        if (child.id != spouseNode?.id) {
          descendants.add(child);
        }
      }

      if (descendants.length == 1) {
        final singleChild = descendants[0];
        if (positions.containsKey(node.id) && positions.containsKey(singleChild.id)) {
          final parentPos = positions[node.id]!;
          double parentMidX = parentPos.dx;
          if (spouseNode != null && positions.containsKey(spouseNode.id)) {
            parentMidX = (parentPos.dx + positions[spouseNode.id]!.dx) / 2;
          }
          final currentChildX = positions[singleChild.id]!.dx;
          final shiftX = parentMidX - currentChildX;

          void shiftSubtree(FamilyTreeNode n) {
            if (positions.containsKey(n.id)) {
              positions[n.id] = Offset(positions[n.id]!.dx + shiftX, positions[n.id]!.dy);
            }
            for (var c in n.children) {
              shiftSubtree(c);
            }
          }
          shiftSubtree(singleChild);
        }
      }

      for (var child in node.children) {
        adjustSubtree(child);
      }
    }

    adjustSubtree(root);

    return positions;
  }

  static bool isSpouseRelation(String rel1, String rel2) {
    final r1 = rel1.toLowerCase().trim();
    final r2 = rel2.toLowerCase().trim();
    if (r1 == 'self' && (r2 == 'wife' || r2 == 'husband' || r2 == 'spouse')) return true;
    if (r2 == 'self' && (r1 == 'wife' || r1 == 'husband' || r1 == 'spouse')) return true;
    if (r1 == 'grandfather' && r2 == 'grandmother') return true;
    if (r2 == 'grandfather' && r1 == 'grandmother') return true;
    if (r1 == 'nana' && r2 == 'nani') return true;
    if (r2 == 'nana' && r1 == 'nani') return true;
    if (r1 == 'father' && r2 == 'mother') return true;
    if (r2 == 'father' && r1 == 'mother') return true;
    if (r1 == 'father-in-law' && r2 == 'mother-in-law') return true;
    if (r2 == 'father-in-law' && r1 == 'mother-in-law') return true;
    return false;
  }

  Color _getRelationColor(String relation) {
    final rel = relation.toLowerCase().trim();
    if (rel == 'husband' || rel == 'wife' || rel == 'spouse') {
      return const Color(0xFF2980B9); // Blue
    } else if (rel == 'father' || rel == 'mother') {
      return const Color(0xFF27AE60); // Green
    } else if (rel == 'brother' || rel == 'sister') {
      return const Color(0xFFE67E22); // Orange
    } else if (rel == 'grandfather' || rel == 'grandmother' || rel == 'nana' || rel == 'nani' || rel == 'ancestors') {
      return const Color(0xFF1B4F72); // Dark Blue
    } else if (rel == 'uncle' || rel == 'aunt') {
      return const Color(0xFF8E44AD); // Purple
    } else if (rel == 'cousin') {
      return const Color(0xFFFD79A8); // Pink
    } else if (rel == 'son' || rel == 'daughter') {
      return const Color(0xFF2E7D32); // Green
    } else if (rel == 'father-in-law' || rel == 'mother-in-law') {
      return const Color(0xFF8D6E63); // Brown
    } else if (rel == 'brother-in-law' || rel == 'sister-in-law') {
      return const Color(0xFF008080); // Teal
    } else if (rel == 'nephew' || rel == 'niece') {
      return const Color(0xFFC0392B); // Red
    } else if (rel == 'guardian') {
      return const Color(0xFF7F8C8D); // Grey
    }
    return const Color(0xFF2C3E50); // Black
  }

  void _showNodeDetailsDialog(FamilyTreeNode node) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final relColor = _getRelationColor(node.relation);
        
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.badge_rounded, color: relColor),
              const SizedBox(width: 10),
              Text(
                'Member Details',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (node.photo.startsWith('data:image') || node.photo.length > 100)
                CircleAvatar(
                  radius: 46,
                  backgroundImage: MemoryImage(base64Decode(node.photo.split(',').last)),
                )
              else
                CircleAvatar(
                  radius: 46,
                  backgroundColor: relColor.withValues(alpha: 0.12),
                  child: Icon(
                    node.relation.toLowerCase() == 'mother' || node.relation.toLowerCase() == 'grandmother' || node.relation.toLowerCase() == 'wife' || node.relation.toLowerCase() == 'daughter'
                        ? Icons.face_3_rounded
                        : Icons.face_rounded,
                    size: 48,
                    color: relColor,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                node.name,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: relColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  node.relation.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: relColor),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddRelationDialog(node);
              },
              child: Text(
                'Add Relation',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFFD35400)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddRelationDialog(FamilyTreeNode parentNode) {
    final nameController = TextEditingController();
    String chosenRelation = 'Son';
    bool isDeceased = false;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Add Relation to ${parentNode.name}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: chosenRelation,
                      decoration: InputDecoration(
                        labelText: 'Relationship',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        'Son',
                        'Daughter',
                        'Brother',
                        'Sister',
                        'Spouse',
                        'Father',
                        'Mother',
                        'Grandfather',
                        'Grandmother',
                        'Nana',
                        'Nani',
                        'Uncle',
                        'Aunt',
                        'Cousin',
                        'Nephew',
                        'Niece'
                      ]
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            chosenRelation = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Is Deceased?'),
                      value: isDeceased,
                      activeColor: const Color(0xFFD35400),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            isDeceased = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name.')),
                      );
                      return;
                    }

                    final user = ref.read(currentUserProvider);
                    if (user == null) return;

                    Navigator.pop(context); // Close dialog

                    try {
                      final response = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/family/add-member'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'userId': user.id,
                          'name': name,
                          'relation': chosenRelation,
                          'isDeceased': isDeceased,
                        }),
                      );

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Relation added successfully!')),
                        );
                        _fetchFamilyTree(); // Reload tree
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add relation.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding relation: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD35400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFocalNodeCard(FamilyTreeNode node, Offset pos, {required bool isFocal}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relColor = _getRelationColor(node.relation);

    Widget avatarWidget;
    if (node.photo.startsWith('data:image') || node.photo.length > 100) {
      avatarWidget = CircleAvatar(
        radius: 22,
        backgroundImage: MemoryImage(base64Decode(node.photo.split(',').last)),
      );
    } else {
      IconData avatarIcon = Icons.face_rounded;
      if (node.relation.toLowerCase() == 'mother' || node.relation.toLowerCase() == 'grandmother' || node.relation.toLowerCase() == 'wife' || node.relation.toLowerCase() == 'daughter') {
        avatarIcon = Icons.face_3_rounded;
      }
      avatarWidget = CircleAvatar(
        radius: 22,
        backgroundColor: relColor.withValues(alpha: 0.15),
        child: Icon(avatarIcon, size: 24, color: relColor),
      );
    }

    return Positioned(
      left: pos.dx - 75, // Center card on pos.dx (card width is 150)
      top: pos.dy - 35,  // Center card on pos.dy (card height is 70)
      child: GestureDetector(
        onTap: () {
          if (node.id != _focalNode?.id) {
            setState(() {
              _focalNode = node;
            });
          }
        },
        child: Container(
          width: 150,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocal ? const Color(0xFF27AE60) : relColor,
              width: isFocal ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              avatarWidget,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.isDeceased ? '⚫ ${node.name}' : node.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: relColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        node.relation.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: relColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey),
                onPressed: () => _showNodeDetailsDialog(node),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodeWidgets() {
    if (_focalNode == null) return [];

    final List<Widget> widgets = [];
    final Map<String, Offset> localPositions = {};

    // 1. Resolve Parents
    FamilyTreeNode? fatherNode;
    FamilyTreeNode? motherNode;
    final pId = _parentMap[_focalNode!.id];
    if (pId != null) {
      final pNode = _nodesMap[pId];
      if (pNode != null) {
        if (pNode.relation.toLowerCase() == 'father') {
          fatherNode = pNode;
        } else if (pNode.relation.toLowerCase() == 'mother') {
          motherNode = pNode;
        }
        for (var child in pNode.children) {
          if (isSpouseRelation(pNode.relation, child.relation)) {
            if (child.relation.toLowerCase() == 'father') {
              fatherNode = child;
            } else if (child.relation.toLowerCase() == 'mother') {
              motherNode = child;
            }
          }
        }
      }
    }

    // 2. Resolve Spouse
    FamilyTreeNode? spouseNode;
    for (var child in _focalNode!.children) {
      if (isSpouseRelation(_focalNode!.relation, child.relation)) {
        spouseNode = child;
        break;
      }
    }

    // 3. Resolve Children
    final List<FamilyTreeNode> childrenNodes = [];
    for (var child in _focalNode!.children) {
      if (child.id != spouseNode?.id && !isSpouseRelation(_focalNode!.relation, child.relation)) {
        childrenNodes.add(child);
      }
    }

    // Map positions
    // Parents (Y = 100)
    if (fatherNode != null && motherNode != null) {
      localPositions[fatherNode.id] = const Offset(700, 100);
      localPositions[motherNode.id] = const Offset(900, 100);
    } else if (fatherNode != null) {
      localPositions[fatherNode.id] = const Offset(800, 100);
    } else if (motherNode != null) {
      localPositions[motherNode.id] = const Offset(800, 100);
    }

    // Self & Spouse (Y = 280)
    if (spouseNode != null) {
      localPositions[_focalNode!.id] = const Offset(700, 280);
      localPositions[spouseNode.id] = const Offset(900, 280);
    } else {
      localPositions[_focalNode!.id] = const Offset(800, 280);
    }

    // Children (Y = 460)
    final int count = childrenNodes.length;
    if (count > 0) {
      final double startX = 800 - (count - 1) * 100.0;
      for (int i = 0; i < count; i++) {
        localPositions[childrenNodes[i].id] = Offset(startX + i * 200.0, 460);
      }
    }

    // Set positions for CustomPaint line drawing
    _positions = localPositions;

    // Render cards
    if (fatherNode != null) widgets.add(_buildFocalNodeCard(fatherNode, localPositions[fatherNode.id]!, isFocal: false));
    if (motherNode != null) widgets.add(_buildFocalNodeCard(motherNode, localPositions[motherNode.id]!, isFocal: false));
    widgets.add(_buildFocalNodeCard(_focalNode!, localPositions[_focalNode!.id]!, isFocal: true));
    if (spouseNode != null) widgets.add(_buildFocalNodeCard(spouseNode, localPositions[spouseNode.id]!, isFocal: false));
    for (var child in childrenNodes) {
      widgets.add(_buildFocalNodeCard(child, localPositions[child.id]!, isFocal: false));
    }

    // Add navigation arrows on canvas
    // Up arrow (from self to parent)
    if (fatherNode != null || motherNode != null) {
      widgets.add(
        Positioned(
          left: 800 - 20,
          top: 195,
          child: Tooltip(
            message: 'Shift focus upwards',
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              elevation: 4,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFD35400), size: 18),
                onPressed: () {
                  setState(() {
                    _focalNode = fatherNode ?? motherNode;
                  });
                },
              ),
            ),
          ),
        ),
      );
    }

    // Down arrow (from self to children)
    if (childrenNodes.isNotEmpty) {
      widgets.add(
        Positioned(
          left: 800 - 20,
          top: 360,
          child: Tooltip(
            message: 'Shift focus downwards',
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              elevation: 4,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_downward_rounded, color: Color(0xFFD35400), size: 18),
                onPressed: () {
                  setState(() {
                    _focalNode = childrenNodes.first;
                  });
                },
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFD35400)),
              const SizedBox(height: 16),
              Text(
                'Loading your family tree...',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.family_restroom_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'My Family Tree',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchFamilyTree,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('Retry', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD35400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_rootNode == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'No family data available.',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    // Interactive custom zoom/pinch/pan view canvas
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Family Tree',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Private Family Lineage Network',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD35400),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchFamilyTree,
            tooltip: 'Reload Tree',
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(200),
        minScale: 0.2,
        maxScale: 2.0,
        child: SizedBox(
          width: 1600,
          height: 1000,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(1600, 1000),
                painter: FamilyTreeLinePainter(
                  rootNode: _rootNode!,
                  positions: _positions,
                  colorResolver: _getRelationColor,
                ),
              ),
              ..._buildNodeWidgets(),
            ],
          ),
        ),
      ),
    );
  }
}

// Line drawing custom painter
class FamilyTreeLinePainter extends CustomPainter {
  final FamilyTreeNode rootNode;
  final Map<String, Offset> positions;
  final Color Function(String) colorResolver;

  FamilyTreeLinePainter({
    required this.rootNode,
    required this.positions,
    required this.colorResolver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    void drawConnections(FamilyTreeNode node) {
      if (!positions.containsKey(node.id)) return;
      final parentPos = positions[node.id]!;

      // Find if spouse node exists
      FamilyTreeNode? spouseNode;
      for (var child in node.children) {
        if (_FamilyTreeScreenState.isSpouseRelation(node.relation, child.relation)) {
          spouseNode = child;
          break;
        }
      }

      Offset jointStart = parentPos;

      if (spouseNode != null && positions.containsKey(spouseNode.id)) {
        final spousePos = positions[spouseNode.id]!;
        // 1. Draw spouse connector line (Husband <-> Wife = Blue)
        paint.color = const Color(0xFF2980B9);
        paint.strokeWidth = 2.5;

        final double parentEdgeX = parentPos.dx < spousePos.dx ? parentPos.dx + 75.0 : parentPos.dx - 75.0;
        final double spouseEdgeX = parentPos.dx < spousePos.dx ? spousePos.dx - 75.0 : spousePos.dx + 75.0;

        canvas.drawLine(
          Offset(parentEdgeX, parentPos.dy),
          Offset(spouseEdgeX, spousePos.dy),
          paint,
        );

        final midX = (parentPos.dx + spousePos.dx) / 2;
        canvas.drawCircle(Offset(midX, parentPos.dy), 4.0, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;

        jointStart = Offset(midX, parentPos.dy);
      }

      // Collect direct descendants
      final List<FamilyTreeNode> descendants = [];
      for (var child in node.children) {
        if (child.id != spouseNode?.id) {
          descendants.add(child);
        }
      }

      if (descendants.isNotEmpty) {
        final double parentBottom = jointStart.dy + 35.0; // Bottom of parent card height

        for (var desc in descendants) {
          if (positions.containsKey(desc.id)) {
            final childPos = positions[desc.id]!;
            final double childTop = childPos.dy - 35.0;
            
            paint.color = colorResolver(desc.relation);
            paint.strokeWidth = 2.0;

            // Orthogonal connector line:
            final double midY = (parentBottom + childTop) / 2;
            
            // 1. Draw line down from jointStart to midY
            canvas.drawLine(
              Offset(jointStart.dx, parentBottom),
              Offset(jointStart.dx, midY),
              paint,
            );
            // 2. Draw horizontal line from jointStart.dx to childPos.dx
            canvas.drawLine(
              Offset(jointStart.dx, midY),
              Offset(childPos.dx, midY),
              paint,
            );
            // 3. Draw vertical line from midY to childTop
            canvas.drawLine(
              Offset(childPos.dx, midY),
              Offset(childPos.dx, childTop),
              paint,
            );

            canvas.drawCircle(Offset(childPos.dx, childTop), 2.0, paint..style = PaintingStyle.fill);
            paint.style = PaintingStyle.stroke;
          }
        }
      }

      // Recursively paint for children
      for (var child in node.children) {
        drawConnections(child);
      }
    }

    drawConnections(rootNode);
  }

  @override
  bool shouldRepaint(covariant FamilyTreeLinePainter oldDelegate) {
    return oldDelegate.rootNode != rootNode || oldDelegate.positions != positions;
  }
}
