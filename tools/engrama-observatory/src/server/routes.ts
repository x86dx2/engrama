import express from "express";

import {
  loadModelsConfig,
  saveModelsConfig,
  validateModelsConfig,
} from "./config.js";
import { loadUsageSummary, loadConfigEvents } from "./usage.js";

export function createApiRouter(repoRoot: string) {
  const router = express.Router();

  router.get("/health", (_request, response) => {
    response.json({ ok: true });
  });

  router.get("/usage", async (request, response) => {
    try {
      const summary = await loadUsageSummary(
        repoRoot,
        typeof request.query.month === "string" ? request.query.month : undefined,
      );
      response.json({
        month: summary.month,
        runs: summary.runs,
        invalidLines: summary.invalidLines,
        warnings: summary.warnings,
      });
    } catch (error) {
      response.status(400).json({ error: (error as Error).message });
    }
  });

  router.get("/usage/summary", async (request, response) => {
    try {
      const summary = await loadUsageSummary(
        repoRoot,
        typeof request.query.month === "string" ? request.query.month : undefined,
      );
      response.json(summary);
    } catch (error) {
      response.status(400).json({ error: (error as Error).message });
    }
  });

  router.get("/models", async (_request, response) => {
    try {
      response.json(await loadModelsConfig(repoRoot));
    } catch (error) {
      response.status(400).json({ error: (error as Error).message });
    }
  });

  router.post("/models/validate", async (request, response) => {
    try {
      response.json(await validateModelsConfig(repoRoot, request.body));
    } catch (error) {
      response.status(400).json({ error: (error as Error).message });
    }
  });

  router.post("/models/save", async (request, response) => {
    try {
      response.json(await saveModelsConfig(repoRoot, request.body));
    } catch (error) {
      response.status(400).json({ error: (error as Error).message });
    }
  });

  router.get("/config-events", async (request, response) => {
    try {
      response.json(
        await loadConfigEvents(
          repoRoot,
          typeof request.query.month === "string" ? request.query.month : undefined,
        ),
      );
    } catch (error) {
      response.status(400).json({ error: (error as Error).message });
    }
  });

  return router;
}
