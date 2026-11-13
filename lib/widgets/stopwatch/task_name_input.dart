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
    final emerald = AppTheme.getTealAccent(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    int currentStep = 1;
    int totalSteps = 1;
    if (isTemplateActive && state.activeTemplate!.steps.isNotEmpty) {
      totalSteps = state.activeTemplate!.steps.length;
      currentStep = (state.currentTemplateStepIndex % totalSteps) + 1;
    }

    return Container(
      decoration: BoxDecoration(
        color: isLight 
            ? Colors.white 
            : Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTemplateActive
              ? AppTheme.amberIndustrial.withValues(alpha: isLight ? 0.7 : 0.5)
              : Theme.of(context).dividerColor.withValues(alpha: isLight ? 0.8 : 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          fontSize: 14,
          color: isTemplateActive 
              ? (isLight ? const Color(0xFFB45309) : AppTheme.amberIndustrial) 
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isTemplateActive ? FontWeight.w700 : FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Nombre de la tarea u operación...',
          hintStyle: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            fontSize: 13.5,
          ),
          filled: false,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: IconButton(
              icon: Icon(
                isTemplateActive ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                color: isTemplateActive ? AppTheme.amberIndustrial : emerald,
                size: 20,
              ),
              tooltip: isTemplateActive ? 'Plantilla Activa: ${state.activeTemplate!.name}' : 'Vincular Plantilla',
              onPressed: () => _showTemplateSelector(context),
            ),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTemplateActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.amberIndustrial.withValues(alpha: isLight ? 0.15 : 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.amberIndustrial.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Paso $currentStep/$totalSteps',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLight ? const Color(0xFFB45309) : AppTheme.amberIndustrial,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                  tooltip: 'Desvincular Plantilla',
                  onPressed: () => notifier.clearTemplate(),
                ),
              ] else ...[
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.45),
                    size: 18,
                  ),
                  onPressed: () {
                    notifier.taskNameController.clear();
                    notifier.updateTaskName('');
                  },
                ),
              ],
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
