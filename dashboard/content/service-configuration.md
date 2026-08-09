---
title: Service Configuration
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Per-service settings, grouped the same way as the Services accordion in
  <a href="/preferences/" class="text-primary-700 dark:text-primary-500 hover:underline">System Preferences</a>.
  Most services here don't have anything genuinely configurable through
  this dashboard &mdash; they manage their own settings through their
  own admin UI, so those blocks just link out instead of pretending to
  offer controls that don't exist. Authelia and MinIO have a couple of
  real, live settings; Nebula's config upload lives at the bottom.
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Jellyfin has no settings exposed here &mdash; manage libraries,
          transcoding, and hardware acceleration directly in its own
          admin UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
          Root credentials are rewritten directly and MinIO is
          restarted &mdash; no system rebuild needed. Console port and
          data path are tied to firewall rules and this box's storage
          layout, so they aren't editable here.
        </p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Root Username</span>
            <input type="text" id="svccfg-minio-user" data-svcfield="minio.rootUser" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Root Password</span>
            <input type="password" id="svccfg-minio-password" data-svcfield="minio.rootPassword" placeholder="Leave blank to keep the current password" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          FileBrowser's sources and admin account are set up once at
          first boot. Manage users, permissions, and sharing directly
          in its own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Z-Wave and HACS are already toggleable &mdash; just not here.
          Manage them on
          <a href="/preferences/" class="text-primary-700 dark:text-primary-500 hover:underline">System Preferences</a>,
          under Services &rarr; Home Automation. Everything else about
          Home Assistant is managed in its own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Camera configuration lives entirely in Frigate's own config,
          not here. Manage cameras, detection, and recording directly
          in its own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Seerr has no settings exposed here &mdash; manage requests,
          users, and integrations directly in its own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Radarr generates and manages its own API key and settings
          &mdash; manage them directly in its own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Sonarr generates and manages its own API key and settings
          &mdash; manage them directly in its own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          Jackett's indexers and API key are managed entirely in its
          own UI.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-sm text-gray-700 dark:text-gray-300">
          qBittorrent's settings, including its WebUI password, are
          managed entirely in its own interface.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
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
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
          Authelia's own UI theme. Session, LDAP, and access-control
          settings aren't editable here &mdash; they're derived from
          this box's own domain and security setup.
        </p>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Theme</span>
            <select id="svccfg-authelia-theme" data-svcfield="authelia.theme" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
              <option value="auto">Auto</option>
              <option value="light">Light</option>
              <option value="dark">Dark</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="svccfg-category-password-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Password Manager</span>
    </button>
  </div>
  <div id="svccfg-category-password-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-vaultwarden-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Vaultwarden</span>
        </button>
      </div>
      <div id="svccfg-vaultwarden-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
          User accounts, vault items, and everything else are managed
          through Vaultwarden's own ADMIN_TOKEN-gated <code>/admin</code>
          panel, not here.
          <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Open it from Services</a>.
        </p>
        <div class="flex items-center justify-between py-2">
          <span class="text-sm text-gray-700 dark:text-gray-300">Allow new signups</span>
          <label class="switch"><input type="checkbox" id="svccfg-vaultwarden-signups" data-svcfield="vaultwarden.signupsAllowed"><span class="slider"></span></label>
        </div>
      </div>
    </div>
  </div>
</div>

