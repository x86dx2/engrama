import path from "node:path";

import { describe, expect, it } from "vitest";

import { assertSafeRepoPath, assertSafeWritePath } from "./repo";

describe("assertSafeRepoPath", () => {
  const repoRoot = "/tmp/engrama";

  it("allows declared read-only paths", () => {
    expect(
      assertSafeRepoPath(repoRoot, ".engrama/evidence/usage/usage-2026-06.jsonl"),
    ).toBe(path.resolve(repoRoot, ".engrama/evidence/usage/usage-2026-06.jsonl"));
  });

  it("blocks path traversal and env files", () => {
    expect(() => assertSafeRepoPath(repoRoot, "../secret.txt")).toThrow(
      /escapes repo root/i,
    );
    expect(() => assertSafeRepoPath(repoRoot, ".env")).toThrow(/forbidden/i);
  });

  it("allows only the write-safe destinations", () => {
    expect(
      assertSafeWritePath(repoRoot, ".engrama/evidence/config-backups/models-20260630.conf"),
    ).toBe(
      path.resolve(repoRoot, ".engrama/evidence/config-backups/models-20260630.conf"),
    );
    expect(() => assertSafeWritePath(repoRoot, "README.md")).toThrow(/allowlist/i);
  });
});
