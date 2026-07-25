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
  final List<FamilyTreeNode> children;

  FamilyTreeNode({
    required this.id,
    required this.name,
    required this.photo,
    required this.relation,
    this.parentId,
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
  Map<String, Offset> _positions = {};
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
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['tree'] != null) {
            final root = FamilyTreeNode.fromJson(data['tree']);
            setState(() {
              _rootNode = root;
              _positions = _calculatePositions(root);
              _isLoading = false;
            });
            
            // Auto-center the tree on startup
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _positions.isNotEmpty) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Canvas width is 1600, center is 800. Center the view on 800.
                final double xTranslation = (screenWidth / 2) - 800;
                _transformationController.value = Matrix4.identity()..setTranslationRaw(xTranslation, 20.0, 0.0);
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
        final r = child.relation.toLowerCase();
        if (r == 'wife' || r == 'husband' || r == 'spouse' || r == 'mother' || r == 'grandmother' || r == 'mother-in-law') {
          traverse(child, level);
        }
      }

      // regular child descendants placed on next level down
      for (var child in node.children) {
        final r = child.relation.toLowerCase();
        if (r != 'wife' && r != 'husband' && r != 'spouse' && r != 'mother' && r != 'grandmother' && r != 'mother-in-law') {
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
          if (_isSpouseRelation(node.relation, other.relation)) {
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

    return positions;
  }

  bool _isSpouseRelation(String rel1, String rel2) {
    final r1 = rel1.toLowerCase();
    final r2 = rel2.toLowerCase();
    if (r1 == 'self' && (r2 == 'wife' || r2 == 'husband' || r2 == 'spouse')) return true;
    if (r2 == 'self' && (r1 == 'wife' || r1 == 'husband' || r1 == 'spouse')) return true;
    if (r1 == 'grandfather' && r2 == 'grandmother') return true;
    if (r2 == 'grandfather' && r1 == 'grandmother') return true;
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
      return const Color(0xFFE67E22); // Orange (Brother/Sister cross relations default to orange)
    } else if (rel == 'grandfather' || rel == 'grandmother') {
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
    return const Color(0xFF2C3E50); // Black for Unknown/Other
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

  Widget _buildNodeCard(FamilyTreeNode node, Offset pos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final relColor = _getRelationColor(node.relation);
    final isSelf = node.relation.toLowerCase() == 'self';

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
        onTap: () => _showNodeDetailsDialog(node),
        child: Container(
          width: 150,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelf ? const Color(0xFF27AE60) : relColor,
              width: isSelf ? 2.5 : 1.5,
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
                      node.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodeWidgets() {
    final List<Widget> widgets = [];
    void collect(FamilyTreeNode node) {
      if (_positions.containsKey(node.id)) {
        widgets.add(_buildNodeCard(node, _positions[node.id]!));
      }
      for (var child in node.children) {
        collect(child);
      }
    }
    if (_rootNode != null) {
      collect(_rootNode!);
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
        final r = child.relation.toLowerCase();
        if (r == 'wife' || r == 'husband' || r == 'spouse' || r == 'mother' || r == 'grandmother' || r == 'mother-in-law') {
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
        canvas.drawLine(
          Offset(parentPos.dx, parentPos.dy),
          Offset(spousePos.dx, spousePos.dy),
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
        final double childLineY = parentBottom + 30.0;    // Horizontal junction line height

        paint.color = const Color(0xFF27AE60); // Default parent-child draw color
        paint.strokeWidth = 2.0;

        canvas.drawLine(
          Offset(jointStart.dx, parentBottom),
          Offset(jointStart.dx, childLineY),
          paint,
        );

        double minX = jointStart.dx;
        double maxX = jointStart.dx;

        for (var desc in descendants) {
          if (positions.containsKey(desc.id)) {
            final x = positions[desc.id]!.dx;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
          }
        }

        canvas.drawLine(
          Offset(minX, childLineY),
          Offset(maxX, childLineY),
          paint,
        );

        for (var desc in descendants) {
          if (positions.containsKey(desc.id)) {
            final childPos = positions[desc.id]!;
            final double childTop = childPos.dy - 35.0;
            
            paint.color = colorResolver(desc.relation);

            canvas.drawLine(
              Offset(childPos.dx, childLineY),
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
