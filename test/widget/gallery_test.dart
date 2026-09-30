import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/dev/gallery/gallery_screen.dart';
import 'package:soongong/core/strings/gallery_strings.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('gallery renders in light and toggles to dark', (tester) async {
    await pumpThemed(tester, const GalleryScreen(), surfaceSize: const Size(390, 2400));
    expect(find.text(GalleryStrings.title), findsOneWidget);
    expect(find.text(GalleryStrings.sectionNeutral), findsOneWidget);
    expect(find.text(GalleryStrings.sectionSubjects), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip(GalleryStrings.toggleTheme));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // spinner never settles
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(Theme.of(tester.element(find.byWidget(scaffold))).brightness,
        Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery renders in dark without layout errors', (tester) async {
    await pumpThemed(
      tester,
      const GalleryScreen(),
      brightness: Brightness.dark,
      surfaceSize: const Size(390, 2400),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text(GalleryStrings.sectionRing), findsOneWidget);
  });
}
