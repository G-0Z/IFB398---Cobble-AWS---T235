// Serves the deck (viewer.html) behind a username and password, for sharing over a tunnel.
// Logins come from USER_<NAME>=<password> lines in .env next to this file (git-ignored).
const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT = __dirname;
const envFile = path.join(ROOT, ".env");
const env = Object.fromEntries(
  (fs.existsSync(envFile) ? fs.readFileSync(envFile, "utf8") : "")
    .split(/\r?\n/)
    .map((line) => line.match(/^\s*([A-Z_]+)\s*=\s*(.*?)\s*$/))
    .filter(Boolean)
    .map((m) => [m[1], m[2]]),
);
// One login per person: a line USER_<NAME>=<password> signs in as <name>.
const accounts = new Map(
  Object.entries(env)
    .filter(([key, pass]) => key.startsWith("USER_") && pass)
    .map(([key, pass]) => [key.slice(5).toLowerCase(), pass]),
);
const PORT = Number(process.env.PORT || env.PORT || 8080);
if (accounts.size === 0) {
  console.error("Add a login to .env first, for example USER_MAX=some-password");
  process.exit(1);
}

// Only the file types the deck needs; never dotfiles such as .env.
const TYPES = { ".html": "text/html; charset=utf-8", ".png": "image/png", ".css": "text/css" };
const same = (a, b) => {
  const x = Buffer.from(a), y = Buffer.from(b);
  return x.length === y.length && crypto.timingSafeEqual(x, y);
};

// Shared slide position: anyone signed in can move it, and every open viewer follows.
let current = 0;
const viewers = new Set();
const broadcast = () => viewers.forEach((v) => v.write(`data: ${current}\n\n`));
setInterval(() => viewers.forEach((v) => v.write(": ping\n\n")), 25000); // keeps tunnels from dropping idle streams

http
  .createServer((req, res) => {
    const [scheme, token] = (req.headers.authorization || "").split(" ");
    const [user, ...rest] = scheme === "Basic" ? Buffer.from(token || "", "base64").toString().split(":") : [];
    const expected = accounts.get((user || "").toLowerCase());
    if (!expected || !same(rest.join(":"), expected)) {
      res.writeHead(401, { "WWW-Authenticate": 'Basic realm="Cobble deck", charset="UTF-8"' });
      return res.end("Sign in required");
    }
    if (req.url === "/events") {
      res.writeHead(200, { "content-type": "text/event-stream", "cache-control": "no-store", connection: "keep-alive" });
      res.write(`data: ${current}\n\n`);
      viewers.add(res);
      return req.on("close", () => viewers.delete(res));
    }
    if (req.url === "/go" && req.method === "POST") {
      let body = "";
      req.on("data", (c) => (body = (body + c).slice(0, 16)));
      return req.on("end", () => {
        const n = Number.parseInt(body, 10);
        if (Number.isInteger(n) && n >= 0 && n < 1000) {
          current = n;
          broadcast();
        }
        res.writeHead(204);
        res.end();
      });
    }
    let rel;
    try {
      rel = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
    } catch {
      res.writeHead(400);
      return res.end();
    }
    if (rel === "/") rel = "/viewer.html";
    const file = path.join(ROOT, rel);
    const type = TYPES[path.extname(file)];
    if (!file.startsWith(ROOT + path.sep) || !type || rel.split("/").some((part) => part.startsWith("."))) {
      res.writeHead(404);
      return res.end();
    }
    fs.readFile(file, (err, data) => {
      if (err) {
        res.writeHead(404);
        return res.end();
      }
      res.writeHead(200, { "content-type": type, "cache-control": "no-store" });
      res.end(data);
    });
  })
  .on("error", (err) => {
    if (err.code !== "EADDRINUSE") throw err;
    console.error(`Port ${PORT} is already in use: another copy is running. Stop it, or set PORT=8081 in .env.`);
    process.exit(1);
  })
  .listen(PORT, () => console.log(`Deck at http://localhost:${PORT}. Logins: ${[...accounts.keys()].join(", ")} (passwords in .env)`));
