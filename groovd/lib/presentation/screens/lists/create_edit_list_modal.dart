import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/user_music_list.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/state/user_lists_provider.dart';

class CreateEditListModal extends ConsumerStatefulWidget {
  final UserMusicList? existingList;

  const CreateEditListModal({super.key, this.existingList});

  static Future<UserMusicList?> show(BuildContext context, {UserMusicList? existingList}) {
    return showModalBottomSheet<UserMusicList?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateEditListModal(existingList: existingList),
    );
  }

  @override
  ConsumerState<CreateEditListModal> createState() => _CreateEditListModalState();
}

class _CreateEditListModalState extends ConsumerState<CreateEditListModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  bool _isSaving = false;

  bool get isEditing => widget.existingList != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingList?.title ?? '');
    _descController = TextEditingController(text: widget.existingList?.description ?? '');
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await ref.read(userListsProvider.notifier).updateList(
              widget.existingList!.id,
              title: title,
              description: _descController.text.trim(),
            );
        if (mounted) {
          Navigator.of(context).pop(ref.read(listByIdProvider(widget.existingList!.id)));
        }
      } else {
        final created = await ref.read(userListsProvider.notifier).createList(
              title,
              description: _descController.text.trim(),
            );
        if (mounted) {
          Navigator.of(context).pop(created);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: bottomInset > 0 ? bottomInset : 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.cyberCyan, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderBold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'EDIT LIST ARCHIVE' : 'INITIALIZE CURATED LIST',
                        style: AppTypography.displaySmall(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EDITORIAL // CUSTOM COLLECTION',
                        style: AppTypography.monoLabel(color: AppColors.cyberCyan, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // List Title Input
            Text(
              'LIST TITLE // HEADLINE',
              style: AppTypography.monoLabel(fontSize: 10),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.characters,
              style: AppTypography.headline(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 2026 SHOEGAZE ESSENTIALS',
                hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // Description / Curator Notes
            Text(
              'CURATOR STATEMENT // NOTES',
              style: AppTypography.monoLabel(fontSize: 10),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: AppTypography.bodyLarge(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add context, thematic narrative, or sonic vibe notes...',
                hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            BrutalistButton(
              label: _isSaving
                  ? 'SAVING ARCHIVE...'
                  : isEditing
                      ? 'UPDATE LIST'
                      : 'CREATE LIST ARCHIVE',
              icon: Icons.check,
              isFullWidth: true,
              backgroundColor: AppColors.cyberCyan,
              textColor: AppColors.pureBlack,
              borderColor: AppColors.pureBlack,
              onPressed: _titleController.text.trim().isEmpty || _isSaving ? null : _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
