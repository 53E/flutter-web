'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "fd546406b2173c19398f31e3cdb364ee",
"assets/AssetManifest.bin.json": "e51bd22a8c84076dc795a795d80f6eae",
"assets/AssetManifest.json": "fefcbe196b52060bc19b6ebd14916f3e",
"assets/assets/fonts/game_font.ttf": "4c8006c92a8a659e3cf92d89126e735b",
"assets/assets/images/characters/enemy/attack.png": "e129f4a3ed400d1295e183a0d7d13d56",
"assets/assets/images/characters/enemy/death.png": "875e2d8b6f1a13deb48cba0d78d62b14",
"assets/assets/images/characters/enemy/idle.png": "30984d9d19a620b689bea08e01f6cfbf",
"assets/assets/images/characters/enemy/setup_stage1.bat": "96f5fab902dd853cf24832aab18a3865",
"assets/assets/images/characters/enemy/stage1/attack.png": "e129f4a3ed400d1295e183a0d7d13d56",
"assets/assets/images/characters/enemy/stage1/death.png": "875e2d8b6f1a13deb48cba0d78d62b14",
"assets/assets/images/characters/enemy/stage1/idle.png": "30984d9d19a620b689bea08e01f6cfbf",
"assets/assets/images/characters/enemy/stage2/attack.png": "e978624a9bd9b2f4779bad496749c2bb",
"assets/assets/images/characters/enemy/stage2/death.png": "c950d7ad86d5545a7330b7301afbf0bd",
"assets/assets/images/characters/enemy/stage2/idle.png": "f1252c70adf8f4c72807e818359068f0",
"assets/assets/images/characters/enemy/stage3/attack.png": "28b8e36cc2dc0cfea34ba391e8cb05c6",
"assets/assets/images/characters/enemy/stage3/death.png": "875e2d8b6f1a13deb48cba0d78d62b14",
"assets/assets/images/characters/enemy/stage3/idle.png": "10a0b5a2c73ac83750b0abc687f5047c",
"assets/assets/images/characters/player/attack.png": "62b61d309c5c050824482741e1d6ffd1",
"assets/assets/images/characters/player/death.png": "a2fed8cf16398662471373ee09192258",
"assets/assets/images/characters/player/idle.png": "d82dca1f077e30093a826c32b2c791b7",
"assets/assets/sounds/bgm/game_battle.mp3": "24a629e87627b18f573042735490cb92",
"assets/assets/sounds/bgm/main_menu.mp3": "4c42b1cf7b11f4c9c59f548125099848",
"assets/assets/sounds/typing_sound.wav": "53135827fe47c665259a6e3c0fec0a47",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "98fe7f4d26a7db2a81e78420c0e8adb3",
"assets/NOTICES": "90435fed278d7536a834a66c426e09cb",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "ff57376880080cd0bb80e987e8f37799",
"index.html": "cecc9ed556d077ba9be3b46eb4dc6fa6",
"/": "cecc9ed556d077ba9be3b46eb4dc6fa6",
"main.dart.js": "e1360c2e42827625fc5ab8300bc1d6d9",
"version.json": "9ef90a235a3dacdc3775313b000c0c95"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
