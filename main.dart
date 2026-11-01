import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const RflMobileApp());

const ink = Color(0xFF101114);
const panel = Color(0xFF191B20);
const accent = Color(0xFFE14B55);
const muted = Color(0xFF9AA0AA);

class RflMobileApp extends StatelessWidget {
  const RflMobileApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RFL Mobile',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(primary: accent, surface: panel),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white),
    ),
    home: const EditorHome(),
  );
}

class RflLayer {
  RflLayer(this.name, {this.visible = true, this.opacity = 1});
  String name;
  bool visible;
  double opacity;
  Map<String, dynamic> toJson() => {'name': name, 'visible': visible, 'opacity': opacity};
}

class EditorHome extends StatefulWidget {
  const EditorHome({super.key});
  @override
  State<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<EditorHome> {
  final List<RflLayer> layers = [RflLayer('Desenho 1'), RflLayer('Papel')];
  int activeLayer = 0;
  String tool = 'Mover';
  bool showLayers = true;
  bool showGuides = true;
  bool showRulers = true;
  final List<Offset> strokes = [];
  final List<List<Offset>> history = [];
  final ImagePicker picker = ImagePicker();
  double lastPressure = 1.0;

  Future<void> saveProject() async {
    final payload = {
      'format': 'rfl-project',
      'version': 1,
      'app': 'RFL Mobile',
      'document': {'width': 2480, 'height': 3508, 'dpi': 300, 'unit': 'px'},
      'layers': layers.map((e) => e.toJson()).toList(),
      'active_layer': activeLayer,
      'note': 'MVP: canvas and stroke serialization will be expanded in later versions.'
    };
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/RFL_Mobile_projeto.rfl.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Projeto salvo: ${file.path}')));
  }

  Future<void> importProject() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json','rfl']);
    if (result == null || result.files.single.path == null) return;
    try {
      final data = jsonDecode(await File(result.files.single.path!).readAsString()) as Map<String, dynamic>;
      final raw = (data['layers'] as List?) ?? [];
      setState(() {
        layers
          ..clear()
          ..addAll(raw.map((e) => RflLayer('${e['name'] ?? 'Camada'}',
            visible: e['visible'] != false,
            opacity: (e['opacity'] as num?)?.toDouble() ?? 1)));
        if (layers.isEmpty) layers.add(RflLayer('Camada 1'));
        activeLayer = 0;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estrutura do projeto importada.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir esse projeto.')));
    }
  }

  Future<void> addImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => layers.insert(0, RflLayer('Imagem importada')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagem selecionada. A importação visual completa entra na próxima etapa.')));
  }

  void undo() {
    if (history.isNotEmpty) setState(() {
      strokes
        ..clear()
        ..addAll(history.removeLast());
    });
  }

  void startStroke(Offset p, double pressure) {
    history.add(List<Offset>.from(strokes));
    setState(() { strokes.add(p); lastPressure = pressure; });
  }
  void moveStroke(Offset p, double pressure) => setState(() { strokes.add(p); lastPressure = pressure; });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.draw_outlined, color: accent), SizedBox(width: 9), Text('RFL Studio', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(width: 8), Text('MOBILE', style: TextStyle(color: muted, fontSize: 11, letterSpacing: 2))]),
        actions: [
          IconButton(tooltip: 'Desfazer', onPressed: undo, icon: const Icon(Icons.undo)),
          IconButton(tooltip: 'Importar projeto', onPressed: importProject, icon: const Icon(Icons.folder_open)),
          IconButton(tooltip: 'Salvar projeto', onPressed: saveProject, icon: const Icon(Icons.save_outlined)),
          PopupMenuButton<String>(onSelected: (v) {
            if (v == 'layers') setState(() => showLayers = !showLayers);
            if (v == 'rulers') setState(() => showRulers = !showRulers);
            if (v == 'guides') setState(() => showGuides = !showGuides);
          }, itemBuilder: (_) => const [
            PopupMenuItem(value: 'layers', child: Text('Mostrar/ocultar camadas')),
            PopupMenuItem(value: 'rulers', child: Text('Mostrar/ocultar réguas')),
            PopupMenuItem(value: 'guides', child: Text('Mostrar/ocultar guias')),
          ]),
        ],
      ),
      body: Column(children: [
        _topTools(),
        Expanded(child: Row(children: [
          if (wide) _toolRail(),
          Expanded(child: _workspace()),
          if (wide && showLayers) _layersPanel(width: 220),
        ])),
        if (!wide) _bottomTools(),
      ]),
      floatingActionButton: wide ? FloatingActionButton.small(onPressed: addImage, backgroundColor: accent, child: const Icon(Icons.add_photo_alternate_outlined)) : null,
    );
  }

  Widget _topTools() => Container(
    height: 48, color: panel, padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(children: [
      _chip('Mover', Icons.open_with), _chip('Pincel', Icons.brush), _chip('Borracha', Icons.auto_fix_off),
      const Spacer(),
      IconButton(onPressed: addImage, tooltip: 'Importar imagem', icon: const Icon(Icons.add_photo_alternate_outlined)),
      Text('A4 • 300 DPI', style: TextStyle(color: muted, fontSize: 11)),
    ]),
  );

  Widget _chip(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(right: 5),
    child: ChoiceChip(label: Text(label, style: const TextStyle(fontSize: 11)), avatar: Icon(icon, size: 15),
      selected: tool == label, onSelected: (_) => setState(() => tool = label),
      visualDensity: VisualDensity.compact, selectedColor: accent.withOpacity(.25)),
  );

  Widget _toolRail() => Container(width: 54, color: panel, child: Column(children: [
    _railButton(Icons.open_with, 'Mover'), _railButton(Icons.brush, 'Pincel'),
    _railButton(Icons.auto_fix_off, 'Borracha'), _railButton(Icons.crop, 'Cortar'),
    const Spacer(), IconButton(onPressed: () => setState(() => showLayers = !showLayers), icon: const Icon(Icons.layers_outlined)),
  ]));

  Widget _railButton(IconData icon, String name) => IconButton(
    tooltip: name, onPressed: () => setState(() => tool = name),
    color: tool == name ? accent : muted, icon: Icon(icon));

  Widget _workspace() => Container(color: const Color(0xFF25272D), child: Column(children: [
    if (showRulers) _ruler(true),
    Expanded(child: Row(children: [
      if (showRulers) _ruler(false),
      Expanded(child: Center(child: AspectRatio(
        aspectRatio: 2480 / 3508,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Color(0xFFF8F7F2), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 18)]),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(builder: (context, c) => Listener(
            onPointerDown: (e) {
              if (tool == 'Pincel') startStroke(e.localPosition, e.pressure);
            },
            onPointerMove: (e) {
              if (tool == 'Pincel' && e.buttons != 0) moveStroke(e.localPosition, e.pressure);
            },
            child: CustomPaint(
              painter: SketchPainter(strokes: strokes, guides: showGuides),
              child: const SizedBox.expand(),
            ),
          )),
        ),
      ))),
    ])),
  ]));

  Widget _ruler(bool horizontal) => Container(
    color: const Color(0xFF17191E),
    height: horizontal ? 22 : null, width: horizontal ? null : 22,
    child: Center(child: RotatedBox(
      quarterTurns: horizontal ? 0 : 1,
      child: Text('0     2     4     6     8     10', style: TextStyle(color: muted, fontSize: 9)),
    )),
  );

  Widget _layersPanel({required double width}) => Container(
    width: width, color: panel, child: Column(children: [
      const Padding(padding: EdgeInsets.all(14), child: Row(children: [Icon(Icons.layers, size: 17), SizedBox(width: 8), Text('Camadas', style: TextStyle(fontWeight: FontWeight.bold))])),
      const Divider(height: 1),
      Expanded(child: ListView.builder(itemCount: layers.length, itemBuilder: (context, i) => ListTile(
        dense: true, selected: activeLayer == i, selectedTileColor: accent.withOpacity(.12),
        leading: Icon(layers[i].visible ? Icons.visibility : Icons.visibility_off, size: 17, color: muted),
        title: Text(layers[i].name, style: const TextStyle(fontSize: 12)),
        onTap: () => setState(() => activeLayer = i),
      ))),
      TextButton.icon(onPressed: () => setState(() => layers.insert(0, RflLayer('Nova camada ${layers.length + 1}'))),
        icon: const Icon(Icons.add, size: 16), label: const Text('Nova camada')),
    ]),
  );

  Widget _bottomTools() => Container(
    color: panel, height: 62,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _bottomButton(Icons.open_with, 'Mover'), _bottomButton(Icons.brush, 'Pincel'),
      _bottomButton(Icons.auto_fix_off, 'Borracha'),
      IconButton(onPressed: () => setState(() => showLayers = !showLayers), icon: const Icon(Icons.layers_outlined)),
      IconButton(onPressed: addImage, icon: const Icon(Icons.add_photo_alternate_outlined)),
      IconButton(onPressed: saveProject, icon: const Icon(Icons.save_outlined)),
    ]),
  );

  Widget _bottomButton(IconData icon, String name) => IconButton(
    onPressed: () => setState(() => tool = name),
    color: tool == name ? accent : muted, icon: Icon(icon));
}

class SketchPainter extends CustomPainter {
  SketchPainter({required this.strokes, required this.guides});
  final List<Offset> strokes;
  final bool guides;
  @override
  void paint(Canvas canvas, Size size) {
    if (guides) {
      final p = Paint()..color = const Color(0xFF4B91C8)..strokeWidth = 1;
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    }
    if (strokes.length > 1) {
      final p = Paint()..color = Colors.black..strokeWidth = 2.2..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      final path = Path()..moveTo(strokes.first.dx, strokes.first.dy);
      for (final point in strokes.skip(1)) { path.lineTo(point.dx, point.dy); }
      canvas.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(covariant SketchPainter old) => old.strokes != strokes || old.guides != guides;
}
