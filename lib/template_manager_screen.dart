import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import 'models.dart';

class TemplateManagerScreen extends ConsumerStatefulWidget {
  const TemplateManagerScreen({super.key});
  @override
  ConsumerState<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends ConsumerState<TemplateManagerScreen> {
  final StorageService _storage = StorageService();
  
  // Estado del explorador de archivos
  TemplateFolder? _currentFolder; 
  List<TemplateFolder> _folders = [];
  List<OperationTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    if (_currentFolder == null) {
      _folders = await _storage.getFolders();
      _templates = await _storage.getTemplates(folderId: null);
    } else {
      _folders = []; 
      _templates = await _storage.getTemplates(folderId: _currentFolder!.id);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateIntoFolder(TemplateFolder folder) {
    setState(() => _currentFolder = folder);
    _loadData();
  }

  Future<bool> _navigateBack() async {
    if (_currentFolder != null) {
      setState(() => _currentFolder = null);
      await _loadData();
      return false; 
    }
    return true; 
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== ACCIONES CREATIVAS ====================
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_currentFolder == null ? 'Crear en Raíz' : 'Crear en ${_currentFolder!.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_currentFolder == null) ...[ 
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.create_new_folder, color: Colors.white)),
                title: const Text('Nueva Carpeta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Agrupa tus rutas por área o modelo.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _createNewFolder();
                },
              ),
              const SizedBox(height: 10),
            ],
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.route, color: Colors.white)),
              title: const Text('Nueva Ruta Estándar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Crea una secuencia de pasos para tomar tiempos.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _createNewTemplate();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewFolder() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Row(children: [Icon(Icons.folder, color: Colors.amber), SizedBox(width: 10), Text('Nueva Carpeta', style: TextStyle(color: Colors.white))]),
        content: TextField(
          controller: folderController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Nombre de la carpeta', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (folderController.text.trim().isNotEmpty) {
                await _storage.createFolder(folderController.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('CREAR', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _createNewTemplate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateTemplateDialog(folderId: _currentFolder?.id),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  // ==================== EDICIÓN Y BORRADO ====================
  Future<void> _deleteFolder(TemplateFolder folder) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('¿Borrar Carpeta?', style: TextStyle(color: Colors.white)),
        content: Text('Esto borrará la carpeta "${folder.name}" y TODAS las rutas estándar que contenga. ¿Estás seguro?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.deleteFolder(folder.id);
      _loadData();
    }
  }

  void _editTemplateName(OperationTemplate template) {
    final nameController = TextEditingController(text: template.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('Renombrar Ruta', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent))),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != template.name) {
                await _storage.updateTemplateName(template.id, newName);
                if (!mounted) return;
                Navigator.pop(context);
                _loadData(); 
              }
            },
            child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editTemplateSteps(OperationTemplate template) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditStepsDialog(template: template),
    ).then((value) {
      if (value == true) {
        _loadData();
      }
    });
  }

  Future<void> _exportTemplate(OperationTemplate template) async {
    String? fileName = await _storage.exportTemplate(template);
    if (!mounted) return;
    
    if (fileName != null) {
      _showSnackBar('Exportado a $fileName', Colors.blueAccent);
    } else {
      _showSnackBar('Error al exportar', Colors.redAccent);
    }
  }

  Future<void> _importTemplate() async {
    bool success = await _storage.importTemplate(currentFolderId: _currentFolder?.id);
    if (!mounted) return;
    
    if (success) {
      _showSnackBar('Plantilla importada con éxito', Colors.tealAccent.shade700);
      _loadData();
    } else {
      _showSnackBar('No se importó ninguna plantilla', Colors.orangeAccent);
    }
  }

  Future<void> _importMultiple() async {
    int? targetFolderId = _currentFolder?.id;
    String? newFolderName;
    
    if (targetFolderId == null) {
      final folderController = TextEditingController();
      bool? create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: const Row(children: [Icon(Icons.folder_copy, color: Colors.amber), SizedBox(width: 10), Text('Nombrar nueva carpeta', style: TextStyle(color: Colors.white, fontSize: 16))]),
          content: TextField(
            controller: folderController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Nombre para las rutas importadas', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONTINUAR', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      
      if (create != true || folderController.text.trim().isEmpty) return;
      newFolderName = folderController.text.trim();
    }
    
    _showSnackBar('Selecciona los archivos (puedes seleccionar varios)...', Colors.white54);
    bool success = await _storage.importMultipleTemplates(
      targetFolderId: targetFolderId,
      newFolderName: newFolderName
    );
    
    if (!mounted) return;
    
    if (success) {
      _showSnackBar(targetFolderId == null ? 'Carpeta y rutas importadas con éxito' : 'Rutas importadas con éxito', Colors.amber);
      _loadData();
    } else {
      _showSnackBar('No se importó nada o se canceló', Colors.orangeAccent);
    }
  }

  // ==================== UI PRINCIPAL ====================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool shouldPop = await _navigateBack();
        if (shouldPop && mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _currentFolder != null 
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _navigateBack()) 
              : null,
          title: Text(_currentFolder == null ? 'Rutas Estándar' : _currentFolder!.name),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download, color: Colors.blueAccent),
              tooltip: 'Opciones de Importación',
              color: const Color(0xFF252525),
              onSelected: (value) {
                if (value == 'file') {
                  _importTemplate();
                } else if (value == 'multiple') {
                  _importMultiple();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'file',
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Importar 1 Ruta', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'multiple',
                  child: Row(
                    children: [
                      Icon(_currentFolder == null ? Icons.create_new_folder : Icons.library_add, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Text(_currentFolder == null ? 'Importar Varios a Carpeta' : 'Importar Varias Rutas', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateOptions,
          backgroundColor: Colors.tealAccent.shade700,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('NUEVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
            : (_folders.isEmpty && _templates.isEmpty)
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      // SECCIÓN DE CARPETAS
                      if (_folders.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text("CARPETAS", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        ..._folders.map((folder) => Card(
                          color: const Color(0xFF252525),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.folder, color: Colors.amber, size: 36),
                            title: Text(folder.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteFolder(folder)),
                                const Icon(Icons.chevron_right, color: Colors.white54),
                              ],
                            ),
                            onTap: () => _navigateIntoFolder(folder),
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // SECCIÓN DE RUTAS (PLANTILLAS)
                      if (_templates.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(_currentFolder == null ? "RUTAS SIN CARPETA" : "RUTAS EN ${_currentFolder!.name.toUpperCase()}", style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        ..._templates.map((template) => _buildTemplateCard(template)),
                      ]
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_currentFolder == null ? Icons.folder_open : Icons.route_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(_currentFolder == null ? 'No hay carpetas ni rutas creadas' : 'Esta carpeta está vacía', style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(OperationTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.list_alt, color: Colors.white, size: 20)),
        title: Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('${template.steps.length} pasos estandarizados', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        children: [
          const Divider(color: Colors.white10, height: 1),
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ...template.steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key + 1}.', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editTemplateName(template),
                        icon: const Icon(Icons.edit, color: Colors.orangeAccent, size: 16),
                        label: const Text('Renombrar', style: TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                      ),
                      TextButton.icon(
                        onPressed: () => _editTemplateSteps(template),
                        icon: const Icon(Icons.format_list_bulleted, color: Colors.greenAccent, size: 16),
                        label: const Text('Pasos', style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                      ),
                      TextButton.icon(
                        onPressed: () => _exportTemplate(template),
                        icon: const Icon(Icons.upload_file, color: Colors.blueAccent, size: 16),
                        label: const Text('Exportar', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await StorageService().deleteTemplate(template.id);
                          _loadData();
                        },
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==============================================================================
// DIÁLOGOS DE EDICIÓN Y CREACIÓN
// ==============================================================================

class _CreateTemplateDialog extends StatefulWidget {
  final int? folderId;
  const _CreateTemplateDialog({this.folderId});
  @override
  State<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<_CreateTemplateDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stepController = TextEditingController();
  final List<String> _steps = [];

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _steps.add(text);
        _stepController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF252525),
      title: const Text('Nueva Ruta Estándar', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nombre del Proceso', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Descripción del paso...', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent))),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.tealAccent), onPressed: _addStep)
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 12, backgroundColor: Colors.white10, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.tealAccent))),
                    title: Text(_steps[index], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    trailing: IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => setState(() => _steps.removeAt(index))),
                  );
                },
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
        TextButton(
          onPressed: () async {
            if (_nameController.text.trim().isNotEmpty && _steps.isNotEmpty) {
              await StorageService().saveTemplate(_nameController.text.trim(), _steps, folderId: widget.folderId);
              if (!mounted) return;
              Navigator.pop(context, true);
            }
          },
          child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _EditStepsDialog extends StatefulWidget {
  final OperationTemplate template;
  const _EditStepsDialog({required this.template});
  @override
  State<_EditStepsDialog> createState() => _EditStepsDialogState();
}

class _EditStepsDialogState extends State<_EditStepsDialog> {
  final TextEditingController _stepController = TextEditingController();
  late List<String> _steps;

  @override
  void initState() {
    super.initState();
    _steps = List<String>.from(widget.template.steps); 
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isNotEmpty) {
      setState(() { 
        _steps.add(text); 
        _stepController.clear(); 
      }); 
    }
  }

  void _editStepText(int index) {
    final editController = TextEditingController(text: _steps[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Editar Paso', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(controller: editController, style: const TextStyle(color: Colors.white), autofocus: true, decoration: const InputDecoration(focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() => _steps[index] = editController.text.trim()); 
              }
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF252525),
      title: const Text('Editar Pasos', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _stepController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Añadir nuevo paso...', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent))), onSubmitted: (_) => _addStep())),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.tealAccent), onPressed: _addStep)
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 12, backgroundColor: Colors.white10, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.tealAccent))),
                    title: Text(_steps[index], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 16, color: Colors.orangeAccent), onPressed: () => _editStepText(index)),
                        IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => setState(() => _steps.removeAt(index))),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
        TextButton(
          onPressed: () async {
            if (_steps.isNotEmpty) {
              await StorageService().updateTemplateSteps(widget.template.id, _steps);
              if (!mounted) return;
              Navigator.pop(context, true);
            }
          },
          child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}