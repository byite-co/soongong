import 'dart:typed_data';
import 'package:flutter/material.dart';

class CropSelection {
  const CropSelection(this.rect, this.turns);
  final Rect rect;
  final int turns;
}

class StudyCropDialog extends StatefulWidget {
  const StudyCropDialog({super.key, required this.image});
  final Uint8List image;
  @override
  State<StudyCropDialog> createState() => _StudyCropDialogState();
}

class _StudyCropDialogState extends State<StudyCropDialog> {
  var x = const RangeValues(0, 1), y = const RangeValues(0, 1);
  int turns = 0;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('영역 선택 · 한 번에 수식 하나'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            height: 220,
            child: LayoutBuilder(
              builder: (context, bounds) => Stack(
                fit: StackFit.expand,
                children: [
                  RotatedBox(
                    quarterTurns: turns,
                    child: Image.memory(
                      widget.image,
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => const Text('지원하지 않는 사진'),
                    ),
                  ),
                  Positioned(
                    left: x.start * bounds.maxWidth,
                    top: y.start * bounds.maxHeight,
                    width: (x.end - x.start) * bounds.maxWidth,
                    height: (y.end - y.start) * bounds.maxHeight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              turns = (turns + 1) % 4;
              x = const RangeValues(0, 1);
              y = const RangeValues(0, 1);
            }),
            child: const Text('오른쪽으로 90° 회전'),
          ),
          const Text('가로 영역'),
          RangeSlider(
            values: x,
            onChanged: (v) {
              if (v.end - v.start >= .01) setState(() => x = v);
            },
          ),
          const Text('세로 영역'),
          RangeSlider(
            values: y,
            onChanged: (v) {
              if (v.end - v.start >= .01) setState(() => y = v);
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(
          context,
          CropSelection(Rect.fromLTRB(x.start, y.start, x.end, y.end), turns),
        ),
        child: const Text('영역 적용'),
      ),
    ],
  );
}