<div id="svccfg-message" class="mb-4 text-sm hidden"></div>
<button id="svccfg-save-btn" type="button" class="hidden mb-8 text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save Changes</button>

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
          Upload or paste a complete Nebula <code>config.yaml</code> &mdash;
          the same format the Nebula mobile apps use, with the CA/cert/key
          embedded directly in the file. Saving replaces the current
          config and restarts Nebula immediately; it does not require a
          system rebuild. The current config is loaded below since this
          page is admin-only &mdash; note that it includes this node's
          private key, same as reading the file directly on the box
          would. Enabling/disabling the Nebula service itself is still
          done on
          <a href="/preferences/" class="text-primary-700 dark:text-primary-500 hover:underline">System Preferences</a>,
          under Services &rarr; Mesh VPN Networks.
        </p>
        <div id="svccfg-nebula-status" class="text-xs text-gray-500 dark:text-gray-400 mb-2"></div>
        <div class="mb-3">
          <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Upload a config file</span>
          <input type="file" id="svccfg-nebula-file" accept=".yaml,.yml,text/yaml,text/x-yaml,text/plain" class="block w-full text-sm text-gray-900 border border-gray-300 rounded-lg cursor-pointer bg-gray-50 dark:text-gray-400 focus:outline-none dark:bg-gray-700 dark:border-gray-600" />
        </div>
        <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">...or paste it directly</span>
        <textarea id="svccfg-nebula-config" rows="10" placeholder="pki:&#10;  ca: ...&#10;  cert: ...&#10;  key: ...&#10;static_host_map:&#10;  ..." class="font-mono text-xs bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white"></textarea>
        <div id="svccfg-nebula-message" class="mt-2 text-sm hidden"></div>
        <button id="svccfg-nebula-save-btn" type="button" class="mt-2 text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save Config</button>
      </div>
    </div>
    <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
      <div class="flex items-center justify-between p-3">
        <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-medium text-gray-900 dark:text-white" data-accordion-target="svccfg-tailscale-panel">
          <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
          <span>Tailscale</span>
        </button>
      </div>
      <div id="svccfg-tailscale-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
        <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
          Authenticate this box against your tailnet by pasting an auth
          key generated at
          <span class="font-mono">login.tailscale.com/admin/settings/keys</span>.
          Applying restarts the Tailscale connection immediately; it
          does not require a system rebuild. Enabling/disabling
          Tailscale itself is still done on
          <a href="/preferences/" class="text-primary-700 dark:text-primary-500 hover:underline">System Preferences</a>,
          under Services &rarr; Mesh VPN Networks.
        </p>
        <div id="svccfg-tailscale-status" class="text-xs text-gray-500 dark:text-gray-400 mb-2"></div>
        <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Auth Key</span>
        <input type="password" id="svccfg-tailscale-key" placeholder="tskey-auth-..." class="font-mono text-xs bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
        <div id="svccfg-tailscale-message" class="mt-2 text-sm hidden"></div>
        <button id="svccfg-tailscale-save-btn" type="button" class="mt-2 text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Authenticate with Key</button>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-4 mb-2">
          ...or authenticate interactively, the same way <code>tailscale up</code>
          works from a terminal &mdash; get a one-time login link and
          approve this device in your browser.
        </p>
        <button id="svccfg-tailscale-login-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-4 py-2 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Get Login Link</button>
        <div id="svccfg-tailscale-login-message" class="mt-2 text-sm hidden"></div>
        <div class="border-t border-gray-200 dark:border-gray-700 mt-4 pt-4">
          <p class="text-xs text-gray-500 dark:text-gray-400 mb-3">
            These apply on the next system rebuild via the shared Save
            Changes button below, not immediately like authentication
            above.
          </p>
          <div class="flex items-center justify-between py-2">
            <span class="text-sm text-gray-700 dark:text-gray-300">Accept DNS settings from the tailnet (MagicDNS)</span>
            <label class="switch"><input type="checkbox" id="svccfg-tailscale-accept-dns" data-svcfield="tailscale.acceptDns"><span class="slider"></span></label>
          </div>
          <div class="flex items-center justify-between py-2">
            <span class="text-sm text-gray-700 dark:text-gray-300">Accept routes/exit nodes advertised by other tailnet devices</span>
            <label class="switch"><input type="checkbox" id="svccfg-tailscale-accept-routes" data-svcfield="tailscale.acceptRoutes"><span class="slider"></span></label>
          </div>
          <div class="flex items-center justify-between py-2">
            <span class="text-sm text-gray-700 dark:text-gray-300">Advertise this device as an exit node</span>
            <label class="switch"><input type="checkbox" id="svccfg-tailscale-advertise-exit-node" data-svcfield="tailscale.advertiseExitNode"><span class="slider"></span></label>
          </div>
          <div class="py-2">
            <span class="block mb-2 text-sm text-gray-700 dark:text-gray-300">Advertise subnet routes (comma-separated CIDRs)</span>
            <input type="text" id="svccfg-tailscale-advertise-routes" data-svcfield="tailscale.advertiseRoutes" placeholder="192.168.3.0/24" class="font-mono text-xs bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- Save-changes modal (Authelia theme / MinIO credentials) -->
