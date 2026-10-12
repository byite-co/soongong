// Include the adapted layout's MIT notice in distributed applications, even
// though calendar_view is not installed as a Flutter package.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

void registerThirdPartyLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const ['MediaPipe Tasks Vision; BlazeFace, FaceMesh V2, Blendshape V2 models'],
      await rootBundle.loadString('assets/licenses/MediaPipe-Apache-2.0.txt'));
    yield LicenseEntryWithLineBreaks(const ['One Euro Filter (algorithm reference; independent implementation)'],
      await rootBundle.loadString('assets/licenses/OneEuroFilter-BSD-3-Clause.txt'));
    yield LicenseEntryWithLineBreaks(const ['SQLite3MultipleCiphers'],
      await rootBundle.loadString('assets/licenses/SQLite3MultipleCiphers-MIT.txt'));
    yield const LicenseEntryWithLineBreaks(
      <String>['flutter_calendar_view (adapted layout)'],
      _calendarViewLicense,
    );
  });
}

const _calendarViewLicense = r'''MIT License

Copyright (c) 2021 Simform Solutions

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';
