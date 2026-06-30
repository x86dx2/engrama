import path from "node:path";

const ALLOWED_READ_PATHS = [
  ".engrama/evidence/usage",
  ".engrama/evidence/config-events",
  ".engrama/engine/config/models.conf",
  ".engrama/engine/config/subscriptions.conf",
  ".engrama/engine/config/prices.conf",
] as const;

const ALLOWED_WRITE_PATHS = [
  ".engrama/engine/config/models.conf",
  ".engrama/evidence/config-backups",
  ".engrama/evidence/config-events",
] as const;

export function resolveRepoRoot(explicitRoot?: string): string {
  const candidate = explicitRoot
    ? path.resolve(explicitRoot)
    : path.resolve(process.cwd(), "..", "..");

  return candidate;
}

function assertSafePath(
  repoRoot: string,
  relativePath: string,
  allowlist: readonly string[],
  scope: "read-only" | "write",
): string {
  if (relativePath.includes(".env")) {
    throw new Error("Access to .env is forbidden");
  }

  const absolutePath = path.resolve(repoRoot, relativePath);
  const normalizedRoot = `${path.resolve(repoRoot)}${path.sep}`;
  const normalizedPath = path.resolve(absolutePath);

  if (!normalizedPath.startsWith(normalizedRoot)) {
    throw new Error(`Path escapes repo root: ${relativePath}`);
  }

  const isAllowed = allowlist.some((allowed) => {
    const absoluteAllowed = path.resolve(repoRoot, allowed);
    return (
      normalizedPath === absoluteAllowed ||
      normalizedPath.startsWith(`${absoluteAllowed}${path.sep}`)
    );
  });

  if (!isAllowed) {
    throw new Error(`Path is outside the ${scope} allowlist: ${relativePath}`);
  }

  return absolutePath;
}

export function assertSafeRepoPath(repoRoot: string, relativePath: string): string {
  return assertSafePath(repoRoot, relativePath, ALLOWED_READ_PATHS, "read-only");
}

export function assertSafeWritePath(repoRoot: string, relativePath: string): string {
  return assertSafePath(repoRoot, relativePath, ALLOWED_WRITE_PATHS, "write");
}
