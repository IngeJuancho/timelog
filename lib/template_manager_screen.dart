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
  List<OperationTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _storage.getTemplates();
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
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

  Future<void> _importTemplate() async {
    try {
      bool success = await _storage.importTemplate();
      if (success) {
        _showSnackBar('Plantilla importada con éxito', Colors.tealAccent.shade700);
        _loadTemplates();
      }
    } catch (e) {
      _showSnackBar('Error al importar la plantilla', Colors.redAccent);
    }
  }

  Future<void> _exportTemplate(OperationTemplate template) async {
    try {
      String? fileName = await _storage.exportTemplate(template);
      if (fileName != null) {
        _showSnackBar('Exportado a $fileName', Colors.blueAccent);
      }
    } catch (e) {
      _showSnackBar('Error al exportar', Colors.redAccent);
    }
  }

  Future<void> _deleteTemplate(int id) async {
    await _storage.deleteTemplate(id);
    _loadTemplates();
  }

  void _createNewTemplate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CreateTemplateDialog(),
    ).then((value) {
      if (value == true) _loadTemplates();
    });
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
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != template.name) {
                await _storage.updateTemplateName(template.id, newName);
                _loadTemplates(); 
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
      if (value == true) _loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Operación'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.blueAccent),
            tooltip: 'Importar .json',
            onPressed: _importTemplate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        backgroundColor: Colors.tealAccent.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NUEVA RUTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : _templates.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No hay plantillas guardadas', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ExpansionTile(
                        shape: const RoundedRectangleBorder(side: BorderSide.none),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.list_alt, color: Colors.white, size: 20),
                        ),
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
                                // Contenedor de botones optimizado con Wrap
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
                                        onPressed: () => _deleteTemplate(template.id),
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
                  },
                ),
    );
  }
}

// Dialogo interno para crear una nueva plantilla
class _CreateTemplateDialog extends StatefulWidget {
  const _CreateTemplateDialog();
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
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                  onPressed: _addStep,
                )
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
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                      onPressed: () => setState(() => _steps.removeAt(index)),
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
            if (_nameController.text.trim().isNotEmpty && _steps.isNotEmpty) {
              await StorageService().saveTemplate(_nameController.text.trim(), _steps);
              if (mounted) Navigator.pop(context, true);
            }
          },
          child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// NUEVO: Dialogo interactivo para editar los pasos de una plantilla existente
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
    _steps = List<String>.from(widget.template.steps); // Clonamos la lista para poder alterarla sin romper
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
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                setState(() => _steps[index] = newText);
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
  void dispose() {
    _stepController.dispose();
    super.dispose();
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
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Añadir nuevo paso...', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent))),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                  onPressed: _addStep,
                )
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
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.orangeAccent),
                          onPressed: () => _editStepText(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                          onPressed: () => setState(() => _steps.removeAt(index)),
                        ),
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
              if (mounted) Navigator.pop(context, true);
            }
          },
          child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}