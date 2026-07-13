// untils/daily.js
const schedule = require('node-cron');

module.exports = function startDailyTimer(client, channelId) {
  console.log('⏰ Daily timer khởi động — gửi lúc 15:00 VN mỗi ngày');

  // Múi giờ Việt Nam = UTC+7 → 15:00 VN = 08:00 UTC
  // Cron: giây phút giờ ngày tháng thứ
  schedule.schedule('0 0 8 * * *', async () => {
    const channel = client.channels.cache.get(channelId);
    if (!channel) {
      console.log('❌ Daily timer: không tìm thấy channel');
      return;
    }

    try {
      await channel.send('owo daily');
      console.log(`⏰ Daily gửi lúc 15:00 VN — ${new Date().toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })}`);
    } catch (err) {
      console.log(`❌ Daily timer lỗi: ${err.message}`);
    }
  }, {
    timezone: 'Asia/Ho_Chi_Minh'
  });
};