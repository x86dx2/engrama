const SECRET_PATTERNS = [
  /\bsk-[A-Za-z0-9_-]{8,}\b/g,
  /\b(?:api[_-]?key|token|secret|password)\b\s*[:=]\s*([A-Za-z0-9/_+=.-]{6,})/gi,
];

function maskToken(value: string): string {
  if (value.length <= 8) {
    return "****";
  }

  return `${value.slice(0, 4)}****${value.slice(-4)}`;
}

export function maskSecrets(value: string): string {
  let masked = value;

  masked = masked.replace(SECRET_PATTERNS[0], (match) => maskToken(match));
  masked = masked.replace(SECRET_PATTERNS[1], (match, token) =>
    match.replace(token, maskToken(token)),
  );

  return masked;
}
