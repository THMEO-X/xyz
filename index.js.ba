require('dotenv').config();
const { Client } = require('discord.js-selfbot-v13');
const farm = require('./FARM/farm');
const Keep_alive = require('./web/Keep_alive');
const sever = require('./web/browse/sever');
const chokidar = require('chokidar');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');
const pause  = require('./Commands/pause');
const resume = require('./Commands/resume');

Keep_alive();

const c = {
  red:     s => `\x1b[31m${s}\x1b[0m`,
  green:   s => `\x1b[32m${s}\x1b[0m`,
  yellow:  s => `\x1b[33m${s}\x1b[0m`,
  blue:    s => `\x1b[34m${s}\x1b[0m`,
  magenta: s => `\x1b[35m${s}\x1b[0m`,
  cyan:    s => `\x1b[36m${s}\x1b[0m`,
};

const activeClients = new Map();

function parseEnv(envPath) {
  if (!fs.existsSync(envPath)) return {};
  const raw = fs.readFileSync(envPath, 'utf8');
  const result = {};
  raw.split('\n').forEach(line => {
    const clean = line.replace(/\r/g, '').trim();
    if (!clean || clean.startsWith('#')) return;
    const idx = clean.indexOf('=');
    if (idx === -1) return;
    const key = clean.slice(0, idx).trim();
    const val = clean.slice(idx + 1).trim().replace(/^["']|["']$/g, '');
    result[key] = val;
  });
  return result;
}

function startClient(profileName, envPath) {
  if (activeClients.has(profileName)) {
    console.log(c.yellow(`[${profileName}] Already running, skipping.`));
    return;
  }

  // Đọc hết data NGAY LÚC NÀY — trước khi file có thể bị xóa/move
  const env = parseEnv(envPath);
  const token     = env.TOKEN || env.DISCORD_TOKEN || null;
  const channelId = env.CHANNEL || env.CHANNEL_ID || null;

  if (!token) {
    console.log(c.red(`[${profileName}] No TOKEN in ${envPath} — skipping.`));
    return;
  }
  if (!channelId) {
    console.log(c.red(`[${profileName}] No CHANNEL in ${envPath} — skipping.`));
    return;
  }

  console.log(c.blue(`\n📁 Profile: ${profileName} | Channel: ${channelId}`));
  console.log(c.green(`✅ Starting client for: ${profileName}`));

  const client = new Client({
    checkUpdate: false,
    readyStatus: false,
    selfbot: true,
  });

  client.once('ready', () => {
    console.log(c.green(`[${profileName}] ✅ Logged in as ${client.user.tag}`));
    activeClients.set(profileName, client);

    const state  = {};
    const idUser = client.user.id;

    client.on('messageCreate', msg => pause(client, msg, state, idUser));
    client.on('messageCreate', msg => resume(client, msg, state, idUser));

    farm(client, channelId, state); // ← string ID, không phải path
  });

  client.on('invalidated', () => {
    console.log(c.red(`[${profileName}] ⚠ Session invalidated — respawning in 5s...`));
    activeClients.delete(profileName);
    client.destroy();
    setTimeout(() => startClient(profileName, envPath), 5000);
  });

  client.on('error', err => {
    console.log(c.red(`[${profileName}] Error: ${err.message}`));
  });

  client.login(token).catch(err => {
    console.log(c.red(`[${profileName}] Login failed: ${err.message}`));
    activeClients.delete(profileName);
  });
}

function stopClient(profileName) {
  const client = activeClients.get(profileName);
  if (!client) return;
  console.log(c.yellow(`[${profileName}] Profile removed — destroying client.`));
  client.destroy();
  activeClients.delete(profileName);
}

function watchProfiles() {
  const profilesDir = path.resolve('./profiles');
  if (!fs.existsSync(profilesDir)) fs.mkdirSync(profilesDir, { recursive: true });

  console.log(c.magenta(`👁  Watching: ${profilesDir}`));

  const watcher = chokidar.watch(profilesDir, {
    persistent: true,
    ignoreInitial: false,
    depth: 2,
    awaitWriteFinish: {
      stabilityThreshold: 800,
      pollInterval: 100,
    },
  });

  watcher
    .on('add', filePath => {
      if (path.basename(filePath) !== '.env') return;
      const profileName = path.basename(path.dirname(filePath));
      if (profileName === path.basename(profilesDir)) return;
      console.log(c.cyan(`👁  [watcher] Detected .env → ${filePath}`));
      startClient(profileName, filePath);
    })
    .on('change', filePath => {
      if (path.basename(filePath) !== '.env') return;
      const profileName = path.basename(path.dirname(filePath));
      if (profileName === path.basename(profilesDir)) return;
      console.log(c.cyan(`🔄 [watcher] .env changed → restarting ${profileName}`));
      stopClient(profileName);
      setTimeout(() => startClient(profileName, filePath), 2000);
    })
    .on('unlink', filePath => {
      if (path.basename(filePath) !== '.env') return;
      const profileName = path.basename(path.dirname(filePath));
      stopClient(profileName);
    });
}

function startRootClient() {
  const token     = process.env.HTOKEN;
  const channelId = process.env.CHANNEL || process.env.CHANNEL_ID;

  if (!token) {
    console.log(c.red('❌ No TOKEN in .env — nothing to start.'));
    return;
  }
  if (!channelId) {
    console.log(c.red('❌ No CHANNEL in .env — nothing to start.'));
    return;
  }

  console.log(c.yellow('⚡ Starting root client...'));

  const client = new Client({
    checkUpdate: false,
    readyStatus: false,
    selfbot: true,
  });

  client.once('ready', () => {
    console.log(c.green(`✅ Root ready: ${client.user.tag}`));

    const state  = {};
    const idUser = client.user.id;

    client.on('messageCreate', msg => pause(client, msg, state, idUser));
    client.on('messageCreate', msg => resume(client, msg, state, idUser));

    farm(client, channelId, state);
  });

  client.on('invalidated', () => {
    console.log(c.red('Root invalidated — reconnecting in 5s...'));
    setTimeout(() => client.login(token), 5000);
  });

  client.on('error', err => {
    console.log(c.red(`Root error: ${err.message}`));
  });

  client.login(token).catch(err => {
    console.log(c.red(`Root login failed: ${err.message}`));
  });
}

// ─── Boot ─────────────────────────────────────────────────────────────────────
startRootClient();
watchProfiles();