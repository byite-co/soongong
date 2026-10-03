// Logger for the signup path (age-check · issue-pass · complete-signup):
// only request ids and outcome codes. Any string that looks like an email, a
// date of birth or a JWT is masked before it can reach the log sink.
const EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
const DATE = /\b\d{4}-\d{2}-\d{2}\b/g;
const JWT = /\b[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b/g;
const SUB = /\b(sub|subject|provider_id|birth_date|email)\b["']?\s*[:=]\s*["']?[^",\s}]+/gi;

export function redact(text: string): string {
  return text
    .replace(JWT, "[jwt]")
    .replace(EMAIL, "[email]")
    .replace(DATE, "[date]")
    .replace(SUB, (m) => m.split(/[:=]/)[0] + "=[redacted]");
}

export interface Logger {
  info(msg: string): void;
  warn(msg: string): void;
  error(msg: string): void;
}

export function logger(requestId: string, sink: (line: string) => void = console.log): Logger {
  const line = (level: string, msg: string) => sink(redact(`[${requestId}] ${level} ${msg}`));
  return {
    info: (m) => line("info", m),
    warn: (m) => line("warn", m),
    error: (m) => line("error", m),
  };
}
