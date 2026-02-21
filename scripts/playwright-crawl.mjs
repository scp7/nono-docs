#!/usr/bin/env node
import { chromium } from "playwright";

const baseUrl = process.env.BASE_URL || "http://localhost:3000";
const maxPages = Number(process.env.MAX_PAGES || 500);

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();

const queue = [baseUrl];
const seen = new Set();
const failures = [];

while (queue.length > 0 && seen.size < maxPages) {
  const url = queue.shift();
  if (!url || seen.has(url)) continue;
  seen.add(url);

  try {
    const response = await page.goto(url, {
      waitUntil: "domcontentloaded",
      timeout: 15000,
    });
    const status = response?.status() ?? 0;
    if (status >= 400 || status === 0) failures.push(`${status} ${url}`);

    const links = await page.$$eval("a[href]", (anchors) =>
      anchors
        .map((a) => a.getAttribute("href"))
        .filter((href) => typeof href === "string" && href.startsWith("/"))
    );

    for (const href of links) {
      const next = new URL(href, baseUrl).toString().split("#")[0];
      if (!seen.has(next)) queue.push(next);
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    failures.push(`ERR ${url} ${msg}`);
  }
}

await browser.close();

if (failures.length > 0) {
  console.error("Broken pages found:");
  for (const failure of failures) console.error(failure);
  process.exit(1);
}

console.log(`Crawl OK. Visited ${seen.size} pages.`);
