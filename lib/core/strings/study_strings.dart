abstract final class StudyStrings {
  static const bodyNotCached = '본문을 아직 내려받지 못했습니다. 저장된 기록이 삭제된 것은 아닙니다.';
  static const bodyLoading = '본문을 불러오는 중입니다.';
  static const solveTitle = '수학 풀이';
  static const solve = '풀이 요청';
  static const solveHint =
      '수학 문제의 풀이 후보입니다. 조건과 풀이를 직접 확인하세요. 도형 정보가 없는 문제는 지원이 제한됩니다.';
  static const reference = '대조할 정답 (선택 · 정수/분수/소수)';
  static const solveConsent = '확정한 문제 텍스트를 풀이 서버에 전송하는 데 동의합니다.';
  static const verified = '요청할 때 제공한 정답과 답의 수치가 일치합니다. 해설 전체가 검증된 것은 아닙니다.';
  static const contradicted = '입력한 정답과 답이 다릅니다.';
  static const inconclusive = '정답 확인이 완료되지 않았습니다.';
  static const unsupported = '이 문제 또는 정답 형식은 검증 범위 밖입니다.';
  static const saveSolution = '확인한 풀이 저장';
  static const title = '손글씨 인식';
  static const inputSupport =
      '한 번에 사진 1장을 선택합니다. 한글과 수식의 손글씨 인식 정확도는 아직 검증 중이므로 원본과 대조해 교정하세요.';
  static const mathSource =
      '수식은 LaTeX 원문으로 표시합니다. 조판된 수식 미리보기와 수학적 검증은 지원하지 않습니다.';
  static const gradingSupport =
      '한 번에 사진 1장에서 문항 번호와 빨간 동그라미·가위표·세모 후보를 읽습니다. 판독 정확도는 아직 검증 중입니다. 찍음·안 품은 직접 지정하고 모든 표시를 원본과 대조해 확정하세요. 기존 판독 횟수를 사용하며 AI 포인트는 차감하지 않습니다.';
  static const select = '사진 선택';
  static const camera = '사진 촬영';
  static const interruptedPicker =
      '중단된 사진 선택은 자동으로 복원하거나 전송하지 않습니다. 임시 파일 정리 후 사진을 다시 선택해 주세요.';
  static const text = '한글·문장';
  static const math = '수식';
  static const recognize = '텍스트 인식';
  static const confirm = '교정한 내용 저장';
  static const consent =
      '선택한 사진을 텍스트 인식 서버에 전송합니다. 사진은 처리 중 메모리에서만 사용하며 서버에 저장하지 않습니다. 인식한 내용은 직접 확인한 뒤 저장하세요.';
  static const agree = '이번 사진의 전송에 동의합니다';
  static const readingConsent = '설정에서 판독 데이터 전송 동의도 활성화해 주세요.';
  static const unavailable = '텍스트 인식 서버가 아직 연결되지 않았습니다.';
  static const error = '처리하지 못했습니다. 입력은 유지됩니다. 다시 시도해 주세요.';
  static const cacheCleanupFailed =
      '사진 임시 파일을 정리하지 못했습니다. 다시 시도하기 전에 앱의 임시 저장공간을 확인해주세요.';
  static const tooLarge = '사진은 4MiB 이하로 선택해 주세요.';
  static const review = '사진과 대조해 인식된 내용을 교정해 주세요.';
  static const saved = '이 기기에 저장되었습니다.';
  static const localOnly = '확정한 텍스트는 이 기기에 저장됩니다. 기기 간 동기화는 아직 지원하지 않습니다.';
  static const history = '저장한 텍스트';
  static const delete = '삭제';
  static const deletePrompt = '저장한 텍스트와 연결된 풀이를 이 기기에서 삭제할까요?';
  static const cancel = '취소';
}
