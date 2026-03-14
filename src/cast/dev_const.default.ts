// Development constants for Cast - Replace with your own values
// This file is a template. Copy to dev_const.ts and modify for your environment

export const CAST_DEV_APP_ID = "5FE44367";

// Chromecast SDK will only load on localhost and HTTPS
// So during local development we have to send our dev IP address,
// but then run the UI on localhost.
export const CAST_DEV_HASS_URL = "http://192.168.1.234:8123";
