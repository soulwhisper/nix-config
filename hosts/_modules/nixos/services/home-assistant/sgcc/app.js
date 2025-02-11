module.exports = {
    apps : [{
      name   : "hass-sgcc",
      script : "./state-grid.js",
      watch: true,
      instances: 1,
      cron_restart: '0 1 * * *',
      env: {
        "WSGW_USERNAME": "$PHONE_NUMBER",
        "WSGW_PASSWORD": "$PASSWORD",
        "WSGW_RECENT_ELC_FEE": "true",
        "WSGW_mqtt_host": "localhost",
        "WSGW_mqtt_port": "1883",
        "WSGW_mqtt_username": "",
        "WSGW_mqtt_password": "",
      }
    }]
  }