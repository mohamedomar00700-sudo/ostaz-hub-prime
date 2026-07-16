const SUPABASE_URL = "https://vfpqlsnnxymaoqnmbqll.supabase.co";
const SUPABASE_KEY = "sb_publishable_3n0_3uOvKUcdZXV9dlk38w_ILaphEZx";

self.addEventListener('install', function(event) {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', function(event) {
  let title = 'أستاذ أونلاين';
  let body = 'تنبيه جديد من لوحة الإشراف';
  
  if (event.data) {
    try {
      const data = event.data.json();
      title = data.title || title;
      body = data.body || body;
      event.waitUntil(
        self.registration.showNotification(title, {
          body: body,
          icon: './logo.jpeg',
          badge: './logo.jpeg',
          dir: 'rtl'
        })
      );
      return;
    } catch (e) {
      // Fallback to fetch if data is not JSON
      try {
        const text = event.data.text();
        if (text) body = text;
      } catch (err) {}
    }
  }
  
  // Tickle-and-query: Fetch latest notification from Supabase
  const fetchPromise = fetch(`${SUPABASE_URL}/rest/v1/custom_notifications?select=*&order=created_at.desc&limit=1`, {
    headers: {
      'apikey': SUPABASE_KEY,
      'Authorization': `Bearer ${SUPABASE_KEY}`
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data && data.length > 0) {
      title = data[0].title || title;
      body = data[0].message || body;
    }
    return self.registration.showNotification(title, {
      body: body,
      icon: './logo.jpeg',
      badge: './logo.jpeg',
      dir: 'rtl'
    });
  })
  .catch(err => {
    console.error("Error fetching notification in sw:", err);
    return self.registration.showNotification(title, {
      body: body,
      icon: './logo.jpeg',
      badge: './logo.jpeg',
      dir: 'rtl'
    });
  });
  
  event.waitUntil(fetchPromise);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      if (clientList.length > 0) {
        return clientList[0].focus();
      }
      return self.clients.openWindow('./');
    })
  );
});