<div id="svcconfig-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="svcconfig-modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <!-- Confirm view -->
    <div id="svcconfig-modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply these changes?</h3>
      <ul id="svcconfig-modal-summary" class="text-sm text-gray-700 dark:text-gray-300 mb-6 list-disc pl-5"></ul>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-6">MinIO changes take effect in a couple of seconds. Authelia, Vaultwarden, and Tailscale routing/DNS changes rebuild the system in place, which can take several minutes.</p>
      <div class="flex justify-end gap-2">
        <button id="svcconfig-modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="svcconfig-modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Apply</button>
      </div>
    </div>
    <!-- Progress view -->
    <div id="svcconfig-modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Applying changes</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="svcconfig-modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="svcconfig-modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="svcconfig-modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="svcconfig-modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="svcconfig-step-list" class="text-sm mb-4">
        <li class="update-step" data-svcconfig-step="download"><span class="update-step-icon" data-svcconfig-step-icon="download">&#9675;</span>Downloading release</li>
        <li class="update-step" data-svcconfig-step="rebuild"><span class="update-step-icon" data-svcconfig-step-icon="rebuild">&#9675;</span>Rebuilding<ul id="svcconfig-derivations-list" class="update-derivations-list hidden"></ul></li>
        <li class="update-step" data-svcconfig-step="inhibitors"><span class="update-step-icon" data-svcconfig-step-icon="inhibitors">&#9675;</span>Check switch inhibitors</li>
        <li class="update-step" data-svcconfig-step="activate"><span class="update-step-icon" data-svcconfig-step-icon="activate">&#9675;</span>Activate configuration</li>
        <li class="update-step" data-svcconfig-step="etc"><span class="update-step-icon" data-svcconfig-step-icon="etc">&#9675;</span>Setting up /etc</li>
        <li class="update-step" data-svcconfig-step="reload"><span class="update-step-icon" data-svcconfig-step-icon="reload">&#9675;</span>Reloading &amp; restarting units</li>
        <li class="update-step" data-svcconfig-step="done"><span class="update-step-icon" data-svcconfig-step-icon="done">&#9675;</span>Done</li>
      </ul>
      <button id="svcconfig-log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="svcconfig-log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="svcconfig-log-panel" class="hidden">
        <div id="svcconfig-log-stages" class="text-xs update-log-stages mb-2"></div>
        <pre id="svcconfig-log-build" class="update-log-output text-xs p-3 rounded-lg overflow-y-auto"></pre>
      </div>
      <div class="flex justify-end mt-4">
        <button id="svcconfig-modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
