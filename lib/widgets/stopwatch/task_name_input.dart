import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../time_log_controller.dart';
import '../../time_log_state.dart';
import 'template_selector_sheet.dart';

class TaskNameInput extends StatelessWidget {
  final FocusNode focusNode;
  final TimeLogState state;
  final TimeLogNotifier notifier;

  const TaskNameInput({
    super.key,
    required this.focusNode,
    required this.state,
    required this.notifier,
  });

  void _showTemplateSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: TemplateSelectorSheet(state: notifier),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTemplateActive = state.activeTemplate != null;
    final tealColor = AppTheme.getTealAccent(context);

    return SizedBox(
      height: 50,
      child: TextField(
        controller: notifier.taskNameController,
        focusNode: focusNode,
        enableInteractiveSelection: true,
        onChanged: (value) => notifier.updateTaskName(value),
        onTap: () {
          final text = notifier.taskNameController.text;
          if (text.isNotEmpty && notifier.taskNameController.selection.isCollapsed) {
            notifier.taskNameController.selection = TextSelection.fromPosition(
              TextPosition(offset: notifier.taskNameController.selection.baseOffset),
            );
          }
        },
        onSubmitted: (_) => focusNode.unfocus(),
        style: TextStyle(
          color: isTemplateActive ? tealColor : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: isTemplateActive ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: 'Nombre de la tarea...',
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          prefixIcon: IconButton(
            icon: Icon(
              isTemplateActive ? Icons.route : Icons.alt_route,
              color: isTemplateActive ? Colors.orangeAccent : tealColor,
              size: 20,
            ),
            tooltip: 'Cargar Ruta Estándar',
            onPressed: () => _showTemplateSelector(context),
          ),
          suffixIcon: isTemplateActive
              ? IconButton(
                  icon: const Icon(Icons.cancel_presentation, color: Colors.orangeAccent, size: 20),
                  tooltip: 'Desvincular Ruta',
                  onPressed: () => notifier.clearTemplate(),
                )
              : IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    notifier.taskNameController.clear();
                    notifier.updateTaskName('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: isTemplateActive ? BorderSide(color: tealColor, width: 1.5) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
