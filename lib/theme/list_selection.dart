import 'package:a_pixel_game/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectableItem {
  final String label;
  final IconData icon;
  final bool experimental;

  const SelectableItem(this.label, this.icon, {this.experimental = false});
}

class ListSelection extends StatefulWidget {
  final RxInt selected;
  final List<SelectableItem> items;
  final Function(SelectableItem)? callback;

  const ListSelection({super.key, required this.selected, required this.items, this.callback});

  @override
  State<ListSelection> createState() => _ListSelectionState();
}

class _ListSelectionState extends State<ListSelection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.items.length, (index) {
        final first = index == 0;
        final last = index == widget.items.length - 1;

        final radius = BorderRadius.vertical(
          top: first ? const Radius.circular(defaultSpacing) : Radius.zero,
          bottom: last ? const Radius.circular(defaultSpacing) : Radius.zero,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: defaultSpacing * 0.5),
          child: Obx(
            () => Material(
              color: widget.selected.value == index ? Get.theme.colorScheme.primary : Get.theme.colorScheme.background,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: () {
                  widget.selected.value = index;
                  if (widget.callback != null) {
                    widget.callback!(widget.items[index]);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(defaultSpacing),
                  child: Row(
                    children: [
                      Icon(widget.items[index].icon, color: Get.theme.colorScheme.onPrimary),
                      horizontalSpacing(defaultSpacing),
                      Text(
                        widget.items[index].label.tr,
                        style: Get.theme.textTheme.bodyMedium!.copyWith(color: Get.theme.colorScheme.onSurface),
                      ),
                      horizontalSpacing(defaultSpacing),
                      widget.items[index].experimental
                          ? Container(
                              decoration: BoxDecoration(
                                color: Get.theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(defaultSpacing),
                              ),
                              padding: const EdgeInsets.all(elementSpacing),
                              child: Row(
                                children: [
                                  Icon(Icons.science, color: Get.theme.colorScheme.error),
                                  horizontalSpacing(elementSpacing),
                                  Text(
                                    "Experimental".tr,
                                    style: Get.theme.textTheme.bodyMedium!.copyWith(color: Get.theme.colorScheme.error),
                                  ),
                                  horizontalSpacing(elementSpacing)
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