(function () {
  var SVCFIELDS = {
    "authelia.theme": { type: "text", label: "Authelia theme", describe: function (v) { return "Change Authelia theme to " + v + "."; } },
    "minio.rootUser": { type: "text", label: "MinIO root username", describe: function (v) { return "Change MinIO root username to " + v + "."; } },
    // Deliberately never echoes the typed password back into the
    // confirm summary, even within the same page load — same
    // never-round-trips posture as every other secret this dashboard
    // handles.
    "minio.rootPassword": { type: "text", label: "MinIO root password", describe: function () { return "Update MinIO root password."; } },
    "vaultwarden.signupsAllowed": {
      type: "checkbox",
      label: "Vaultwarden signups",
      describe: function (v) { return (v ? "Enable" : "Disable") + " new signups on Vaultwarden."; }
    },
    "tailscale.acceptDns": {
      type: "checkbox",
      label: "Tailscale accept DNS",
      describe: function (v) { return (v ? "Enable" : "Disable") + " accepting DNS settings (MagicDNS) from the tailnet."; }
    },
    "tailscale.acceptRoutes": {
      type: "checkbox",
      label: "Tailscale accept routes",
      describe: function (v) { return (v ? "Enable" : "Disable") + " accepting routes/exit nodes advertised by other tailnet devices."; }
    },
    "tailscale.advertiseExitNode": {
      type: "checkbox",
      label: "Tailscale exit node",
      describe: function (v) { return (v ? "Advertise" : "Stop advertising") + " this device as a Tailscale exit node."; }
    },
    "tailscale.advertiseRoutes": {
      type: "text",
      label: "Tailscale advertised routes",
      describe: function (v) { return v ? "Advertise Tailscale subnet routes: " + v + "." : "Stop advertising Tailscale subnet routes."; }
    }
  };

  var messageEl = document.getElementById("svccfg-message");
  var saveBtn = document.getElementById("svccfg-save-btn");
  var themeInput = document.getElementById("svccfg-authelia-theme");
  var minioUserInput = document.getElementById("svccfg-minio-user");
  var minioPasswordInput = document.getElementById("svccfg-minio-password");
  var vaultwardenSignupsInput = document.getElementById("svccfg-vaultwarden-signups");
  var tailscaleAcceptDnsInput = document.getElementById("svccfg-tailscale-accept-dns");
  var tailscaleAcceptRoutesInput = document.getElementById("svccfg-tailscale-accept-routes");
  var tailscaleAdvertiseExitNodeInput = document.getElementById("svccfg-tailscale-advertise-exit-node");
  var tailscaleAdvertiseRoutesInput = document.getElementById("svccfg-tailscale-advertise-routes");

  var modal = document.getElementById("svcconfig-modal");
  var modalCloseX = document.getElementById("svcconfig-modal-close-x");
  var confirmView = document.getElementById("svcconfig-modal-confirm-view");
  var progressView = document.getElementById("svcconfig-modal-progress-view");
  var summaryEl = document.getElementById("svcconfig-modal-summary");
  var cancelBtn = document.getElementById("svcconfig-modal-cancel-btn");
  var confirmBtn = document.getElementById("svcconfig-modal-confirm-btn");
  var spinnerEl = document.getElementById("svcconfig-modal-spinner");
  var iconSuccessEl = document.getElementById("svcconfig-modal-icon-success");
  var iconFailedEl = document.getElementById("svcconfig-modal-icon-failed");
  var statusTextEl = document.getElementById("svcconfig-modal-status-text");
  var logToggleBtn = document.getElementById("svcconfig-log-toggle-btn");
  var logToggleChevron = document.getElementById("svcconfig-log-toggle-chevron");
  var logPanel = document.getElementById("svcconfig-log-panel");
  var logStagesEl = document.getElementById("svcconfig-log-stages");
  var logBuildEl = document.getElementById("svcconfig-log-build");
  var modalCloseBtn = document.getElementById("svcconfig-modal-close-btn");

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.classList.remove("hidden");
    messageEl.className = "mb-4 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }
  function hideMessage() { messageEl.classList.add("hidden"); }

  var baseline = {
    "authelia.theme": "auto",
    "minio.rootUser": "",
    "vaultwarden.signupsAllowed": false,
    "tailscale.acceptDns": false,
    "tailscale.acceptRoutes": false,
    "tailscale.advertiseExitNode": false,
    "tailscale.advertiseRoutes": ""
  };
  var minioPasswordSet = false;

  // One place to add a new field's input element — currentValue() reads
  // it according to SVCFIELDS[key].type rather than a growing chain of
  // per-key special cases, so a future checkbox/select/text field needs
  // no changes here at all, just a registry entry + this one line.
  var fieldInputs = {
    "authelia.theme": themeInput,
    "minio.rootUser": minioUserInput,
    "minio.rootPassword": minioPasswordInput,
    "vaultwarden.signupsAllowed": vaultwardenSignupsInput,
    "tailscale.acceptDns": tailscaleAcceptDnsInput,
    "tailscale.acceptRoutes": tailscaleAcceptRoutesInput,
    "tailscale.advertiseExitNode": tailscaleAdvertiseExitNodeInput,
    "tailscale.advertiseRoutes": tailscaleAdvertiseRoutesInput
  };

  function currentValue(key) {
    var el = fieldInputs[key];
    if (!el) { return ""; }
    if (SVCFIELDS[key].type === "checkbox") { return el.checked; }
    return (key === "minio.rootUser" || key === "tailscale.advertiseRoutes") ? el.value.trim() : el.value;
  }

  // Only ever includes fields that actually changed — saveCgi accepts
  // any subset of SVCFIELDS' keys, so a payload with just one field is
  // exactly as valid as one with all three. minio.rootPassword is
  // "changed" whenever it's non-empty (blank always means "keep"),
  // every other field compares against its own fetched baseline.
  function buildChanges() {
    var changes = [];
    Object.keys(SVCFIELDS).forEach(function (key) {
      var val = currentValue(key);
      if (key === "minio.rootPassword") {
        if (val) { changes.push({ key: key, value: val }); }
        return;
      }
      if (val !== baseline[key]) { changes.push({ key: key, value: val }); }
    });
    return changes;
  }

  function refreshSaveVisibility() {
    saveBtn.classList.toggle("hidden", buildChanges().length === 0);
  }

  [
    themeInput, minioUserInput, minioPasswordInput, vaultwardenSignupsInput,
    tailscaleAcceptDnsInput, tailscaleAcceptRoutesInput, tailscaleAdvertiseExitNodeInput, tailscaleAdvertiseRoutesInput
  ].forEach(function (el) {
    el.addEventListener("input", refreshSaveVisibility);
    el.addEventListener("change", refreshSaveVisibility);
  });

  fetch("/preferences/svcconfig/current", { cache: "no-store" })
    .then(function (r) { return r.json(); })
    .then(function (data) {
      baseline = {
        "authelia.theme": data["authelia.theme"] || "auto",
        "minio.rootUser": data["minio.rootUser"] || "",
        "vaultwarden.signupsAllowed": !!data["vaultwarden.signupsAllowed"],
        "tailscale.acceptDns": !!data["tailscale.acceptDns"],
        "tailscale.acceptRoutes": !!data["tailscale.acceptRoutes"],
        "tailscale.advertiseExitNode": !!data["tailscale.advertiseExitNode"],
        "tailscale.advertiseRoutes": data["tailscale.advertiseRoutes"] || ""
      };
      minioPasswordSet = !!data["minio.rootPasswordSet"];
      themeInput.value = baseline["authelia.theme"];
      minioUserInput.value = baseline["minio.rootUser"];
      minioPasswordInput.placeholder = minioPasswordSet
        ? "Leave blank to keep the current password"
        : "Required — no password set yet";
      vaultwardenSignupsInput.checked = baseline["vaultwarden.signupsAllowed"];
      tailscaleAcceptDnsInput.checked = baseline["tailscale.acceptDns"];
      tailscaleAcceptRoutesInput.checked = baseline["tailscale.acceptRoutes"];
      tailscaleAdvertiseExitNodeInput.checked = baseline["tailscale.advertiseExitNode"];
      tailscaleAdvertiseRoutesInput.value = baseline["tailscale.advertiseRoutes"];
      refreshSaveVisibility();
    })
    .catch(function () { refreshSaveVisibility(); });

  function openModal() { modal.classList.remove("hidden"); }
  function closeModal() { modal.classList.add("hidden"); }

  function showConfirmView(changes) {
    summaryEl.innerHTML = "";
    changes.forEach(function (c) {
      var li = document.createElement("li");
      li.textContent = SVCFIELDS[c.key].describe(c.value);
      summaryEl.appendChild(li);
    });
    confirmView.classList.remove("hidden");
    progressView.classList.add("hidden");
    modalCloseX.classList.add("hidden");
    openModal();
  }

  function showProgressView() {
    confirmView.classList.add("hidden");
    progressView.classList.remove("hidden");
    openModal();
  }

  function setTerminalIcon(state) {
    spinnerEl.classList.toggle("hidden", state !== "running");
    iconSuccessEl.classList.toggle("hidden", state !== "success");
    iconFailedEl.classList.toggle("hidden", state !== "failed");
    var terminal = state === "success" || state === "failed";
    modalCloseBtn.classList.toggle("hidden", !terminal);
    modalCloseX.classList.toggle("hidden", !terminal);
  }

  // Same shape as every other rebuild-driven modal on this site — see
  // modules/system-rebuild.nix's applyScript for the literal log
  // phrases these regexes match. A MinIO-only save never produces any
  // of this text (it never touches the shared runner), so every step
  // just stays unchecked and the modal resolves straight to "success"
  // from the top status line alone — no special-casing needed here.
  var SVCCONFIG_STEPS = [
    { key: "download", re: /rebuilding \(this can take a while\)|checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "rebuild", re: /checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "inhibitors", re: /activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "activate", re: /setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "etc", re: /reloading|restarting|done\. the new configuration/i },
    { key: "reload", re: /done\. the new configuration/i },
    { key: "done", re: null }
  ];

  function renderSvcconfigSteps(data) {
    var stageText = (data.log || []).map(function (e) { return e.message; }).join(" | ");
    var buildLog = data.buildLog || "";
    var combined = stageText + "\n" + buildLog;

    SVCCONFIG_STEPS.forEach(function (step) {
      var isDone = step.key === "done" ? data.state === "success" : step.re.test(combined);
      var li = document.querySelector('[data-svcconfig-step="' + step.key + '"]');
      var icon = document.querySelector('[data-svcconfig-step-icon="' + step.key + '"]');
      if (!li || !icon) { return; }
      li.classList.toggle("update-step-done", isDone);
      icon.innerHTML = isDone ? "&#10003;" : "&#9675;";
    });

    var derivationsList = document.getElementById("svcconfig-derivations-list");
    var match = buildLog.match(/these \d+ derivations?[^\n]*will be built:\r?\n((?:\s+\/nix\/store\/\S+\r?\n?)+)/i);
    if (match) {
      var lines = match[1].split(/\r?\n/).map(function (l) { return l.trim(); }).filter(Boolean);
      derivationsList.innerHTML = "";
      lines.forEach(function (l) {
        var short = l.replace(/^\/nix\/store\/[a-z0-9]+-/, "");
        var item = document.createElement("li");
        item.textContent = short;
        derivationsList.appendChild(item);
      });
      derivationsList.classList.remove("hidden");
    }
  }

  function renderLog(data) {
    var stages = data.log || [];
    logStagesEl.innerHTML = "";
    stages.forEach(function (entry) {
      var line = document.createElement("div");
      var t = "";
      try { t = new Date(entry.time).toLocaleTimeString(); } catch (e) { t = entry.time; }
      line.textContent = "[" + t + "] " + entry.message;
      logStagesEl.appendChild(line);
    });
    if (data.buildLog) {
      logBuildEl.textContent = data.buildLog;
      logBuildEl.scrollTop = logBuildEl.scrollHeight;
    }
    renderSvcconfigSteps(data);
  }

  var polling = null;
  function stopPolling() {
    if (polling) { clearInterval(polling); polling = null; }
  }

  var pendingChanges = null;

  function poll() {
    fetch("/preferences/svcconfig/status", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        showProgressView();
        setTerminalIcon(data.state);
        statusTextEl.textContent = data.message || data.state;
        renderLog(data);
        if (data.state === "success") {
          stopPolling();
          (pendingChanges || []).forEach(function (c) {
            if (c.key === "minio.rootPassword") { return; }
            baseline[c.key] = c.value;
          });
          minioPasswordInput.value = "";
          if ((pendingChanges || []).some(function (c) { return c.key === "minio.rootPassword"; })) {
            minioPasswordSet = true;
            minioPasswordInput.placeholder = "Leave blank to keep the current password";
          }
          refreshSaveVisibility();
        } else if (data.state === "failed") {
          stopPolling();
        }
      })
      .catch(function () { /* try again on next tick */ });
  }

  saveBtn.addEventListener("click", function () {
    var changes = buildChanges();
    if (changes.length === 0) { return; }
    hideMessage();
    pendingChanges = changes;
    showConfirmView(changes);
  });

  cancelBtn.addEventListener("click", closeModal);
  modalCloseX.addEventListener("click", closeModal);
  modalCloseBtn.addEventListener("click", closeModal);

  logToggleBtn.addEventListener("click", function () {
    var hidden = logPanel.classList.toggle("hidden");
    logToggleChevron.style.transform = hidden ? "" : "rotate(180deg)";
    logToggleBtn.querySelector("span").textContent = hidden ? "Show details" : "Hide details";
  });

  confirmBtn.addEventListener("click", function () {
    showProgressView();
    setTerminalIcon("running");
    statusTextEl.textContent = "Starting...";
    logStagesEl.innerHTML = "";
    logBuildEl.textContent = "";
    document.getElementById("svcconfig-derivations-list").classList.add("hidden");
    renderSvcconfigSteps({ log: [], buildLog: "", state: "running" });

    var body = {};
    (pendingChanges || []).forEach(function (c) { body[c.key] = c.value; });

    fetch("/preferences/svcconfig/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    })
      .then(function (r) {
        return r.json().then(function (data) { return { ok: r.ok, data: data }; });
      })
      .then(function (result) {
        if (!result.ok) {
          throw new Error((result.data && result.data.error) || "Save failed.");
        }
        polling = setInterval(poll, 3000);
        poll();
      })
      .catch(function (err) {
        setTerminalIcon("failed");
        statusTextEl.textContent = err.message || "Could not save.";
      });
  });
})();
</script>

