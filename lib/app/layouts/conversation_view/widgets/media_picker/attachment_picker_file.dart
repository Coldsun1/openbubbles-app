import 'dart:typed_data';

import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/ui/theme_helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime_type/mime_type.dart';
import 'package:photo_manager/photo_manager.dart';

class AttachmentPickerFile extends StatefulWidget {
  AttachmentPickerFile({
    super.key,
    required this.onTap,
    required this.data,
    required this.controller,
    this.selectedPath,
    this.isPending = false,
  });
  final AssetEntity data;
  final Future<void> Function() onTap;
  final ConversationViewController controller;
  final String? selectedPath;
  final bool isPending;

  @override
  State<AttachmentPickerFile> createState() => _AttachmentPickerFileState();
}

class _AttachmentPickerFileState extends OptimizedState<AttachmentPickerFile> {
  Uint8List? image;
  String? path;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final file = await widget.data.file;
    if (file == null) return;
    path = file.path;
    try {
      image = await widget.data.thumbnailDataWithSize(
        const ThumbnailSize.square(300),
        quality: 85,
      );
    } catch (_) {
      if (widget.data.type == AssetType.video) image = fs.noVideoPreviewIcon;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hideAttachments = ss.settings.redactedMode.value && ss.settings.hideAttachments.value;

    return Obx(() {
      bool containsThis = widget.controller.pickedAttachments.firstWhereOrNull(
        (e) => (path != null && e.path == path)
            || (widget.selectedPath != null && e.path == widget.selectedPath),
      ) != null;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (image != null)
                Image.memory(
                  image!,
                  fit: BoxFit.cover,
                  width: 150,
                  height: 150,
                  cacheWidth: 300,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) {
                      return Positioned.fill(
                        child: Container(
                          color: context.theme.colorScheme.properSurface,
                        ),
                      );
                    } else {
                      return child;
                    }
                  },
                ),
              if (image == null || hideAttachments)
                Positioned.fill(
                  child: Container(
                    color: context.theme.colorScheme.properSurface,
                    alignment: Alignment.center,
                    child: Text(
                      mime(path) ?? "",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (containsThis)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.theme.colorScheme.primary, width: 3),
                      ),
                    ),
                  ),
                ),
              if (widget.isPending)
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.theme.colorScheme.properSurface.withOpacity(0.9),
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.theme.colorScheme.primary,
                  ),
                )
              else if (containsThis)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.colorScheme.primary,
                    ),
                    child: Icon(
                      iOS ? CupertinoIcons.check_mark : Icons.check,
                      color: context.theme.colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                )
              else if (widget.data.type == AssetType.video)
                Icon(
                  iOS ? CupertinoIcons.play_circle_fill : Icons.play_circle_filled,
                  color: context.theme.colorScheme.onPrimary,
                  size: 50,
                ),
            ],
          ),
        ),
      );
    });
  }
}
