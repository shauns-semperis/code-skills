export function truncate(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }
  return value.slice(0, maxLength - 1) + "…";
}

/**
 * Collapses runs of whitespace to a single space and trims both ends.
 * Non-breaking spaces count as whitespace.
 */
export function normalizeWhitespace(value: string): string {
  return value.replace(/[\s ]+/g, " ").trim();
}
