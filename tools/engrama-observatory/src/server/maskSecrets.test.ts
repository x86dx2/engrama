import { describe, expect, it } from "vitest";

import { maskSecrets } from "./maskSecrets";

describe("maskSecrets", () => {
  it("masks suspicious token-looking substrings", () => {
    expect(maskSecrets("token=super-secret-value")).toContain("supe****alue");
    expect(maskSecrets("sk-abcdefghijklmnopqrstuvwxyz")).toContain("sk-a****wxyz");
  });
});
