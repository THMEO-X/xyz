const fs = require('fs');
const path = require('path');
const startCaptchaDetector = require('../untils/captcha');
const pauseCmd = require('../Commands/pause');
const resumeCmd = require('../Commands/resume');
const startStatsCommand = require('../untils/webhock');
const startRPC = require('../untils/rpc');

const randomChoice = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomDelay = (min, max) => Math.floor(Math.random() * (max - min) + min);
const delay = (ms) => new Promise((res) => setTimeout(res, ms));

const timestamp = () => {
  const now = new Date();
  const hh = now.getHours().toString().padStart(2, '0');
  const mm = now.getMinutes().toString().padStart(2, '0');
  const ss = now.getSeconds().toString().padStart(2, '0');
  return `${hh}:${mm}:${ss}`;
};

module.exports = async function farm(client, channelId, state) {
  const channel = client.channels.cache.get(channelId);

  if (!channel) {
    console.log(`❌ Không tìm thấy kênh — kiểm tra CHANNEL_ID`);
    return;
  }

  const tag = channel.name;
  const stats = { hunt: 0, battle: 0 };

  const global = state;
  if (global.paused      === undefined) global.paused      = false;
  if (global.captcha     === undefined) global.captcha     = false;
  if (global.gemChecking === undefined) global.gemChecking = false;
  if (global.hunt        === undefined) global.hunt        = false;
  if (global.battle      === undefined) global.battle      = false;

  // ─── Auto Pause ───────────────────────────────────────────────
  function startAutoPause() {
    const runTime   = randomDelay(15 * 60 * 1000, 30 * 60 * 1000);
    const pauseTime = randomDelay( 5 * 60 * 1000,  7 * 60 * 1000);

    console.log(`[${tag}] ⏱️ Auto pause sau ${(runTime / 60000).toFixed(1)} phút`);

    setTimeout(() => {
      global.paused = true;
      console.log(`[${tag}] ⏸️ Auto pause — nghỉ ${(pauseTime / 60000).toFixed(1)} phút`);

      setTimeout(() => {
        if (!global.captcha && !global.gemChecking) {
          global.paused = false;
          console.log(`[${tag}] ▶️ Auto resume — farm tiếp`);
        } else {
          console.log(`[${tag}] ⚠️ Resume bị hold — captcha/gem active`);
        }
        startAutoPause();
      }, pauseTime);
    }, runTime);
  }

  // ─── Blocked Check ────────────────────────────────────────────
  function isBlocked() {
    return global.paused || global.captcha || global.gemChecking;
  }

  // ─── Hunt ─────────────────────────────────────────────────────
  async function hunt() {
    const interval    = randomDelay(15000, 25000);
    const scheduledAt = Date.now();

    if (isBlocked() || global.battle) {
      console.log(`[${tag}] ⏭️ Hunt skip — blocked/battle active`);
      setTimeout(hunt, interval);
      return;
    }

    global.hunt = true;
    try {
      channel.sendTyping();
      if (global.battle) await delay(1500);

      if (isBlocked()) {
        console.log(`[${tag}] ⏭️ Hunt abort — paused trong delay`);
        return;
      }

      await channel.send(
        `${randomChoice(["owo", "owo"])} ${randomChoice(["h", "hunt"])}`
      );
      stats.hunt++;
      console.log(`[${tag}] 🏹 Hunt #${stats.hunt} — ${timestamp()}`);

      sendPhrase();
    } catch (err) {
      console.log(`[${tag}] ❌ Hunt lỗi: ${err.message}`);
    } finally {
      global.hunt = false;
      const elapsed = Date.now() - scheduledAt;
      const next    = Math.max(0, interval - elapsed);
      console.log(`[${tag}] ⏱️ Hunt tiếp theo sau ${(next / 1000).toFixed(1)}s`);
      setTimeout(hunt, next);
    }
  }

  // ─── Battle ───────────────────────────────────────────────────
  async function battle() {
    const interval    = randomDelay(15000, 25000);
    const scheduledAt = Date.now();

    if (isBlocked() || global.hunt) {
      console.log(`[${tag}] ⏭️ Battle skip — blocked/hunt active`);
      setTimeout(battle, interval);
      return;
    }

    global.battle = true;
    try {
      channel.sendTyping();
      if (global.hunt) await delay(1500);

      if (isBlocked()) {
        console.log(`[${tag}] ⏭️ Battle abort — paused trong delay`);
        return;
      }

      await channel.send(
        `${randomChoice(["owo", "owo"])} ${randomChoice(["b", "battle"])}`
      );
      stats.battle++;
      console.log(`[${tag}] ⚔️ Battle #${stats.battle} — ${timestamp()}`);
    } catch (err) {
      console.log(`[${tag}] ❌ Battle lỗi: ${err.message}`);
    } finally {
      global.battle = false;
      const elapsed = Date.now() - scheduledAt;
      const next    = Math.max(0, interval - elapsed);
      console.log(`[${tag}] ⏱️ Battle tiếp theo sau ${(next / 1000).toFixed(1)}s`);
      setTimeout(battle, next);
    }
  }

  // ─── Phrase ───────────────────────────────────────────────────
  async function sendPhrase() {
    if (global.paused || global.captcha) {
      console.log(`[${tag}] ⏭️ Phrase skip — paused/captcha`);
      return;
    }

    try {
      const data = fs.readFileSync(
        path.join(__dirname, '../textmess/text.json'), 'utf8'
      );
      const { phrases } = JSON.parse(data);

      if (!phrases?.length) {
        console.log(`[${tag}] ❌ Phrases trống`);
        return;
      }

      const phrase = randomChoice(phrases);
      channel.sendTyping();
      await delay(randomDelay(800, 1500));

      if (global.paused || global.captcha) {
        console.log(`[${tag}] ⏭️ Phrase skip — flag đổi trong delay`);
        return;
      }

      await channel.send(phrase);
      console.log(`[${tag}] 💬 Phrase: "${phrase}" — ${timestamp()}`);
    } catch (err) {
      console.log(`[${tag}] ❌ Phrase lỗi: ${err.message}`);
    }
  }

  // ─── Boot ─────────────────────────────────────────────────────
  console.log(`[${tag}] ✅ Farm bắt đầu: ${channel.name}`);

  global.restartLoops = () => {
    hunt();
    setTimeout(battle, 2000);
  };

  startCaptchaDetector(client, channelId, client.user.id, global);
  startAutoPause();
  startStatsCommand(client, stats);
  startRPC(client);

  hunt();
  await delay(2000);
  battle();
};