# EXT-03 · On-device gaze observation

Applied after EXT-01 and EXT-02 to PR #9; main remains unchanged.

- MediaPipe Tasks Vision 1.1.0, Android Maven exact version; iOS SPM pinned to `d652c28b7e27d04d49dda53dd359a98b881848ec`.
- Real native bridges consume camera NV21/BGRA frames, rotate to upright, return landmarks from one face only. No network or file output. Serial inference, Dart maximum 5 Hz / one in flight, explicit run IDs fence late replies.
- Independent Dart One Euro equations smooth eye-region coordinates. Fifteen stable observations calibrate a reference direction. Lost/closed/ambiguous eyes remain unknown. This is an experimental direction signal, **not a validated concentration classifier**.
- Dev menu → 시선 관측 실험. Explicit consent, permission, stop and background handling. Cannot run alongside a live measurement. Raw frames/coordinates/calibration are not persisted. SeatEngine/SeatHysteresis and time accounting are unchanged.
- `python3 tool/fetch_gaze_model.py` before Flutter commands downloads the official 3.76 MB asset and checks SHA-256. No model download occurs in the app. The generated model is ignored by git, SDK/source/model notices are bundled.

## PRINCIPLE-CONFLICT / boundaries

The user's explicit gaze request permits this isolated dev experiment despite the original face-presence-only principle. General users are not assigned focus scores; enabling time-accounting changes requires a separate decision and validation.

Native CI compiles Android/iOS. Physical camera orientation, glasses, lighting, head movement, paper/phone positions, thermal load, frame latency and battery impact still require device evidence before product exposure. A calibrated eye-region signal is not a screen gaze point or mental-state measurement.

Official sources: https://github.com/google-ai-edge/mediapipe ; https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker ; https://github.com/casiez/OneEuroFilter .

Model licensing: the official BlazeFace (Short Range), FaceMesh V2 and Blendshape V2 model cards each state Apache-2.0. SDK license is from the pinned repository. OneEuroFilter reference license is `python/LICENSE` (BSD-3-Clause, Copyright 2023 Inria), retained even though the equations were independently implemented. SDK/model copyright belongs to Google and respective contributors.