<script>
(function () {
  var fileInput = document.getElementById("svccfg-nebula-file");
  var textarea = document.getElementById("svccfg-nebula-config");
  var statusEl = document.getElementById("svccfg-nebula-status");
  var messageEl = document.getElementById("svccfg-nebula-message");
  var saveBtn = document.getElementById("svccfg-nebula-save-btn");

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.classList.remove("hidden");
    messageEl.className = "mt-2 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : kind === "success"
        ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }

  // Loads the actual config into the textarea (not just a "one's set"
  // boolean) — this page is admin-only, so showing it back is the same
  // trust boundary as an admin reading the file directly on the box.
  // Only ever called on page load and right after a successful save
  // (never on a timer), so this can't clobber an admin's in-progress
  // edit mid-typing.
  function refreshStatusLine() {
    fetch("/preferences/nebula/current", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        statusEl.textContent = data.configSet
          ? "A Nebula config is currently active — shown below."
          : "No Nebula config uploaded yet.";
        textarea.value = data.config || "";
      })
      .catch(function () { statusEl.textContent = ""; });
  }
  refreshStatusLine();

  // Reads the selected file and drops its contents into the same
  // textarea the Save button reads from — one save path regardless of
  // whether the config got there by typing/pasting or by picking a
  // file, so nothing else here needs to know which happened.
  fileInput.addEventListener("change", function () {
    var file = fileInput.files && fileInput.files[0];
    if (!file) { return; }
    var reader = new FileReader();
    reader.onload = function () {
      textarea.value = String(reader.result || "");
      fileInput.value = "";
    };
    reader.onerror = function () {
      showMessage("Could not read that file.", "error");
      fileInput.value = "";
    };
    reader.readAsText(file);
  });

  // Same bounded-attempts poll shape as the Let's Encrypt accordion's
  // own pollStatus() — this never touches a rebuild (nebula.service is
  // just restarted), so a handful of 1s polls is generous, not tight.
  function pollStatus() {
    var attempts = 0;
    var iv = setInterval(function () {
      attempts++;
      fetch("/preferences/nebula/status", { cache: "no-store" })
        .then(function (r) { return r.text(); })
        .then(function (text) {
          var status = text.trim();
          if (status === "ok") {
            clearInterval(iv);
            showMessage("Saved — Nebula restarted with the new config.", "success");
            saveBtn.disabled = false;
            refreshStatusLine();
          } else if (status.indexOf("error:") === 0) {
            clearInterval(iv);
            showMessage(status.replace(/^error:\s*/, ""), "error");
            saveBtn.disabled = false;
          } else if (attempts >= 15) {
            clearInterval(iv);
            showMessage("Still applying — check back in a moment.", "info");
            saveBtn.disabled = false;
          }
        })
        .catch(function () {
          if (attempts >= 15) {
            clearInterval(iv);
            saveBtn.disabled = false;
          }
        });
    }, 1000);
  }

  saveBtn.addEventListener("click", function () {
    var body = textarea.value;
    if (!body.trim()) {
      showMessage("Upload or paste a config.yaml first.", "error");
      return;
    }

    saveBtn.disabled = true;
    showMessage("Saving and restarting Nebula...", "info");

    fetch("/preferences/nebula/save", {
      method: "POST",
      headers: { "Content-Type": "text/plain" },
      body: body
    })
      .then(function (r) {
        return r.json().then(function (data) { return { ok: r.ok, data: data }; });
      })
      .then(function (result) {
        if (!result.ok) {
          throw new Error((result.data && result.data.error) || "Save failed.");
        }
        pollStatus();
      })
      .catch(function (err) {
        showMessage(err.message || "Could not save.", "error");
        saveBtn.disabled = false;
      });
  });
})();
</script>

