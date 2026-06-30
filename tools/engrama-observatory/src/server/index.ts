import fs from "node:fs/promises";
import path from "node:path";

import express from "express";
import { createServer as createViteServer } from "vite";

import { resolveRepoRoot } from "./repo.js";
import { createApiRouter } from "./routes.js";

const observatoryRoot = process.cwd();
const repoRoot = resolveRepoRoot(process.env.ENGRAMA_REPO_ROOT);
const port = Number(process.env.PORT || "4177");
const isProduction = process.env.NODE_ENV === "production";

async function start() {
  const app = express();

  app.use(express.json());
  app.use("/api", createApiRouter(repoRoot));

  if (!isProduction) {
    const vite = await createViteServer({
      root: observatoryRoot,
      server: { middlewareMode: true },
      appType: "spa",
    });

    app.use(vite.middlewares);
    app.use("*", async (request, response, next) => {
      try {
        const templatePath = path.resolve(observatoryRoot, "index.html");
        const template = await fs.readFile(templatePath, "utf8");
        const html = await vite.transformIndexHtml(request.originalUrl, template);
        response.status(200).set({ "Content-Type": "text/html" }).end(html);
      } catch (error) {
        next(error);
      }
    });
  } else {
    const clientRoot = path.resolve(observatoryRoot, "dist/client");
    app.use(express.static(clientRoot));
    app.get("*", (_request, response) => {
      response.sendFile(path.resolve(clientRoot, "index.html"));
    });
  }

  app.listen(port, () => {
    console.log(
      `Engrama Observatory listening on http://localhost:${port} (repo: ${repoRoot})`,
    );
  });
}

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
