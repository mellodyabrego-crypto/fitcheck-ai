// Her Style Co. — Firebase Cloud Messaging service worker.
//
// Required by FCM web for background pushes. Once Firebase config is filled
// in below (or injected at deploy time) this worker handles notifications
// while the app tab is closed/backgrounded.
//
// To activate:
//   1. Create a Firebase project at console.firebase.google.com
//   2. Project settings → Your apps → Web → register app, copy config
//   3. Replace the placeholders in `firebaseConfig` below (or run a build
//      script that substitutes them from FIREBASE_* env vars)
//   4. Cloud Messaging → Web Push certificates → Generate key pair → use as
//      FIREBASE_VAPID_KEY in Flutter dart-defines

importScripts(
  "https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js",
);

// PLACEHOLDER — replace at deploy time. The service worker file is fetched
// directly by the browser, so dart-define values do NOT reach it. Substitute
// these values via the build pipeline (or commit them — they're not secrets,
// just identifiers).
const firebaseConfig = {
  apiKey: "REPLACE_FIREBASE_API_KEY",
  authDomain: "REPLACE_FIREBASE_AUTH_DOMAIN",
  projectId: "REPLACE_FIREBASE_PROJECT_ID",
  storageBucket: "REPLACE_FIREBASE_STORAGE_BUCKET",
  messagingSenderId: "REPLACE_FIREBASE_MESSAGING_SENDER_ID",
  appId: "REPLACE_FIREBASE_APP_ID",
};

// If config is still placeholder, no-op so the worker doesn't crash.
const isConfigured = !Object.values(firebaseConfig).some((v) =>
  typeof v === "string" && v.startsWith("REPLACE_")
);

if (isConfigured) {
  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const notif = payload.notification || {};
    self.registration.showNotification(
      notif.title || "Today’s look is ready",
      {
        body: notif.body ||
          "Open Her Style Co. for an outfit picked for today’s weather.",
        icon: "/icons/Icon-192.png",
        badge: "/icons/Icon-192.png",
        data: payload.data || {},
      },
    );
  });
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.link) ||
    "/";
  event.waitUntil(clients.openWindow(url));
});