<script>
(function () {
  var keyInput = document.getElementById("svccfg-tailscale-key");
  var statusEl = document.getElementById("svccfg-tailscale-status");
  var messageEl = document.getElementById("svccfg-tailscale-message");
  var saveBtn = document.getElementById("svccfg-tailscale-save-btn");
  var loginBtn = document.getElementById("svccfg-tailscale-login-btn");
  var loginMessageEl = document.getElementById("svccfg-tailscale-login-message");

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.classList.remove("hidden");
    messageEl.className = "mt-2 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : kind === "success"
        ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }

  // Never fetches or shows the auth key itself — modules/dashboard-tailscale.nix's
  // currentCgi only ever reports connection status via `tailscale
  // status` (the operator-granted CLI), never anything from the key
  // file on disk. Only ever called on load and right after a save
  // resolves, so it can't clobber an admin mid-paste.
  function refreshStatusLine() {
    fetch("/preferences/tailscale/current", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data.backendState === "Running") {
          var where = data.tailscaleIp ? " (" + data.tailscaleIp + ")" : "";
          statusEl.textContent = "Connected" + where + (data.dnsName ? " — " + data.dnsName : "") + ".";
        } else if (data.backendState === "NotEnabled") {
          statusEl.textContent = "Tailscale isn't running yet — enable it on System Preferences first.";
        } else {
          statusEl.textContent = "Not authenticated.";
        }
      })
      .catch(function () { statusEl.textContent = ""; });
  }
  refreshStatusLine();

  function showLoginMessage(text, kind) {
    loginMessageEl.innerHTML = "";
    loginMessageEl.textContent = text;
    loginMessageEl.classList.remove("hidden");
    loginMessageEl.className = "mt-2 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : kind === "success"
        ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }

  // Relaxed, long-bounded poll of the *existing* status endpoint
  // (same one refreshStatusLine() already uses) — this is what
  // actually detects the admin finishing the browser flow, completely
  // independent of whether dashboard-tailscale-login-apply.service
  // itself is still running. Bound (100 * 3s = 5 minutes) matches
  // modules/dashboard-tailscale.nix's own TimeoutStartSec on that unit.
  function pollForConnected() {
    var attempts = 0;
    var iv = setInterval(function () {
      attempts++;
      fetch("/preferences/tailscale/current", { cache: "no-store" })
        .then(function (r) { return r.json(); })
        .then(function (data) {
          if (data.backendState === "Running") {
            clearInterval(iv);
            showLoginMessage("Connected.", "success");
            refreshStatusLine();
            loginBtn.disabled = false;
          } else if (attempts >= 100) {
            clearInterval(iv);
            loginBtn.disabled = false;
          }
        })
        .catch(function () {
          if (attempts >= 100) {
            clearInterval(iv);
            loginBtn.disabled = false;
          }
        });
    }, 3000);
  }

  // Short bounded poll waiting for dashboard-tailscale-login-apply.service
  // to actually print the login URL — this typically appears within a
  // second or two of the service starting, well before the admin has
  // had any chance to click it, so 15s is generous, not tight.
  function pollLoginLink() {
    var attempts = 0;
    var iv = setInterval(function () {
      attempts++;
      fetch("/preferences/tailscale/login-status", { cache: "no-store" })
        .then(function (r) { return r.json(); })
        .then(function (data) {
          if (data.loginUrl) {
            clearInterval(iv);
            loginMessageEl.innerHTML = "";
            loginMessageEl.classList.remove("hidden");
            loginMessageEl.className = "mt-2 text-sm rounded-lg p-3 bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300";
            var p = document.createElement("p");
            p.className = "mb-2";
            p.textContent = "Click this link to authorize this device, then this page will update automatically.";
            var a = document.createElement("a");
            a.href = data.loginUrl;
            a.target = "_blank";
            a.rel = "noopener noreferrer";
            a.className = "font-mono hover:underline";
            a.textContent = data.loginUrl;
            loginMessageEl.appendChild(p);
            loginMessageEl.appendChild(a);
            pollForConnected();
          } else if (attempts >= 15) {
            clearInterval(iv);
            showLoginMessage("Could not get a login link — check journalctl -u dashboard-tailscale-login-apply on the box.", "error");
            loginBtn.disabled = false;
          }
        })
        .catch(function () {
          if (attempts >= 15) {
            clearInterval(iv);
            loginBtn.disabled = false;
          }
        });
    }, 1000);
  }

  loginBtn.addEventListener("click", function () {
    loginBtn.disabled = true;
    showLoginMessage("Requesting a login link...", "info");

    fetch("/preferences/tailscale/login", { method: "POST" })
      .then(function (r) {
        if (!r.ok) { throw new Error("Could not start the login flow."); }
        pollLoginLink();
      })
      .catch(function (err) {
        showLoginMessage(err.message || "Could not start the login flow.", "error");
        loginBtn.disabled = false;
      });
  });

  // Same bounded-attempts poll shape as the Nebula block's own
  // pollStatus() — generous enough (60 * 1s) to cover
  // modules/tailscale.nix's own TimeoutStartSec=60 on the restart this
  // triggers.
  function pollStatus() {
    var attempts = 0;
    var iv = setInterval(function () {
      attempts++;
      fetch("/preferences/tailscale/status", { cache: "no-store" })
        .then(function (r) { return r.text(); })
        .then(function (text) {
          var status = text.trim();
          if (status === "ok") {
            clearInterval(iv);
            showMessage("Saved — Tailscale restarted with the new key.", "success");
            keyInput.value = "";
            saveBtn.disabled = false;
            refreshStatusLine();
          } else if (status.indexOf("error:") === 0) {
            clearInterval(iv);
            showMessage(status.replace(/^error:\s*/, ""), "error");
            saveBtn.disabled = false;
          } else if (attempts >= 60) {
            clearInterval(iv);
            showMessage("Still applying — check back in a moment.", "info");
            saveBtn.disabled = false;
          }
        })
        .catch(function () {
          if (attempts >= 60) {
            clearInterval(iv);
            saveBtn.disabled = false;
          }
        });
    }, 1000);
  }

  saveBtn.addEventListener("click", function () {
    var body = keyInput.value.trim();
    if (!body) {
      showMessage("Paste an auth key first.", "error");
      return;
    }

    saveBtn.disabled = true;
    showMessage("Authenticating...", "info");

    fetch("/preferences/tailscale/save", {
      method: "POST",
      headers: { "Content-Type": "text/plain" },
      body: body
    })
      .then(function (r) {
        return r.json().then(function (data) { return { ok: r.ok, data: data }; });
      })
      .then(function (result) {
        if (!result.ok) {
          throw new Error((result.data && result.data.error) || "Save failed.");
        }
        pollStatus();
      })
      .catch(function (err) {
        showMessage(err.message || "Could not save.", "error");
        saveBtn.disabled = false;
      });
  });
})();
</script>
