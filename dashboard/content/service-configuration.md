---
title: Service Configuration
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Placeholder scaffolding for per-service settings. Nothing on this page
  is live yet &mdash; every field below is a preview of what will
  eventually be configurable here, grouped the same way as the Services
  accordion in <a href="/preferences/" class="text-primary-700 dark:text-primary-500 hover:underline">System Preferences</a>.
</p>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-playback-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Media Playback</span>
    </button>
  </div>
  <div id="svccfg-category-playback-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-jellyfin-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Jellyfin</span>
        </button>
      </div>
      <div id="svccfg-jellyfin-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Library Path</span>
            <input type="text" value="/rust/media" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Transcode Path</span>
            <input type="text" value="/var/cache/jellyfin/transcodes" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Hardware Acceleration</span>
            <select disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
              <option>None</option>
              <option selected>VAAPI</option>
              <option>NVENC</option>
              <option>QSV</option>
            </select>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-storage-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Storage</span>
    </button>
  </div>
  <div id="svccfg-category-storage-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-minio-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>MinIO</span>
        </button>
      </div>
      <div id="svccfg-minio-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Root User</span>
            <input type="text" value="minioadmin" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Console Port</span>
            <input type="number" value="9001" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Data Path</span>
            <input type="text" value="/rust/minio" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-filebrowser-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>FileBrowser</span>
        </button>
      </div>
      <div id="svccfg-filebrowser-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Root Path</span>
            <input type="text" value="/rust/data" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Listen Port</span>
            <input type="number" value="8095" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-homeauto-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Home Automation</span>
    </button>
  </div>
  <div id="svccfg-category-homeauto-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-homeassistant-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Home Assistant</span>
        </button>
      </div>
      <div id="svccfg-homeassistant-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Config Path</span>
            <input type="text" value="/var/lib/hass" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Timezone</span>
            <input type="text" value="America/Chicago" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
        <div class="flex items-center justify-between py-2">
          <span class="text-sm text-gray-700 dark:text-gray-300">Enable Z-Wave</span>
          <label class="switch"><input type="checkbox" disabled><span class="slider"></span></label>
        </div>
        <div class="flex items-center justify-between py-2">
          <span class="text-sm text-gray-700 dark:text-gray-300">Enable HACS</span>
          <label class="switch"><input type="checkbox" checked disabled><span class="slider"></span></label>
        </div>
      </div>
    </div>

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-frigate-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Frigate</span>
        </button>
      </div>
      <div id="svccfg-frigate-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Camera Config Path</span>
            <input type="text" value="/var/lib/frigate/config.yml" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Detector</span>
            <select disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
              <option selected>CPU</option>
              <option>Coral (USB)</option>
              <option>Coral (PCIe)</option>
              <option>OpenVINO</option>
            </select>
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Retention (days)</span>
            <input type="number" value="14" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-acquisition-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Media Acquisition</span>
    </button>
  </div>
  <div id="svccfg-category-acquisition-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-seerr-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Seerr</span>
        </button>
      </div>
      <div id="svccfg-seerr-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Base URL</span>
            <input type="text" value="http://127.0.0.1:5055" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
            <input type="password" placeholder="Not shown" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-radarr-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Radarr</span>
        </button>
      </div>
      <div id="svccfg-radarr-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
            <input type="password" placeholder="Not shown" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Root Folder</span>
            <input type="text" value="/rust/media/movies" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Quality Profile</span>
            <select disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
              <option selected>HD-1080p</option>
              <option>Ultra-HD</option>
              <option>Any</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-sonarr-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Sonarr</span>
        </button>
      </div>
      <div id="svccfg-sonarr-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
            <input type="password" placeholder="Not shown" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Root Folder</span>
            <input type="text" value="/rust/media/tv" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Quality Profile</span>
            <select disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
              <option selected>HD-1080p</option>
              <option>Ultra-HD</option>
              <option>Any</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-jackett-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Jackett</span>
        </button>
      </div>
      <div id="svccfg-jackett-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
            <input type="password" placeholder="Not shown" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Indexers</span>
            <input type="text" value="1337x, rarbg-archive, thepiratebay" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-qbittorrent-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>qBittorrent</span>
        </button>
      </div>
      <div id="svccfg-qbittorrent-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Download Path</span>
            <input type="text" value="/rust/media/downloads" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">WebUI Port</span>
            <input type="number" value="8080" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-auth-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Authentication</span>
    </button>
  </div>
  <div id="svccfg-category-auth-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-sso-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>SSO / Authelia</span>
        </button>
      </div>
      <div id="svccfg-sso-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">Preview only &mdash; not wired up yet.</p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Session Domain</span>
            <input type="text" value="beardedtek.com" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Default 2FA Method</span>
            <select disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
              <option selected>TOTP</option>
              <option>WebAuthn</option>
              <option>None</option>
            </select>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-meshvpn-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Mesh VPN Networks</span>
    </button>
  </div>
  <div id="svccfg-category-meshvpn-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">

    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-nebula-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Nebula</span>
        </button>
      </div>
      <div id="svccfg-nebula-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
          Preview only &mdash; not wired up yet. Uploading a full config
          is already available on the
          <a href="/preferences/" class="text-primary-700 dark:text-primary-500 hover:underline">System Preferences</a>
          page, under Services &rarr; Mesh VPN Networks.
        </p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Lighthouse IP</span>
            <input type="text" value="10.100.0.1" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Listen Port</span>
            <input type="number" value="4242" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>

  </div>
</div>
