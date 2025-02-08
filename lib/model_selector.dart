import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model_state.dart';
import 'llm_model.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ModelState, LLMModel>(
      selector: (_, modelState) => modelState.currentModel,
      builder: (context, currentModel, child) {
        return GestureDetector(
          onTapDown: (TapDownDetails details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final Offset offset = renderBox.localToGlobal(Offset.zero);
            final Size size = renderBox.size;
            showDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (BuildContext context) {
                return _FloatingMenuContent(
                  buttonOffset: offset,
                  buttonSize: size,
                );
              },
            );
          },
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: 'ChatTQW',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextSpan(
                  text: ' ${currentModel.short} ›',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        );
      },
    );
  }
}

class _FloatingMenuContent extends StatefulWidget {
  final Offset buttonOffset;
  final Size buttonSize;
  const _FloatingMenuContent({
    required this.buttonOffset,
    required this.buttonSize,
  });

  @override
  State<_FloatingMenuContent> createState() => _FloatingMenuContentState();
}

class _FloatingMenuContentState extends State<_FloatingMenuContent> {
  // This flag is used to remove the shadow from the floating menu when the
  // second-level (company) menu is open.
  bool _subMenuOpen = false;
  double topPadding = 0;

  Future<void> _showCompanyMenu(
      String company, Offset position, Size itemSize) async {
    // Remove the shadow from the first-level menu.
    setState(() {
      _subMenuOpen = true;
    });

    final currentModel = context.read<ModelState>().currentModel;
    final models = ModelState.availableModels
        .where((model) => model.company.value == company)
        .toList();

    // Show the company submenu. This menu always has a shadow.
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        // Convert the models list into a list with indices so that we can add
        // dividers between items only.
        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy - topPadding,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header that allows closing the submenu.
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                company,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Use a divider only if there are items following.
                      if (models.isNotEmpty)
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      // Build each model item with a divider between (but not after) items.
                      ...models.asMap().entries.map((entry) {
                        final index = entry.key;
                        final model = entry.value;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                context.read<ModelState>().currentModel = model;
                                // Close both menus.
                                Navigator.pop(context); // Close company menu.
                                Navigator.pop(context); // Close floating menu.
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        model.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (model == currentModel)
                                      // const SizedBox(width: 8),
                                      Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < models.length - 1)
                              const Divider(
                                  height: 1, color: Color(0xFFE0E0E0)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // Restore the shadow on the first-level menu.
    setState(() {
      _subMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlayContext = Overlay.of(context)!.context;
    topPadding = MediaQuery.of(overlayContext).padding.top;
    final companies = ModelState.availableModels
        .map((model) => model.company.value)
        .toSet()
        .toList();

    return Stack(
      children: [
        Positioned(
          left: widget.buttonOffset.dx - 100 + (widget.buttonSize.width / 2),
          top: widget.buttonOffset.dy + widget.buttonSize.height - topPadding,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // Remove the shadow if a submenu is open.
                boxShadow: _subMenuOpen
                    ? null
                    : const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Build each company item with a divider only between items.
                  ...companies.asMap().entries.map((entry) {
                    final index = entry.key;
                    final company = entry.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(builder: (BuildContext context) {
                          return InkWell(
                            onTapDown: (TapDownDetails details) {
                              final RenderBox itemBox =
                                  context.findRenderObject() as RenderBox;
                              final Offset itemPosition =
                                  itemBox.localToGlobal(Offset.zero);
                              _showCompanyMenu(
                                  company, itemPosition, itemBox.size);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Opacity(
                                opacity: _subMenuOpen ? 0.6 : 1.0,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        company,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        if (index < companies.length - 1)
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
