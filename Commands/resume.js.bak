const { setPaused } = require('../FARM/farm');

module.exports = async (client, message, state, idUser, channel) => {
  if (message.author.id !== idUser) return;
  if (message.content !== "TT") return;
  if (!state.paused && !state.captcha) {
    console.log("▶️ Bot đang chạy rồi");
    return;
  }

  setPaused(false); // flag clear, không killNow()
  state.captcha = false;
  await message.edit("RESUME");
  console.log("▶️ Resume — loop restart");

  const farm = require('../FARM/farm');
  farm.restartLoops(client, channel);
};