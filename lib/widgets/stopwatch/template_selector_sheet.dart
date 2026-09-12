import 'package:flutter/material.dart';
import '../../models.dart';
import '../../storage_service.dart';
import '../../theme.dart';
import '../../time_log_controller.dart';

class TemplateSelectorSheet extends StatefulWidget {
  final TimeLogNotifier state;
  const TemplateSelectorSheet({super.key, required this.state});

  @override
  State<TemplateSelectorSheet> createState() => _TemplateSelectorSheetState();
}

class _TemplateSelectorSheetState extends State<TemplateSelectorSheet> {
  final StorageService _storage = StorageService();
  TemplateFolder? _currentFolder;
  List<TemplateFolder> _folders = [];
  List<OperationTemplate> _templates = [];
  List<OperationTemplate> _allTemplates = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _allTemplates = await _storage.getAllTemplates();

    if (_currentFolder == null) {
      _folders = await _storage.getFolders();
      _templates = await _storage.getTemplates(folderId: null);
    } else {
      _folders = [];
      _templates = await _storage.getTemplates(folderId: _currentFolder!.id);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateIntoFolder(TemplateFolder folder) {
    setState(() => _currentFolder = folder);
    _loadData();
  }

  void _navigateBack() {
    setState(() => _currentFolder = null);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentFolder != null && _searchQuery.isEmpty)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                  onPressed: _navigateBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_currentFolder != null && _searchQuery.isEmpty) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Resultados de Búsqueda'
                      : (_currentFolder == null ? 'Seleccionar Ruta Estándar' : _currentFolder!.name),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: _currentFolder == null && _searchQuery.isEmpty ? TextAlign.center : TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onTap: () {
              if (!_searchFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_searchFocusNode);
              }
            },
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número...',
              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, color: AppTheme.getTealAccent(context)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)), onPressed: () => _searchController.clear())
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final titleStyle = TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold);
    final subtitleStyle = TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.54));

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.getTealAccent(context)));
    }

    if (_searchQuery.isNotEmpty) {
      final filtered = _allTemplates.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
      if (filtered.isEmpty) {
        return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text('No se encontraron coincidencias', style: subtitleStyle)));
      }
      return ListView(
        shrinkWrap: true,
        children: filtered.map((template) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.route, color: Colors.white, size: 20)),
          title: Text(template.name, style: titleStyle),
          subtitle: Text('${template.steps.length} pasos programados', style: subtitleStyle),
          onTap: () {
            widget.state.loadTemplate(template);
            Navigator.pop(context);
          },
        )).toList(),
      );
    }

    if (_folders.isEmpty && _templates.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text('Carpeta vacía', style: subtitleStyle)));
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ..._folders.map((folder) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.folder, color: Colors.white, size: 20)),
          title: Text(folder.name, style: titleStyle),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)),
          onTap: () => _navigateIntoFolder(folder),
        )),
        ..._templates.map((template) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.route, color: Colors.white, size: 20)),
          title: Text(template.name, style: titleStyle),
          subtitle: Text('${template.steps.length} pasos programados', style: subtitleStyle),
          onTap: () {
            widget.state.loadTemplate(template);
            Navigator.pop(context);
          },
        )),
      ],
    );
  }
}
