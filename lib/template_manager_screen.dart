import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import 'models.dart';
import 'theme.dart';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final folders = _currentFolder == null ? await _storage.getFolders() : <TemplateFolder>[];
    final templates = await _storage.getTemplates(folderId: _currentFolder?.id);
    
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _templates = templates;
      _isLoading = false;
    });
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealAccent = AppTheme.getTealAccent(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentFolder == null ? 'CREAR ELEMENTO' : 'CREAR EN ${_currentFolder!.name.toUpperCase()}',
                style: TextStyle(
                  color: theme.textTheme.titleMedium?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              if (_currentFolder == null) ...[ 
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  tileColor: isDark ? AppTheme.amoledSurfaceContainer : AppTheme.lightSurfaceContainer,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.amberIndustrial.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.create_new_folder_rounded, color: AppTheme.amberIndustrial),
                  ),
                  title: const Text('Nueva Carpeta', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Agrupa tus plantillas por área, máquina o modelo.', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewFolder();
                  },
                ),
                const SizedBox(height: 10),
              ],
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.dividerColor),
                ),
                tileColor: isDark ? AppTheme.amoledSurfaceContainer : AppTheme.lightSurfaceContainer,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.alt_route_rounded, color: tealAccent),
                ),
                title: const Text('Nueva Plantilla', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Crea una secuencia de pasos para estandarizar tomas.', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _createNewTemplate();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewFolder() {
    final folderController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_rounded, color: AppTheme.amberIndustrial),
            SizedBox(width: 10),
            Text('Nueva Carpeta'),
          ],
        ),
        content: TextField(
          controller: folderController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la carpeta',
            hintText: 'Ej. Ensamble, Línea 2...',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.amberIndustrial, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.amberIndustrial,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              if (folderController.text.trim().isNotEmpty) {
                await _storage.createFolder(folderController.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('CREAR', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('¿Eliminar Carpeta?'),
        content: Text('Esta acción eliminará permanentemente la carpeta "${folder.name}" y TODAS las plantillas que contenga.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.crimsonOutlier,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.deleteFolder(folder.id);
      if (mounted) _loadData();
    }
  }

  void _editTemplateName(OperationTemplate template) {
    final nameController = TextEditingController(text: template.name);
    final tealAccent = AppTheme.getTealAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Plantilla'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nombre del proceso',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: tealAccent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tealAccent,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != template.name) {
                await _storage.updateTemplateName(template.id, newName);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadData(); 
              }
            },
            child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
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
      _showSnackBar('Plantilla importada con éxito', AppTheme.getTealAccent(context));
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
      final isDark = Theme.of(context).brightness == Brightness.dark;

      bool? create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.folder_zip_rounded, color: AppTheme.amberIndustrial),
              SizedBox(width: 10),
              Text('Nombrar nueva carpeta'),
            ],
          ),
          content: TextField(
            controller: folderController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre para las plantillas importadas',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.amberIndustrial, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.amberIndustrial,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      
      if (create != true || folderController.text.trim().isEmpty) return;
      newFolderName = folderController.text.trim();
    }
    
    _showSnackBar('Selecciona los archivos (puedes seleccionar varios)...', Colors.white70);
    bool success = await _storage.importMultipleTemplates(
      targetFolderId: targetFolderId,
      newFolderName: newFolderName
    );
    
    if (!mounted) return;
    
    if (success) {
      _showSnackBar(targetFolderId == null ? 'Carpeta y plantillas importadas con éxito' : 'Plantillas importadas con éxito', AppTheme.amberIndustrial);
      _loadData();
    } else {
      _showSnackBar('No se importó nada o se canceló', Colors.orangeAccent);
    }
  }

  // ==================== UI PRINCIPAL ====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealAccent = AppTheme.getTealAccent(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool shouldPop = await _navigateBack();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _currentFolder != null 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _navigateBack(),
                ) 
              : null,
          title: Text(
            _currentFolder == null ? 'Gestor de Plantillas' : _currentFolder!.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.file_download_outlined, color: AppTheme.skyPrecision),
              tooltip: 'Importar plantillas',
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.dividerColor),
              ),
              onSelected: (value) {
                if (value == 'file') {
                  _importTemplate();
                } else if (value == 'multiple') {
                  _importMultiple();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'file',
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, color: AppTheme.skyPrecision, size: 20),
                      const SizedBox(width: 12),
                      Text('Importar 1 Plantilla', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'multiple',
                  child: Row(
                    children: [
                      Icon(
                        _currentFolder == null ? Icons.create_new_folder_outlined : Icons.library_add_outlined,
                        color: AppTheme.amberIndustrial,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _currentFolder == null ? 'Importar Varios a Carpeta' : 'Importar Varias Plantillas',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateOptions,
          backgroundColor: tealAccent,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('NUEVA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          shape: const StadiumBorder(),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: tealAccent))
            : (_folders.isEmpty && _templates.isEmpty)
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      // SECCIÓN DE CARPETAS
                      if (_folders.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 14, color: AppTheme.amberIndustrial),
                              const SizedBox(width: 6),
                              Text(
                                "CARPETAS (${_folders.length})",
                                style: const TextStyle(
                                  color: AppTheme.amberIndustrial,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._folders.map((folder) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _navigateIntoFolder(folder),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.amberIndustrial.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.folder_rounded, color: AppTheme.amberIndustrial, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        folder.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.crimsonOutlier, size: 20),
                                      onPressed: () => _deleteFolder(folder),
                                      tooltip: 'Eliminar carpeta',
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                        const SizedBox(height: 20),
                      ],

                      // SECCIÓN DE PLANTILLAS
                      if (_templates.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.format_list_bulleted_rounded, size: 14, color: tealAccent),
                              const SizedBox(width: 6),
                              Text(
                                _currentFolder == null 
                                    ? "PLANTILLAS (${_templates.length})" 
                                    : "PLANTILLAS EN ${_currentFolder!.name.toUpperCase()} (${_templates.length})",
                                style: TextStyle(
                                  color: tealAccent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._templates.map((template) => _buildTemplateCard(template)),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.amoledSurface : AppTheme.lightSurfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(
              _currentFolder == null ? Icons.folder_open_rounded : Icons.format_list_bulleted_rounded,
              size: 48,
              color: theme.hintColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _currentFolder == null ? 'No hay carpetas ni plantillas' : 'Esta carpeta está vacía',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentFolder == null
                ? 'Crea o importa plantillas para estandarizar tus tomas.'
                : 'Usa el botón "+ NUEVA" para agregar plantillas aquí.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(OperationTemplate template) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealAccent = AppTheme.getTealAccent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tealAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.format_list_bulleted_rounded, color: tealAccent, size: 22),
          ),
          title: Text(
            template.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${template.steps.length} pasos estandarizados',
            style: theme.textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: theme.iconTheme.color?.withValues(alpha: 0.8)),
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'rename':
                  _editTemplateName(template);
                  break;
                case 'steps':
                  _editTemplateSteps(template);
                  break;
                case 'export':
                  _exportTemplate(template);
                  break;
                case 'delete':
                  await StorageService().deleteTemplate(template.id);
                  if (mounted) _loadData();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.drive_file_rename_outline_rounded, color: AppTheme.amberIndustrial, size: 18),
                    const SizedBox(width: 12),
                    Text('Renombrar', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'steps',
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: tealAccent, size: 18),
                    const SizedBox(width: 12),
                    Text('Editar Pasos', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file_rounded, color: AppTheme.skyPrecision, size: 18),
                    const SizedBox(width: 12),
                    Text('Exportar', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppTheme.crimsonOutlier, size: 18),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: AppTheme.crimsonOutlier)),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Divider(color: theme.dividerColor, height: 1),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.amoledSurfaceContainer : AppTheme.lightSurfaceContainer,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                children: [
                  ...template.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tealAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              color: tealAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              e.value,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            )
          ],
        ),
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
  void dispose() {
    _nameController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealColor = AppTheme.getTealAccent(context);

    return AlertDialog(
      title: const Text('Nueva Plantilla'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Proceso',
                hintText: 'Ej. Ensamble de Motor, Cambio de Molde...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tealColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: InputDecoration(
                      hintText: 'Añadir paso a la secuencia...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: tealColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: tealColor.withValues(alpha: 0.15),
                    foregroundColor: tealColor,
                  ),
                  onPressed: _addStep,
                  tooltip: 'Agregar paso',
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Agrega al menos un paso para guardar la plantilla.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.amoledSurfaceContainer : AppTheme.lightSurfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tealColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tealColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _steps[index],
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.crimsonOutlier),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => setState(() => _steps.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tealColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
          onPressed: () async {
            if (_nameController.text.trim().isNotEmpty && _steps.isNotEmpty) {
              await StorageService().saveTemplate(_nameController.text.trim(), _steps, folderId: widget.folderId);
              if (!context.mounted) return;
              Navigator.pop(context, true);
            }
          },
          child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
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
    final tealColor = AppTheme.getTealAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Paso'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Descripción del paso',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: tealColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() => _steps[index] = editController.text.trim()); 
              }
              Navigator.pop(context);
            },
            child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealColor = AppTheme.getTealAccent(context);

    return AlertDialog(
      title: Text('Editar Pasos (${widget.template.name})'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: InputDecoration(
                      hintText: 'Añadir nuevo paso...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: tealColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: tealColor.withValues(alpha: 0.15),
                    foregroundColor: tealColor,
                  ),
                  onPressed: _addStep,
                  tooltip: 'Agregar paso',
                ),
              ],
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.amoledSurfaceContainer : AppTheme.lightSurfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tealColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tealColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _steps[index],
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.amberIndustrial),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => _editStepText(index),
                          tooltip: 'Editar texto',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.crimsonOutlier),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => setState(() => _steps.removeAt(index)),
                          tooltip: 'Eliminar paso',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: tealColor,
            foregroundColor: isDark ? Colors.black : Colors.white,
          ),
          onPressed: () async {
            if (_steps.isNotEmpty) {
              await StorageService().updateTemplateSteps(widget.template.id, _steps);
              if (!context.mounted) return;
              Navigator.pop(context, true);
            }
          },
          child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}