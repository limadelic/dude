import { chromium } from "playwright";
import { createInterface } from "readline";
import { stat } from "fs/promises";

async function open() {
  const browser = await chromium.launch({ headless: true });
  return browser;
}

async function record(browser) {
  const ctx = await browser.newContext({
    recordVideo: { dir: "/tmp" },
  });
  return ctx;
}

async function join(page) {
  const url = "http://127.0.0.1:8080/#auto-join=%23the-lab";
  await page.goto(url);
}

async function guest(page) {
  await page.click('button:has-text("Guest")');
}

async function nick(page) {
  const input = page.locator('input[placeholder="your_nick"]');
  await input.fill("watcher");
  await input.press("Enter");
}

async function ready(page) {
  await page.waitForSelector('[data-testid="compose-input"]', {
    timeout: 10000,
  });

  const header = page.locator('header');
  await header.waitFor({ timeout: 5000 });

  const channelName = await page.locator('header').textContent();
  if (!channelName.includes("#the-lab")) {
    throw new Error("Not in #the-lab channel");
  }

  const messageList = page.locator('[data-testid="message-list"]');
  await messageList.waitFor({ timeout: 5000 });
}

function listen() {
  return new Promise((resolve) => {
    const rl = createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: false,
    });

    rl.on("line", (line) => {
      if (line === "stop") {
        rl.close();
        resolve();
      }
    });

    rl.on("close", () => {
      resolve();
    });
  });
}

async function baseline(page) {
  const msgs = page.locator('[data-testid="message-list"] [id^="msg-"]');
  return await msgs.count();
}

async function messages(page) {
  try {
    const msgs = page.locator('[data-testid="message-list"] [id^="msg-"]');
    const count = await msgs.count();
    const lines = [];

    for (let i = 0; i < count; i++) {
      try {
        const text = await msgs.nth(i).textContent({ timeout: 1000 });
        lines.push(text);
      } catch (e) {
        break;
      }
    }

    return lines;
  } catch (e) {
    return [];
  }
}

async function main() {
  let browser;
  let ctx;
  let page;
  let start = 0;

  try {
    browser = await open();
    ctx = await record(browser);
    page = await ctx.newPage();

    await join(page);
    await guest(page);
    await nick(page);
    await ready(page);

    start = await baseline(page);
    console.log("ready");

    await listen();

    const all = await messages(page);
    const newMessages = all.slice(start);
    const count = newMessages.length;

    let greet = null;
    for (const msg of newMessages) {
      if (msg.includes("brian") && msg.includes("greet")) {
        greet = msg;
        break;
      }
    }

    if (!greet) {
      for (const msg of all) {
        if (msg.includes("brian") && msg.includes("greet")) {
          greet = msg;
          break;
        }
      }
    }

    if (greet) {
      console.log(`saw ${count} ${greet}`);
    } else {
      console.log(`saw ${count} none`);
    }
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  } finally {
    if (ctx) {
      await ctx.close();
      const videoPath = await ctx.video?.path();
      if (videoPath) {
        const info = await stat(videoPath);
        console.log(`video ${videoPath} ${info.size}`);
      }
    }
    if (browser) await browser.close();
  }
}

process.stdout.on("error", (err) => {
  if (err.code !== "EPIPE") {
    console.error("stdout error:", err);
  }
});

main();
