/** Normalized key for case-insensitive dedupe of category/subcategory names. */
export function normalizeEntityNameKey(name: string): string {
  return name.trim().replace(/\s+/g, ' ').toLowerCase();
}
