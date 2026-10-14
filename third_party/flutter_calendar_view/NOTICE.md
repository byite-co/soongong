# flutter_calendar_view reference

Source: https://github.com/SimformSolutionsPvtLtd/flutter_calendar_view/blob/0cc89e4cf9b26d6154bb149c9e11f3a3dd360b55/lib/src/event_arrangers/side_event_arranger.dart

Copyright (c) 2021 Simform Solutions. MIT license is retained alongside this file.

`lib/features/timetable/domain/overlap_layout.dart` adapts the side-by-side
overlap-group / reusable-column layout approach. It uses an iterative sweep
instead of the upstream recursive longest-event extraction, preserves input
identity, and groups the actual minimum-height rectangles used by SoonGong.
No upstream widgets, event model, persistence or theme are imported.
