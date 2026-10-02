import 'dart:async';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class Dialogs {
  Dialogs._();

  BuildContext get _context => rootNavigatorKey.currentContext!;

  Future<T?> showCommonDialog<T>({
    required Widget child,
    BuildContext? context,
    bool? dismissible,
  }) async {
    final target = context ?? _context;
    return showModal<T>(
      useRootNavigator: false,
      context: target,
      configuration: FadeScaleTransitionConfiguration(
        barrierColor: Theme.of(target).colorScheme.modalScrim,
        barrierDismissible: dismissible ?? true,
      ),
      builder: (_) => Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _DialogFrost())),
          child,
        ],
      ),
    );
  }

  Future<bool?> showMessage({
    required InlineSpan message,
    BuildContext? context,
    String? title,
    String? confirmText,
    String? cancelText,
    bool cancelable = true,
    bool? dismissible,
  }) async {
    return showCommonDialog<bool>(
      context: context,
      dismissible: dismissible,
      child: Builder(
        builder: (context) {
          final appLocalizations = context.appLocalizations;
          return CommonDialog(
            title: title ?? appLocalizations.tip,
            actions: [
              if (cancelable)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(cancelText ?? appLocalizations.cancel),
                ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(confirmText ?? appLocalizations.confirm),
              ),
            ],
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.labelLarge,
                    children: [message],
                  ),
                  style: const TextStyle(overflow: TextOverflow.visible),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> showUpdateProgress({
    required String version,
    required Future<void> Function(
      void Function(DesktopUpdateProgress progress) onProgress,
    )
    task,
  }) async {
    await showCommonDialog<void>(
      dismissible: false,
      child: _UpdateProgressDialog(version: version, task: task),
    );
  }

  Future<bool?> showAllUpdatingMessagesDialog(
    List<UpdatingMessage> messages,
  ) async {
    return showCommonDialog<bool>(
      child: Builder(
        builder: (context) {
          final appLocalizations = context.appLocalizations;
          return CommonDialog(
            backgroundColor: context.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: appLocalizations.tip,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(appLocalizations.confirm),
              ),
            ],
            child: generateSectionV3(
              items: messages.map(
                (message) => _UpdatingMessageItem(message: message),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> showDisclaimer() async {
    return await showCommonDialog<bool>(
          dismissible: false,
          child: CommonDialog(
            title: currentAppLocalizations.disclaimer,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(_context).pop<bool>(false);
                },
                child: Text(currentAppLocalizations.exit),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(_context).pop<bool>(true);
                },
                child: Text(currentAppLocalizations.agree),
              ),
            ],
            child: Text(currentAppLocalizations.disclaimerDesc),
          ),
        ) ??
        false;
  }

  void showNotifier(
    String text, {
    MessageLevel level = MessageLevel.info,
    MessageActionState? actionState,
  }) {
    rootNavigatorKey.currentContext?.showNotifier(
      text,
      level: level,
      actionState: actionState,
    );
  }

  Future<void> openUrl(String url) async {
    final res = await showMessage(
      message: TextSpan(text: url),
      title: currentAppLocalizations.externalLink,
      confirmText: currentAppLocalizations.go,
    );
    if (res != true) {
      return;
    }
    unawaited(launchUrl(Uri.parse(url)));
  }
}

class _UpdateProgressDialog extends StatefulWidget {
  final String version;
  final Future<void> Function(
    void Function(DesktopUpdateProgress progress) onProgress,
  )
  task;

  const _UpdateProgressDialog({required this.version, required this.task});

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  DesktopUpdateProgress _progress = const DesktopUpdateProgress(
    stage: DesktopUpdateStage.downloading,
  );
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    try {
      await widget.task((progress) {
        if (!mounted) return;
        setState(() {
          _progress = progress;
        });
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = compactError(error);
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kib = bytes / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
    return '${(kib / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final error = _error;
    final installing = _progress.stage == DesktopUpdateStage.installing;
    final fraction = _progress.fraction;
    final received = _formatBytes(_progress.receivedBytes);
    final total = _progress.totalBytes > 0
        ? _formatBytes(_progress.totalBytes)
        : null;
    return CommonDialog(
      title: '${appLocalizations.update} ${widget.version}',
      actions: error == null
          ? null
          : [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(appLocalizations.confirm),
              ),
            ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            installing
                ? '${appLocalizations.update} · ${appLocalizations.restart}'
                : appLocalizations.download,
            style: context.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: fraction),
          const SizedBox(height: 8),
          if (!installing)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  total == null ? received : '$received / $total',
                  style: context.textTheme.bodySmall,
                ),
                if (fraction != null)
                  Text(
                    '${(fraction * 100).toStringAsFixed(0)}%',
                    style: context.textTheme.bodySmall,
                  ),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdatingMessageItem extends StatelessWidget {
  final UpdatingMessage message;

  const _UpdatingMessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecorationListItem(
      minVerticalPadding: 12,
      title: TooltipText(
        text: Text(message.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      subtitle: TooltipText(
        text: Text(
          message.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

final dialogs = Dialogs._();

/// Frosts the window behind a dialog so the glass panel reads on its own.
class _DialogFrost extends StatelessWidget {
  const _DialogFrost();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: const SizedBox.expand(),
    );
  }
}
