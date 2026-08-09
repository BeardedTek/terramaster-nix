---
title: System Preferences
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Admin-only system settings. More will land here over time.
</p>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-network-panel">
    <span>Network</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-network-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  Hostname and Domain below are preview only for now. Network Interface
  and the fields below it are live &mdash; saving rebuilds the system in
  place.
</p>
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4 preferences-dimmed">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Hostname</span>
    <input type="text" value="young" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Domain</span>
    <input type="text" value="beardedtek.com" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>
<span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Network Interface</span>
<div class="flex items-center gap-4 mb-4">
  <label class="flex items-center gap-2 text-sm text-gray-900 dark:text-white">
    <input type="radio" name="net-mode" value="dhcp" checked data-mode-toggle="net-mode">
    DHCP
  </label>
  <label class="flex items-center gap-2 text-sm text-gray-900 dark:text-white">
    <input type="radio" name="net-mode" value="static" data-mode-toggle="net-mode">
    Static
  </label>
</div>
<p id="network-current-info" class="text-sm text-gray-700 dark:text-gray-300 mb-4">
  Current address: <span id="network-live-ip" class="font-mono">&mdash;</span>
</p>
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4" data-mode="net-mode:static">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">IP Address</span>
    <input type="text" id="network-ip" placeholder="192.168.3.181" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Subnet Mask / CIDR</span>
    <input type="text" id="network-prefix" placeholder="255.255.255.0" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Gateway</span>
    <input type="text" id="network-gateway" placeholder="192.168.3.1" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">DNS Servers</span>
    <input type="text" id="network-dns" placeholder="1.1.1.1, 8.8.8.8" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>
<div id="network-message" class="mb-4 text-sm hidden mt-4"></div>
<button id="network-save-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 mt-4 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save</button>
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-update-panel">
    <span>System Update</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-update-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-gray-700 dark:text-gray-300 mb-4 leading-relaxed">
  The current and latest available version are always shown below.
  Applying an update fetches the new release and rebuilds the system
  in place.
</p>

<div id="update-info" class="mb-4 text-sm text-gray-700 dark:text-gray-300">
  <p>Current version: <span id="current-version" class="font-mono">&mdash;</span></p>
  <p>Latest release: <span id="latest-version" class="font-mono">&mdash;</span> <a id="release-link" href="#" target="_blank" rel="noopener noreferrer" class="text-primary-700 dark:text-primary-500 hover:underline hidden">(notes)</a></p>
</div>

<div id="update-message" class="mb-4 text-sm hidden"></div>

<button id="check-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Check for updates</button>
<button id="update-btn" type="button" disabled class="text-white bg-gray-400 cursor-not-allowed font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-600">Update now</button>
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-services-panel">
    <span>Services</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-services-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  Enable or disable optional services. Toggling a switch previews the
  change only &mdash; nothing is applied until you click Save and confirm.
  Applying rebuilds the system in place, pinned to the currently
  installed release.
</p>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-playback-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Media Playback</span>
    </button>
  </div>
  <div id="services-group-playback-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-900 dark:text-white">Jellyfin</span>
      <label class="switch"><input type="checkbox" checked data-flag="jellyfin.enable"><span class="slider"></span></label>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-storage-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Storage</span>
    </button>
  </div>
  <div id="services-group-storage-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-900 dark:text-white">MinIO</span>
      <label class="switch"><input type="checkbox" data-flag="minio.enable"><span class="slider"></span></label>
    </div>
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-900 dark:text-white">FileBrowser</span>
      <label class="switch"><input type="checkbox" data-flag="filebrowser.enable"><span class="slider"></span></label>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-homeauto-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Home Automation</span>
    </button>
  </div>
  <div id="services-group-homeauto-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm font-medium text-gray-900 dark:text-white">Home Assistant</span>
      <label class="switch"><input type="checkbox" checked data-flag="homeAssistant.enable" data-group-toggle="homeassistant"><span class="slider"></span></label>
    </div>
    <div class="pl-6 space-y-2 mb-2" data-group="homeassistant">
      <div class="flex items-center justify-between py-2">
        <span class="text-sm text-gray-700 dark:text-gray-300">Z-Wave</span>
        <label class="switch"><input type="checkbox" data-flag="homeAssistant.zwave.enable"><span class="slider"></span></label>
      </div>
      <div class="flex items-center justify-between py-2">
        <span class="text-sm text-gray-700 dark:text-gray-300">HACS</span>
        <label class="switch"><input type="checkbox" checked data-flag="homeAssistant.hacs.enable"><span class="slider"></span></label>
      </div>
    </div>
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-900 dark:text-white">Frigate</span>
      <label class="switch"><input type="checkbox" checked data-flag="frigate.enable"><span class="slider"></span></label>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-acquisition-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Media Acquisition</span>
    </button>
  </div>
  <div id="services-group-acquisition-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3 space-y-2">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-700 dark:text-gray-300">Seerr</span>
      <label class="switch"><input type="checkbox" checked data-flag="mediaAcquisition.seerr.enable"><span class="slider"></span></label>
    </div>
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-700 dark:text-gray-300">Radarr</span>
      <label class="switch"><input type="checkbox" checked data-flag="mediaAcquisition.radarr.enable"><span class="slider"></span></label>
    </div>
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-700 dark:text-gray-300">Sonarr</span>
      <label class="switch"><input type="checkbox" checked data-flag="mediaAcquisition.sonarr.enable"><span class="slider"></span></label>
    </div>
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-700 dark:text-gray-300">Jackett</span>
      <label class="switch"><input type="checkbox" checked data-flag="mediaAcquisition.jackett.enable"><span class="slider"></span></label>
    </div>
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-700 dark:text-gray-300">qBittorrent</span>
      <label class="switch"><input type="checkbox" checked data-flag="mediaAcquisition.qbittorrent.enable"><span class="slider"></span></label>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-auth-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Authentication</span>
    </button>
  </div>
  <div id="services-group-auth-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm font-medium text-gray-900 dark:text-white">SSO</span>
      <label class="switch"><input type="checkbox" data-flag="sso.enable" data-group-toggle="sso"><span class="slider"></span></label>
    </div>
    <div class="pl-6 space-y-2 mb-2" data-group="sso">
      <div class="flex items-center justify-between py-2">
        <span class="text-sm text-gray-700 dark:text-gray-300">Authelia</span>
        <label class="switch"><input type="checkbox" data-flag="sso.authelia.enable"><span class="slider"></span></label>
      </div>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-password-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Password Manager</span>
    </button>
  </div>
  <div id="services-group-password-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm font-medium text-gray-900 dark:text-white">Vaultwarden</span>
      <label class="switch"><input type="checkbox" data-flag="vaultwarden.enable"><span class="slider"></span></label>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-meshvpn-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Mesh VPN Networks</span>
    </button>
  </div>
  <div id="services-group-meshvpn-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm font-medium text-gray-900 dark:text-white">Nebula</span>
      <label class="switch"><input type="checkbox" data-flag="nebula.enable"><span class="slider"></span></label>
    </div>
    <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
      Upload or paste the Nebula config on the
      <a href="/service-configuration/" class="text-primary-700 dark:text-primary-500 hover:underline">Service Configuration</a>
      page.
    </p>
    <div class="flex items-center justify-between py-2 mt-2">
      <span class="text-sm font-medium text-gray-900 dark:text-white">Tailscale</span>
      <label class="switch"><input type="checkbox" data-flag="tailscale.enable"><span class="slider"></span></label>
    </div>
    <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
      Authenticate (or check connection status) on the
      <a href="/service-configuration/" class="text-primary-700 dark:text-primary-500 hover:underline">Service Configuration</a>
      page.
    </p>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-monitoring-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Monitoring</span>
    </button>
  </div>
  <div id="services-group-monitoring-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm font-medium text-gray-900 dark:text-white">Scrutiny</span>
      <label class="switch"><input type="checkbox" data-flag="scrutiny.enable"><span class="slider"></span></label>
    </div>
    <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
      Hard drive S.M.A.R.T monitoring and historical trends. Has no
      login of its own, so it sits behind the same SSO gate as Sonarr
      &mdash; sign in once, reach both.
    </p>
  </div>
</div>

<button id="services-save-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save</button>
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-letsencrypt-panel">
    <span>Let's Encrypt</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-letsencrypt-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-gray-700 dark:text-gray-300 mb-4 leading-relaxed">
  Configures DNS-01 certificate issuance for Traefik. Pick your DNS
  provider, enter its credentials, and set the domain (and wildcard
  subdomain) you want a certificate for. Saving restarts Traefik to apply
  the change &mdash; takes a few seconds.
</p>

<div class="mb-4">
  <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">DNS Provider</span>
  <select id="dns-provider-select" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
    <option value="linode">Linode</option>
    <option value="cloudflare">Cloudflare</option>
    <option value="digitalocean">DigitalOcean</option>
    <option value="route53">AWS Route53</option>
    <option value="duckdns">DuckDNS</option>
    <option value="godaddy">GoDaddy</option>
    <option value="namecheap">Namecheap</option>
    <option value="gcloud">Google Cloud DNS</option>
    <option value="azure">Azure DNS</option>
    <option value="ovh">OVH</option>
    <option value="porkbun">Porkbun</option>
    <option value="vultr">Vultr</option>
    <option value="hetzner">Hetzner</option>
    <option value="gandi">Gandi</option>
    <option value="desec">deSEC</option>
  </select>
</div>

<div data-provider-fields="linode" class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Token</span>
    <input type="password" data-field="LINODE_TOKEN" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="cloudflare" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Token</span>
    <input type="password" data-field="CF_DNS_API_TOKEN" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="digitalocean" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Token</span>
    <input type="password" data-field="DO_AUTH_TOKEN" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="route53" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Access Key ID</span>
    <input type="text" data-field="AWS_ACCESS_KEY_ID" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Secret Access Key</span>
    <input type="password" data-field="AWS_SECRET_ACCESS_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="duckdns" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Token</span>
    <input type="password" data-field="DUCKDNS_TOKEN" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="godaddy" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
    <input type="text" data-field="GODADDY_API_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Secret</span>
    <input type="password" data-field="GODADDY_API_SECRET" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="namecheap" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API User</span>
    <input type="text" data-field="NAMECHEAP_API_USER" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
    <input type="password" data-field="NAMECHEAP_API_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="gcloud" class="hidden grid grid-cols-1 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">GCP Project ID</span>
    <input type="text" data-field="GCE_PROJECT" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Service Account JSON</span>
    <textarea data-field="GCE_SERVICE_ACCOUNT_JSON" rows="6" placeholder="Paste the full service-account key JSON here" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-xs"></textarea>
  </div>
</div>

<div data-provider-fields="azure" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Client ID</span>
    <input type="text" data-field="AZURE_CLIENT_ID" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Client Secret</span>
    <input type="password" data-field="AZURE_CLIENT_SECRET" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Subscription ID</span>
    <input type="text" data-field="AZURE_SUBSCRIPTION_ID" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Tenant ID</span>
    <input type="text" data-field="AZURE_TENANT_ID" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Resource Group</span>
    <input type="text" data-field="AZURE_RESOURCE_GROUP" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="ovh" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Endpoint</span>
    <input type="text" data-field="OVH_ENDPOINT" placeholder="ovh-eu" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Application Key</span>
    <input type="text" data-field="OVH_APPLICATION_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Application Secret</span>
    <input type="password" data-field="OVH_APPLICATION_SECRET" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Consumer Key</span>
    <input type="password" data-field="OVH_CONSUMER_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="porkbun" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
    <input type="text" data-field="PORKBUN_API_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Secret API Key</span>
    <input type="password" data-field="PORKBUN_SECRET_API_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="vultr" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
    <input type="password" data-field="VULTR_API_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="hetzner" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">API Key</span>
    <input type="password" data-field="HETZNER_API_KEY" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="gandi" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Bearer Token</span>
    <input type="password" data-field="GANDI_BEARER_TOKEN" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div data-provider-fields="desec" class="hidden grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Token</span>
    <input type="password" data-field="DESEC_TOKEN" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Domain</span>
    <input type="text" id="dns-domain" placeholder="example.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Wildcard Subdomain</span>
    <input type="text" id="dns-wildcard" placeholder="*.example.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>

<div id="dns-provider-message" class="mb-4 text-sm hidden"></div>

<button id="dns-provider-save-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save &amp; Apply</button>

<script>
(function () {
  var providerSelect = document.getElementById("dns-provider-select");
  var messageEl = document.getElementById("dns-provider-message");
  var saveBtn = document.getElementById("dns-provider-save-btn");
  var domainEl = document.getElementById("dns-domain");
  var wildcardEl = document.getElementById("dns-wildcard");

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.className = "mb-4 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : kind === "success"
        ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }

  // Populated from /preferences/dns-provider/current on load — which of
  // the *currently selected* provider's fields already have a value
  // saved, never the values themselves (see modules/traefik-dns01.nix's
  // currentCgi). Drives the "already set — leave blank to keep"
  // placeholders below; leaving such a field blank on save keeps
  // whatever's already there (saveCgi's own blank-means-keep fallback).
  var currentFields = {};

  function applyPlaceholders() {
    var chosen = providerSelect.value;
    var activeBlock = document.querySelector('[data-provider-fields="' + chosen + '"]');
    if (!activeBlock) return;
    activeBlock.querySelectorAll("[data-field]").forEach(function (input) {
      var alreadySet = !!currentFields[input.getAttribute("data-field")];
      input.placeholder = alreadySet ? "Already set — leave blank to keep" : "";
    });
  }

  function updateFieldVisibility() {
    var chosen = providerSelect.value;
    document.querySelectorAll("[data-provider-fields]").forEach(function (el) {
      el.classList.toggle("hidden", el.getAttribute("data-provider-fields") !== chosen);
    });
    applyPlaceholders();
  }
  providerSelect.addEventListener("change", updateFieldVisibility);
  updateFieldVisibility();

  // Pre-fills the form with whatever's already configured — provider
  // selection and the (non-secret) domain/wildcard directly, credential
  // fields only as "already set" placeholders. Silently leaves the form
  // at its blank defaults if this fails or nothing's configured yet
  // (e.g. a box that's never had this page touched).
  fetch("/preferences/dns-provider/current", { cache: "no-store" })
    .then(function (r) { return r.json(); })
    .then(function (data) {
      currentFields = data.fields || {};
      if (data.provider) { providerSelect.value = data.provider; }
      if (data.domain) { domainEl.value = data.domain; }
      if (data.wildcard) { wildcardEl.value = data.wildcard; }
      updateFieldVisibility();
    })
    .catch(function () { /* form just stays at its blank defaults */ });

  // Polls a few times after a save — the restart itself is sub-second,
  // but this still needs at least one round trip after the trigger file
  // is touched for traefik-dns01-apply.service to actually run and write
  // a result.
  function pollStatus() {
    var attempts = 0;
    var iv = setInterval(function () {
      attempts++;
      fetch("/preferences/dns-provider/status", { cache: "no-store" })
        .then(function (r) { return r.text(); })
        .then(function (text) {
          var status = text.trim();
          if (status === "ok") {
            clearInterval(iv);
            showMessage("Saved — Traefik restarted successfully.", "success");
            saveBtn.disabled = false;
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
    var chosen = providerSelect.value;
    var domain = domainEl.value.trim();
    var wildcard = wildcardEl.value.trim();
    if (!domain || !wildcard) {
      showMessage("Domain and wildcard subdomain are both required.", "error");
      return;
    }

    var fields = {};
    var activeBlock = document.querySelector('[data-provider-fields="' + chosen + '"]');
    activeBlock.querySelectorAll("[data-field]").forEach(function (input) {
      fields[input.getAttribute("data-field")] = input.value;
    });

    saveBtn.disabled = true;
    showMessage("Saving and restarting Traefik...", "info");

    fetch("/preferences/dns-provider/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ provider: chosen, domain: domain, wildcard: wildcard, fields: fields })
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
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-smtp-panel">
    <span>OpenSMTP</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-smtp-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  Lets other services on this box (password resets, 2FA links, alerts)
  send email through a real upstream provider. Saving rebuilds the
  system in place, same as Services or Network changes &mdash; it can
  take a few minutes.
</p>
<div class="flex items-center justify-between py-2 mb-4">
  <span class="text-sm font-medium text-gray-900 dark:text-white">Enable SMTP relay</span>
  <label class="switch"><input type="checkbox" id="smtp-enable"><span class="slider"></span></label>
</div>
<div id="smtp-fields">
<div class="mb-4">
  <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Provider Preset</span>
  <select id="smtp-provider-preset" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
    <option value="custom" selected>Custom / Other (SMTP)</option>
    <option value="gmail">Gmail</option>
    <option value="outlook">Outlook.com / Hotmail</option>
    <option value="yahoo">Yahoo Mail</option>
    <option value="icloud">iCloud Mail</option>
    <option value="sendgrid">SendGrid</option>
    <option value="protonmail">Proton Mail (via Bridge)</option>
  </select>
  <p id="smtp-provider-hint" class="hidden mt-2 text-sm rounded-lg p-3 bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"></p>
</div>
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">SMTP Host</span>
    <input type="text" id="smtp-host" placeholder="mail.example.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Port</span>
    <input type="number" id="smtp-port" value="587" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Encryption</span>
    <select id="smtp-scheme" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
      <option value="smtp">SMTP (none)</option>
      <option value="submission" selected>Submission (STARTTLS)</option>
      <option value="submissions">Submissions (implicit TLS)</option>
    </select>
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Sender Address</span>
    <input type="email" id="smtp-sender" placeholder="no-reply@example.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Username</span>
    <input type="text" id="smtp-username" placeholder="no-reply@example.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Password</span>
    <input type="password" id="smtp-password" placeholder="Not shown — stored outside git" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>
</div>
<div id="smtp-message" class="mt-4 text-sm hidden"></div>
<button id="smtp-save-btn" type="button" class="hidden mt-4 text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save</button>
  </div>
</div>

<!-- Modal -->
<div id="update-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <!-- Confirm view -->
    <div id="modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply update?</h3>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-6">This fetches <span id="modal-confirm-version" class="font-mono"></span> and rebuilds the system in place. It can take several minutes, and services may briefly restart as part of activation.</p>
      <div class="flex justify-end gap-2">
        <button id="modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Update now</button>
      </div>
    </div>
    <!-- Progress view -->
    <div id="modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Updating</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="step-list" class="text-sm mb-4">
        <li class="update-step" data-step="download"><span class="update-step-icon" data-step-icon="download">&#9675;</span>Downloading latest release</li>
        <li class="update-step" data-step="rebuild"><span class="update-step-icon" data-step-icon="rebuild">&#9675;</span>Rebuilding<ul id="derivations-list" class="update-derivations-list hidden"></ul></li>
        <li class="update-step" data-step="inhibitors"><span class="update-step-icon" data-step-icon="inhibitors">&#9675;</span>Check switch inhibitors</li>
        <li class="update-step" data-step="activate"><span class="update-step-icon" data-step-icon="activate">&#9675;</span>Activate configuration</li>
        <li class="update-step" data-step="etc"><span class="update-step-icon" data-step-icon="etc">&#9675;</span>Setting up /etc</li>
        <li class="update-step" data-step="reload"><span class="update-step-icon" data-step-icon="reload">&#9675;</span>Reloading &amp; restarting units</li>
        <li class="update-step" data-step="done"><span class="update-step-icon" data-step-icon="done">&#9675;</span>Done</li>
      </ul>
      <button id="log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="log-panel" class="hidden">
        <div id="log-stages" class="text-xs update-log-stages mb-2"></div>
        <pre id="log-build" class="update-log-output text-xs p-3 rounded-lg overflow-y-auto"></pre>
      </div>
      <div class="flex justify-end mt-4">
        <button id="modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Services Modal -->
<div id="services-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="services-modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <!-- Confirm view -->
    <div id="services-modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply service changes?</h3>
      <ul id="services-modal-summary" class="text-sm text-gray-700 dark:text-gray-300 mb-6 list-disc pl-5"></ul>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-6">This rebuilds the system in place. It can take several minutes, and services may briefly restart as part of activation.</p>
      <div class="flex justify-end gap-2">
        <button id="services-modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="services-modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Apply</button>
      </div>
    </div>
    <!-- Progress view -->
    <div id="services-modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Applying service changes</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="services-modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="services-modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="services-modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="services-modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="services-step-list" class="text-sm mb-4">
        <li class="update-step" data-services-step="download"><span class="update-step-icon" data-services-step-icon="download">&#9675;</span>Downloading release</li>
        <li class="update-step" data-services-step="rebuild"><span class="update-step-icon" data-services-step-icon="rebuild">&#9675;</span>Rebuilding<ul id="services-derivations-list" class="update-derivations-list hidden"></ul></li>
        <li class="update-step" data-services-step="inhibitors"><span class="update-step-icon" data-services-step-icon="inhibitors">&#9675;</span>Check switch inhibitors</li>
        <li class="update-step" data-services-step="activate"><span class="update-step-icon" data-services-step-icon="activate">&#9675;</span>Activate configuration</li>
        <li class="update-step" data-services-step="etc"><span class="update-step-icon" data-services-step-icon="etc">&#9675;</span>Setting up /etc</li>
        <li class="update-step" data-services-step="reload"><span class="update-step-icon" data-services-step-icon="reload">&#9675;</span>Reloading &amp; restarting units</li>
        <li class="update-step" data-services-step="done"><span class="update-step-icon" data-services-step-icon="done">&#9675;</span>Done</li>
      </ul>
      <button id="services-log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="services-log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="services-log-panel" class="hidden">
        <div id="services-log-stages" class="text-xs update-log-stages mb-2"></div>
        <pre id="services-log-build" class="update-log-output text-xs p-3 rounded-lg overflow-y-auto"></pre>
      </div>
      <div class="flex justify-end mt-4">
        <button id="services-modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Network Modal -->
<div id="network-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="network-modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <!-- Confirm / warning view -->
    <div id="network-modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply network changes?</h3>
      <p id="network-modal-summary" class="text-sm text-gray-700 dark:text-gray-300 mb-4"></p>
      <div class="mb-6 text-sm rounded-lg p-3 bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">
        Changing how this box gets its IP address may require updating DNS
        records or other systems that point at its current address, and
        can disrupt reachability to every service on this box if
        something here is wrong. Make sure you can reach this box another
        way (console, Nebula) before continuing.
      </div>
      <div class="flex justify-end gap-2">
        <button id="network-modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="network-modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Continue Anyway</button>
      </div>
    </div>
    <!-- Progress view -->
    <div id="network-modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Applying network changes</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="network-modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="network-modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="network-modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="network-modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="network-step-list" class="text-sm mb-4">
        <li class="update-step" data-network-step="download"><span class="update-step-icon" data-network-step-icon="download">&#9675;</span>Downloading release</li>
        <li class="update-step" data-network-step="rebuild"><span class="update-step-icon" data-network-step-icon="rebuild">&#9675;</span>Rebuilding<ul id="network-derivations-list" class="update-derivations-list hidden"></ul></li>
        <li class="update-step" data-network-step="inhibitors"><span class="update-step-icon" data-network-step-icon="inhibitors">&#9675;</span>Check switch inhibitors</li>
        <li class="update-step" data-network-step="activate"><span class="update-step-icon" data-network-step-icon="activate">&#9675;</span>Activate configuration</li>
        <li class="update-step" data-network-step="etc"><span class="update-step-icon" data-network-step-icon="etc">&#9675;</span>Setting up /etc</li>
        <li class="update-step" data-network-step="reload"><span class="update-step-icon" data-network-step-icon="reload">&#9675;</span>Reloading &amp; restarting units</li>
        <li class="update-step" data-network-step="done"><span class="update-step-icon" data-network-step-icon="done">&#9675;</span>Done</li>
      </ul>
      <button id="network-log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="network-log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="network-log-panel" class="hidden">
        <div id="network-log-stages" class="text-xs update-log-stages mb-2"></div>
        <pre id="network-log-build" class="update-log-output text-xs p-3 rounded-lg overflow-y-auto"></pre>
      </div>
      <div id="network-confirm-reachability" class="hidden mt-4 rounded-lg p-3 bg-yellow-100 dark:bg-yellow-900">
        <p class="text-sm text-yellow-800 dark:text-yellow-300 mb-2">
          Applied. Verify you can still reach the dashboard, then confirm
          below. If not confirmed within
          <span id="network-confirm-countdown" class="font-mono">5:00</span>,
          this change is rolled back automatically.
        </p>
        <p class="text-sm mb-3">
          <a id="network-confirm-link" href="#" target="_blank" rel="noopener noreferrer" class="text-primary-700 dark:text-primary-500 hover:underline font-mono"></a>
        </p>
        <div class="flex justify-end">
          <button id="network-confirm-reachability-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Confirm &mdash; Keep This Configuration</button>
        </div>
      </div>
      <div class="flex justify-end mt-4">
        <button id="network-modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- SMTP Modal -->
<div id="smtp-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="smtp-modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <!-- Confirm view -->
    <div id="smtp-modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply SMTP settings?</h3>
      <p id="smtp-modal-summary" class="text-sm text-gray-700 dark:text-gray-300 mb-6"></p>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-6">This rebuilds the system in place. It can take several minutes, and services may briefly restart as part of activation.</p>
      <div class="flex justify-end gap-2">
        <button id="smtp-modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="smtp-modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Apply</button>
      </div>
    </div>
    <!-- Progress view -->
    <div id="smtp-modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Applying SMTP settings</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="smtp-modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="smtp-modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="smtp-modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="smtp-modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="smtp-step-list" class="text-sm mb-4">
        <li class="update-step" data-smtp-step="download"><span class="update-step-icon" data-smtp-step-icon="download">&#9675;</span>Downloading release</li>
        <li class="update-step" data-smtp-step="rebuild"><span class="update-step-icon" data-smtp-step-icon="rebuild">&#9675;</span>Rebuilding<ul id="smtp-derivations-list" class="update-derivations-list hidden"></ul></li>
        <li class="update-step" data-smtp-step="inhibitors"><span class="update-step-icon" data-smtp-step-icon="inhibitors">&#9675;</span>Check switch inhibitors</li>
        <li class="update-step" data-smtp-step="activate"><span class="update-step-icon" data-smtp-step-icon="activate">&#9675;</span>Activate configuration</li>
        <li class="update-step" data-smtp-step="etc"><span class="update-step-icon" data-smtp-step-icon="etc">&#9675;</span>Setting up /etc</li>
        <li class="update-step" data-smtp-step="reload"><span class="update-step-icon" data-smtp-step-icon="reload">&#9675;</span>Reloading &amp; restarting units</li>
        <li class="update-step" data-smtp-step="done"><span class="update-step-icon" data-smtp-step-icon="done">&#9675;</span>Done</li>
      </ul>
      <button id="smtp-log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="smtp-log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="smtp-log-panel" class="hidden">
        <div id="smtp-log-stages" class="text-xs update-log-stages mb-2"></div>
        <pre id="smtp-log-build" class="update-log-output text-xs p-3 rounded-lg overflow-y-auto"></pre>
      </div>
      <div class="flex justify-end mt-4">
        <button id="smtp-modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
(function () {
  var FLAG_LABELS = {
    "jellyfin.enable": "Jellyfin",
    "minio.enable": "MinIO",
    "filebrowser.enable": "FileBrowser",
    "homeAssistant.enable": "Home Assistant",
    "homeAssistant.zwave.enable": "Z-Wave",
    "homeAssistant.hacs.enable": "HACS",
    "frigate.enable": "Frigate",
    "mediaAcquisition.enable": "Media Acquisition",
    "mediaAcquisition.seerr.enable": "Seerr",
    "mediaAcquisition.radarr.enable": "Radarr",
    "mediaAcquisition.sonarr.enable": "Sonarr",
    "mediaAcquisition.jackett.enable": "Jackett",
    "mediaAcquisition.qbittorrent.enable": "qBittorrent",
    "sso.enable": "SSO",
    "sso.authelia.enable": "Authelia",
    "nebula.enable": "Nebula",
    "tailscale.enable": "Tailscale",
    "vaultwarden.enable": "Vaultwarden",
    "scrutiny.enable": "Scrutiny"
  };

  var saveBtn = document.getElementById("services-save-btn");
  var modal = document.getElementById("services-modal");
  var modalCloseX = document.getElementById("services-modal-close-x");
  var confirmView = document.getElementById("services-modal-confirm-view");
  var progressView = document.getElementById("services-modal-progress-view");
  var summaryEl = document.getElementById("services-modal-summary");
  var cancelBtn = document.getElementById("services-modal-cancel-btn");
  var confirmBtn = document.getElementById("services-modal-confirm-btn");
  var spinnerEl = document.getElementById("services-modal-spinner");
  var iconSuccessEl = document.getElementById("services-modal-icon-success");
  var iconFailedEl = document.getElementById("services-modal-icon-failed");
  var statusTextEl = document.getElementById("services-modal-status-text");
  var logToggleBtn = document.getElementById("services-log-toggle-btn");
  var logToggleChevron = document.getElementById("services-log-toggle-chevron");
  var logPanel = document.getElementById("services-log-panel");
  var logStagesEl = document.getElementById("services-log-stages");
  var logBuildEl = document.getElementById("services-log-build");
  var modalCloseBtn = document.getElementById("services-modal-close-btn");

  var baseline = {};
  var polling = null;

  function flagInput(key) {
    return document.querySelector('[data-flag="' + key + '"]');
  }

  // Server-side (dashboard-services-save-cgi) enforces the same
  // normalization independently — this is the client-side mirror so the
  // confirm summary and the submitted payload always agree with what a
  // successful save will actually produce, rather than surprising the
  // admin with a change they didn't ask for.
  function buildPayload() {
    var payload = {};
    Object.keys(FLAG_LABELS).forEach(function (key) {
      var input = flagInput(key);
      payload[key] = !!(input && input.checked);
    });
    // Media Acquisition has no master toggle in the UI anymore — always
    // send true; the five services below it are independently
    // controlled, and there's no "disable the whole group at once"
    // control to read a value from.
    payload["mediaAcquisition.enable"] = true;
    if (!payload["sso.enable"]) { payload["sso.authelia.enable"] = false; }
    if (!payload["homeAssistant.enable"]) {
      payload["homeAssistant.zwave.enable"] = false;
      payload["homeAssistant.hacs.enable"] = false;
    }
    return payload;
  }

  function diffFromBaseline(payload) {
    var changes = [];
    Object.keys(FLAG_LABELS).forEach(function (key) {
      if (!!payload[key] !== !!baseline[key]) {
        changes.push({ key: key, enabled: !!payload[key] });
      }
    });
    return changes;
  }

  function refreshSaveVisibility() {
    var dirty = diffFromBaseline(buildPayload()).length > 0;
    saveBtn.classList.toggle("hidden", !dirty);
  }

  Object.keys(FLAG_LABELS).forEach(function (key) {
    var input = flagInput(key);
    if (input) { input.addEventListener("change", refreshSaveVisibility); }
  });

  // Pre-fills every switch from the build-time state snapshot
  // (modules/dashboard-services.nix's environment.etc JSON) and takes
  // that as the dirty-tracking baseline — always the real, currently
  // running configuration, regardless of whether it came from
  // variables.nix or a previously saved overrides file. Falls back to
  // whatever's in the static markup (this page's own best-guess
  // defaults) if the fetch fails, so the form is still usable, just
  // without a guaranteed-accurate baseline.
  fetch("/preferences/services/current", { cache: "no-store" })
    .then(function (r) { return r.json(); })
    .then(function (data) {
      Object.keys(FLAG_LABELS).forEach(function (key) {
        var input = flagInput(key);
        if (input && key in data) { input.checked = !!data[key]; }
      });
      baseline = buildPayload();
      refreshSaveVisibility();
    })
    .catch(function () {
      baseline = buildPayload();
      refreshSaveVisibility();
    });

  function openModal() { modal.classList.remove("hidden"); }
  function closeModal() { modal.classList.add("hidden"); }

  function showConfirmView(changes) {
    summaryEl.innerHTML = "";
    changes.forEach(function (c) {
      var li = document.createElement("li");
      li.textContent = (c.enabled ? "Enable: " : "Disable: ") + (FLAG_LABELS[c.key] || c.key);
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

  // Same shape as the Update modal's own STEPS/renderSteps (see the
  // script at the bottom of this page) — duplicated rather than shared
  // across the two modals' independent script blocks, matching how the
  // rest of this feature deliberately doesn't share code with the
  // Update flow. Each step's regex also matches every later step's own
  // marker, so whichever marker is furthest along in the real
  // nixos-rebuild output automatically marks everything before it done
  // too. The "download" step's own completion trigger
  // ("rebuilding (this can take a while)") is the literal phrase
  // modules/system-rebuild.nix's applyScript writes — the same shared
  // runner the Update flow uses, so these markers apply identically
  // here.
  var SERVICES_STEPS = [
    { key: "download", re: /rebuilding \(this can take a while\)|checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "rebuild", re: /checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "inhibitors", re: /activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "activate", re: /setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "etc", re: /reloading|restarting|done\. the new configuration/i },
    { key: "reload", re: /done\. the new configuration/i },
    { key: "done", re: null }
  ];

  function renderServicesSteps(data) {
    var stageText = (data.log || []).map(function (e) { return e.message; }).join(" | ");
    var buildLog = data.buildLog || "";
    var combined = stageText + "\n" + buildLog;

    SERVICES_STEPS.forEach(function (step) {
      var isDone = step.key === "done" ? data.state === "success" : step.re.test(combined);
      var li = document.querySelector('[data-services-step="' + step.key + '"]');
      var icon = document.querySelector('[data-services-step-icon="' + step.key + '"]');
      if (!li || !icon) { return; }
      li.classList.toggle("update-step-done", isDone);
      icon.innerHTML = isDone ? "&#10003;" : "&#9675;";
    });

    var derivationsList = document.getElementById("services-derivations-list");
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
    renderServicesSteps(data);
  }

  function stopPolling() {
    if (polling) { clearInterval(polling); polling = null; }
  }

  var pendingPayload = null;

  function poll() {
    fetch("/preferences/services/status", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        showProgressView();
        setTerminalIcon(data.state);
        statusTextEl.textContent = data.message || data.state;
        renderLog(data);
        if (data.state === "success") {
          stopPolling();
          baseline = pendingPayload || baseline;
          refreshSaveVisibility();
        } else if (data.state === "failed") {
          stopPolling();
        }
      })
      .catch(function () { /* try again on next tick */ });
  }

  saveBtn.addEventListener("click", function () {
    var payload = buildPayload();
    var changes = diffFromBaseline(payload);
    if (changes.length === 0) { return; }
    pendingPayload = payload;
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
    document.getElementById("services-derivations-list").classList.add("hidden");
    renderServicesSteps({ log: [], buildLog: "", state: "running" });

    fetch("/preferences/services/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(pendingPayload)
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
  var ipInput = document.getElementById("network-ip");
  var prefixInput = document.getElementById("network-prefix");
  var gatewayInput = document.getElementById("network-gateway");
  var dnsInput = document.getElementById("network-dns");
  var liveIpEl = document.getElementById("network-live-ip");
  var messageEl = document.getElementById("network-message");
  var saveBtn = document.getElementById("network-save-btn");

  var modal = document.getElementById("network-modal");
  var modalCloseX = document.getElementById("network-modal-close-x");
  var confirmView = document.getElementById("network-modal-confirm-view");
  var progressView = document.getElementById("network-modal-progress-view");
  var summaryEl = document.getElementById("network-modal-summary");
  var cancelBtn = document.getElementById("network-modal-cancel-btn");
  var confirmBtn = document.getElementById("network-modal-confirm-btn");
  var spinnerEl = document.getElementById("network-modal-spinner");
  var iconSuccessEl = document.getElementById("network-modal-icon-success");
  var iconFailedEl = document.getElementById("network-modal-icon-failed");
  var statusTextEl = document.getElementById("network-modal-status-text");
  var logToggleBtn = document.getElementById("network-log-toggle-btn");
  var logToggleChevron = document.getElementById("network-log-toggle-chevron");
  var logPanel = document.getElementById("network-log-panel");
  var logStagesEl = document.getElementById("network-log-stages");
  var logBuildEl = document.getElementById("network-log-build");
  var modalCloseBtn = document.getElementById("network-modal-close-btn");
  var confirmReachabilityEl = document.getElementById("network-confirm-reachability");
  var confirmCountdownEl = document.getElementById("network-confirm-countdown");
  var confirmLinkEl = document.getElementById("network-confirm-link");
  var confirmReachabilityBtn = document.getElementById("network-confirm-reachability-btn");

  var baseline = null;
  var polling = null;
  var pendingPayload = null;
  // Set once the *original* change's own success has been shown, so a
  // relaxed-interval poll that keeps seeing state:"success" afterward
  // doesn't re-fetch/re-show the reachability block on every tick.
  // Reset at the start of every new confirmBtn ("Continue Anyway") run.
  var reachabilityShown = false;
  var countdownInterval = null;
  var countdownRemaining = 300;

  function modeInput() {
    return document.querySelector('input[name="net-mode"]:checked');
  }

  // Mirrors modules/dashboard-network.nix's own saveCgi validation
  // (valid_ipv4/resolve_prefix) — catching bad input here means the
  // confirm/warning modal never opens for a request that was always
  // going to be rejected server-side.
  function isValidIPv4(s) {
    var parts = (s || "").split(".");
    if (parts.length !== 4) { return false; }
    return parts.every(function (p) {
      if (!/^\d{1,3}$/.test(p)) { return false; }
      if (p.length > 1 && p[0] === "0") { return false; }
      var n = parseInt(p, 10);
      return n >= 0 && n <= 255;
    });
  }

  var MASK_BITS = { 255: 8, 254: 7, 252: 6, 248: 5, 240: 4, 224: 3, 192: 2, 128: 1, 0: 0 };
  function resolvePrefix(s) {
    s = (s || "").trim();
    if (/^\d{1,2}$/.test(s)) {
      var n = parseInt(s, 10);
      return (n >= 0 && n <= 32) ? n : null;
    }
    var parts = s.split(".");
    if (parts.length !== 4) { return null; }
    var bits = [];
    var seenPartial = false;
    for (var i = 0; i < 4; i++) {
      if (!/^\d{1,3}$/.test(parts[i]) || !(parseInt(parts[i], 10) in MASK_BITS)) { return null; }
      var b = MASK_BITS[parseInt(parts[i], 10)];
      if (seenPartial && b !== 0) { return null; }
      if (b < 8) { seenPartial = true; }
      bits.push(b);
    }
    return bits[0] + bits[1] + bits[2] + bits[3];
  }

  function buildPayload() {
    var mode = modeInput() ? modeInput().value : "dhcp";
    if (mode === "dhcp") { return { mode: "dhcp" }; }
    var dns = dnsInput.value.split(",").map(function (s) { return s.trim(); }).filter(Boolean);
    return {
      mode: "static",
      ip: ipInput.value.trim(),
      prefix: prefixInput.value.trim(),
      gateway: gatewayInput.value.trim(),
      dns: dns
    };
  }

  function validationError(payload) {
    if (payload.mode === "dhcp") { return null; }
    if (!isValidIPv4(payload.ip)) { return "Invalid IP address."; }
    if (!isValidIPv4(payload.gateway)) { return "Invalid gateway."; }
    if (resolvePrefix(payload.prefix) === null) { return "Invalid subnet mask / prefix."; }
    if (payload.dns.length === 0) { return "At least one DNS server is required."; }
    for (var i = 0; i < payload.dns.length; i++) {
      if (!isValidIPv4(payload.dns[i])) { return "Invalid DNS server: " + payload.dns[i]; }
    }
    return null;
  }

  function payloadsEqual(a, b) {
    if (!a || !b) { return false; }
    return JSON.stringify(a) === JSON.stringify(b);
  }

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.className = "mb-4 text-sm rounded-lg p-3 mt-4 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }

  function refreshSaveVisibility() {
    var dirty = !payloadsEqual(buildPayload(), baseline);
    saveBtn.classList.toggle("hidden", !dirty);
  }

  [ipInput, prefixInput, gatewayInput, dnsInput].forEach(function (input) {
    input.addEventListener("input", refreshSaveVisibility);
  });
  document.querySelectorAll('input[name="net-mode"]').forEach(function (input) {
    input.addEventListener("change", refreshSaveVisibility);
  });

  // Pre-fills the form from the build-time-configured state, and shows
  // the live-active address (only knowable at request time, not build
  // time — see modules/dashboard-network.nix's currentCgi) regardless
  // of mode. Falls back to leaving the form/baseline as whatever's
  // currently on screen if this fails, same posture as the
  // Services/Let's Encrypt forms. Reused both on page load and after
  // an automatic rollback, when the live config has just changed back
  // out from under whatever the form was showing.
  function refreshFormFromCurrent() {
    return fetch("/preferences/network/current", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var mode = data.mode === "static" ? "static" : "dhcp";
        var radio = document.querySelector('input[name="net-mode"][value="' + mode + '"]');
        if (radio) {
          radio.checked = true;
          radio.dispatchEvent(new Event("change"));
        }
        if (data.ip) { ipInput.value = data.ip; }
        if (data.prefix !== null && data.prefix !== undefined) { prefixInput.value = data.prefix; }
        if (data.gateway) { gatewayInput.value = data.gateway; }
        if (data.dns && data.dns.length) { dnsInput.value = data.dns.join(", "); }
        liveIpEl.textContent = data.liveIp
          ? data.liveIp + (data.liveGateway ? " (gateway " + data.liveGateway + ")" : "")
          : "unknown";
        baseline = buildPayload();
        refreshSaveVisibility();
        return data;
      })
      .catch(function () {
        baseline = baseline || buildPayload();
        refreshSaveVisibility();
      });
  }
  refreshFormFromCurrent();

  function openModal() { modal.classList.remove("hidden"); }
  function closeModal() {
    modal.classList.add("hidden");
    // Purely a display concern — the server-side rollback timer (if
    // one is running) is completely independent of whether anything's
    // still polling to show it, so it's safe to stop watching once the
    // admin dismisses the modal.
    stopPolling();
    stopCountdown();
  }

  function describeChange(payload) {
    if (payload.mode === "dhcp") { return "Switch Network Interface to DHCP (automatic addressing)."; }
    return "Set a static address: " + payload.ip + "/" + resolvePrefix(payload.prefix) +
      ", gateway " + payload.gateway + ", DNS " + payload.dns.join(", ") + ".";
  }

  function showConfirmView(payload) {
    summaryEl.textContent = describeChange(payload);
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

  function renderCountdown() {
    var m = Math.max(0, Math.floor(countdownRemaining / 60));
    var s = Math.max(0, countdownRemaining % 60);
    confirmCountdownEl.textContent = m + ":" + (s < 10 ? "0" : "") + s;
  }

  function stopCountdown() {
    if (countdownInterval) { clearInterval(countdownInterval); countdownInterval = null; }
  }

  // Purely a display countdown — modules/dashboard-network.nix's own
  // applyScript runs the real 5-minute confirm-or-rollback timer
  // server-side, independent of whether this tab is even open, so
  // this is never the source of truth for whether a rollback happens.
  function startCountdown() {
    countdownRemaining = 300;
    renderCountdown();
    stopCountdown();
    countdownInterval = setInterval(function () {
      countdownRemaining -= 1;
      renderCountdown();
      if (countdownRemaining <= 0) {
        stopCountdown();
        statusTextEl.textContent = "Confirmation window elapsed — this change may have been rolled back automatically. Reload to check.";
      }
    }, 1000);
  }

  function hideConfirmReachability() {
    confirmReachabilityEl.classList.add("hidden");
    confirmReachabilityBtn.disabled = false;
    stopCountdown();
  }

  function showConfirmReachability() {
    confirmReachabilityEl.classList.remove("hidden");
    fetch("/preferences/network/current", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var port = data.lanLocalPort || "8090";
        var ip = data.liveIp || (pendingPayload && pendingPayload.mode === "static" ? pendingPayload.ip : "");
        var url = ip ? ("http://" + ip + ":" + port + "/") : "";
        confirmLinkEl.href = url || "#";
        confirmLinkEl.textContent = url || "(address unknown — check the dashboard directly)";
      })
      .catch(function () { /* link just stays at its placeholder */ });
    startCountdown();
  }

  // Same shape as the Update/Services modals' own STEPS/renderSteps —
  // duplicated per this repo's established "don't share code across
  // independent modal scripts" posture. The shared runner
  // (modules/system-rebuild.nix) writes the exact same progress
  // messages regardless of caller, so these markers apply unchanged.
  var NETWORK_STEPS = [
    { key: "download", re: /rebuilding \(this can take a while\)|checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "rebuild", re: /checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "inhibitors", re: /activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "activate", re: /setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "etc", re: /reloading|restarting|done\. the new configuration/i },
    { key: "reload", re: /done\. the new configuration/i },
    { key: "done", re: null }
  ];

  function renderNetworkSteps(data) {
    var stageText = (data.log || []).map(function (e) { return e.message; }).join(" | ");
    var buildLog = data.buildLog || "";
    var combined = stageText + "\n" + buildLog;

    NETWORK_STEPS.forEach(function (step) {
      var isDone = step.key === "done" ? data.state === "success" : step.re.test(combined);
      var li = document.querySelector('[data-network-step="' + step.key + '"]');
      var icon = document.querySelector('[data-network-step-icon="' + step.key + '"]');
      if (!li || !icon) { return; }
      li.classList.toggle("update-step-done", isDone);
      icon.innerHTML = isDone ? "&#10003;" : "&#9675;";
    });

    var derivationsList = document.getElementById("network-derivations-list");
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
    renderNetworkSteps(data);
  }

  function stopPolling() {
    if (polling) { clearInterval(polling); polling = null; }
  }

  function switchToRelaxedPolling() {
    // Down from every 3s during an active rebuild to every 10s once
    // settled — this keeps watching through the whole confirm window
    // so an automatic rollback (which is just another ordinary
    // kind:"network" run) gets picked up and rendered the same way any
    // other run would be, without hammering the endpoint for minutes.
    stopPolling();
    polling = setInterval(poll, 10000);
  }

  function poll() {
    fetch("/preferences/network/status", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        showProgressView();
        setTerminalIcon(data.state);
        statusTextEl.textContent = data.message || data.state;
        renderLog(data);

        var isRollback = /rolled back automatically/i.test(data.message || "");

        if (data.state === "success") {
          if (isRollback) {
            // The automatic rollback (if one fired) has now finished —
            // the live config just changed back out from under
            // whatever the form/baseline were showing.
            stopPolling();
            hideConfirmReachability();
            refreshFormFromCurrent();
          } else if (!reachabilityShown) {
            reachabilityShown = true;
            baseline = pendingPayload || baseline;
            refreshSaveVisibility();
            showConfirmReachability();
            switchToRelaxedPolling();
          }
        } else if (data.state === "failed") {
          stopPolling();
          hideConfirmReachability();
        } else if (data.state === "running" && reachabilityShown) {
          // A rollback just started running — its own eventual
          // success (handled above) closes things out.
          hideConfirmReachability();
        }
      })
      .catch(function () { /* try again on next tick */ });
  }

  saveBtn.addEventListener("click", function () {
    var payload = buildPayload();
    var err = validationError(payload);
    if (err) {
      showMessage(err, "error");
      return;
    }
    messageEl.classList.add("hidden");
    pendingPayload = payload;
    showConfirmView(payload);
  });

  cancelBtn.addEventListener("click", closeModal);
  modalCloseX.addEventListener("click", closeModal);
  modalCloseBtn.addEventListener("click", closeModal);

  logToggleBtn.addEventListener("click", function () {
    var hidden = logPanel.classList.toggle("hidden");
    logToggleChevron.style.transform = hidden ? "" : "rotate(180deg)";
    logToggleBtn.querySelector("span").textContent = hidden ? "Show details" : "Hide details";
  });

  confirmReachabilityBtn.addEventListener("click", function () {
    confirmReachabilityBtn.disabled = true;
    fetch("/preferences/network/confirm", { method: "POST" })
      .then(function () {
        hideConfirmReachability();
        statusTextEl.textContent = "Confirmed — this configuration is now permanent.";
      })
      .catch(function () {
        confirmReachabilityBtn.disabled = false;
      });
  });

  confirmBtn.addEventListener("click", function () {
    reachabilityShown = false;
    hideConfirmReachability();
    showProgressView();
    setTerminalIcon("running");
    statusTextEl.textContent = "Starting...";
    logStagesEl.innerHTML = "";
    logBuildEl.textContent = "";
    document.getElementById("network-derivations-list").classList.add("hidden");
    renderNetworkSteps({ log: [], buildLog: "", state: "running" });

    fetch("/preferences/network/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(pendingPayload)
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
  var currentEl = document.getElementById("current-version");
  var latestEl = document.getElementById("latest-version");
  var releaseLinkEl = document.getElementById("release-link");
  var messageEl = document.getElementById("update-message");
  var checkBtn = document.getElementById("check-btn");
  var updateBtn = document.getElementById("update-btn");

  var modal = document.getElementById("update-modal");
  var modalCloseX = document.getElementById("modal-close-x");
  var confirmView = document.getElementById("modal-confirm-view");
  var progressView = document.getElementById("modal-progress-view");
  var confirmVersionEl = document.getElementById("modal-confirm-version");
  var cancelBtn = document.getElementById("modal-cancel-btn");
  var confirmBtn = document.getElementById("modal-confirm-btn");
  var spinnerEl = document.getElementById("modal-spinner");
  var iconSuccessEl = document.getElementById("modal-icon-success");
  var iconFailedEl = document.getElementById("modal-icon-failed");
  var statusTextEl = document.getElementById("modal-status-text");
  var logToggleBtn = document.getElementById("log-toggle-btn");
  var logToggleChevron = document.getElementById("log-toggle-chevron");
  var logPanel = document.getElementById("log-panel");
  var logStagesEl = document.getElementById("log-stages");
  var logBuildEl = document.getElementById("log-build");
  var modalCloseBtn = document.getElementById("modal-close-btn");

  var polling = null;
  var latestKnown = "";

  // Order matters: each step's own regex also matches every later
  // step's marker, so whichever marker is the furthest along in the
  // real nixos-rebuild output automatically marks everything before it
  // done too — no separate state tracking needed between polls.
  var STEPS = [
    { key: "download", re: /rebuilding \(this can take a while\)|checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "rebuild", re: /checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "inhibitors", re: /activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "activate", re: /setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "etc", re: /reloading|restarting|done\. the new configuration/i },
    { key: "reload", re: /done\. the new configuration/i },
    { key: "done", re: null }
  ];

  function renderSteps(data) {
    var stageText = (data.log || []).map(function (e) { return e.message; }).join(" | ");
    var buildLog = data.buildLog || "";
    var combined = stageText + "\n" + buildLog;

    STEPS.forEach(function (step) {
      var isDone = step.key === "done" ? data.state === "success" : step.re.test(combined);
      var li = document.querySelector('[data-step="' + step.key + '"]');
      var icon = document.querySelector('[data-step-icon="' + step.key + '"]');
      if (!li || !icon) { return; }
      li.classList.toggle("update-step-done", isDone);
      icon.innerHTML = isDone ? "&#10003;" : "&#9675;";
    });

    var derivationsList = document.getElementById("derivations-list");
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

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.className = "mb-4 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : kind === "success"
        ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }

  function setUpdateEnabled(enabled) {
    updateBtn.disabled = !enabled;
    updateBtn.className = enabled
      ? "text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
      : "text-white bg-gray-400 cursor-not-allowed font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-600";
  }

  function stopPolling() {
    if (polling) { clearInterval(polling); polling = null; }
  }

  function openModal() { modal.classList.remove("hidden"); }
  function closeModal() { modal.classList.add("hidden"); }

  function showConfirmView() {
    confirmVersionEl.textContent = latestKnown || "the latest release";
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
    renderSteps(data);
  }

  // Renders a terminal state exactly once per run. Without this guard,
  // the success branch's own background refresh re-fetched /update/status,
  // which — for up to two minutes after a run finishes (see
  // nas-update-status-cgi's freshness window) — still reports
  // state:"success", so applyProgress ran again, called showProgressView()
  // again, and reopened the modal a moment after Close was clicked. Only
  // covers the current page load, though: lastRenderedTerminal resets to
  // null on every fresh load, so a reload *within* that same two-minute
  // window still walked straight back into the same reopen — confirmed
  // the hard way (the "Close" the user just clicked didn't survive so
  // much as one reload). DISMISS_KEY below extends the same guard across
  // reloads/sessions via localStorage instead of an in-memory variable.
  var lastRenderedTerminal = null;
  var lastRenderedData = null;
  var DISMISS_KEY = "nas-update-dismissed-run";

  // Identifies *this* run, not just "the last known terminal state" — a
  // later run's own first log entry gets a fresh timestamp the moment
  // nas-update-apply starts (it deletes progressFile up front), so this
  // naturally stops matching once a new update actually runs, with no
  // separate cleanup needed.
  function runId(data) {
    var log = data.log || [];
    return log.length ? log[0].time : (data.message || "");
  }

  function isDismissed(data) {
    var id = runId(data);
    return !!id && localStorage.getItem(DISMISS_KEY) === id;
  }

  function dismissCurrentRun() {
    if (lastRenderedTerminal && lastRenderedData) {
      var id = runId(lastRenderedData);
      if (id) { localStorage.setItem(DISMISS_KEY, id); }
    }
    closeModal();
  }

  function applyProgress(data) {
    var terminal = data.state === "success" || data.state === "failed";
    if (terminal && lastRenderedTerminal === data.state) {
      return;
    }
    if (!terminal) {
      lastRenderedTerminal = null;
    }
    lastRenderedData = data;

    // A closed modal reopening itself on the very next poll is the bug
    // above; a closed modal staying closed on the *next page load* for a
    // run the user already dismissed is the fix. Doesn't apply while the
    // modal's already open (an update actively being watched should keep
    // updating normally) — only to the "walked back onto this page"
    // case, which is exactly the state a hidden modal + terminal data
    // describes.
    if (terminal && modal.classList.contains("hidden") && isDismissed(data)) {
      if (data.state === "success") {
        lastRenderedTerminal = "success";
        stopPolling();
        currentEl.textContent = latestKnown || currentEl.textContent;
        setUpdateEnabled(false);
      } else {
        lastRenderedTerminal = "failed";
        stopPolling();
        setUpdateEnabled(true);
      }
      return;
    }

    showProgressView();
    setTerminalIcon(data.state);
    statusTextEl.textContent = data.message || data.state;
    renderLog(data);

    if (data.state === "success") {
      lastRenderedTerminal = "success";
      stopPolling();
      currentEl.textContent = latestKnown || currentEl.textContent;
      setUpdateEnabled(false);
    } else if (data.state === "failed") {
      lastRenderedTerminal = "failed";
      stopPolling();
      setUpdateEnabled(true);
    }
  }

  function checkNow() {
    fetch("/update/status", { cache: "no-store" })
      .then(function (r) {
        if (!r.ok) { throw new Error("Update service returned an error (HTTP " + r.status + ")."); }
        return r.json();
      })
      .then(function (data) {
        if (data.state) {
          applyProgress(data);
          if (data.state === "running" && !polling) {
            polling = setInterval(checkNow, 3000);
          }
          return;
        }
        currentEl.textContent = data.current || "unknown";
        if (data.error) {
          showMessage(data.error, "error");
          return;
        }
        latestEl.textContent = data.latest || "unknown";
        latestKnown = data.latest || "";
        if (data.releaseUrl) {
          releaseLinkEl.href = data.releaseUrl;
          releaseLinkEl.classList.remove("hidden");
        }
        setUpdateEnabled(!!data.updateAvailable);
        if (data.updateAvailable) {
          showMessage("A newer release is available.", "info");
        } else {
          messageEl.classList.add("hidden");
        }
      })
      .catch(function (err) {
        showMessage(err.message || "Could not reach the update service.", "error");
      });
  }

  checkBtn.addEventListener("click", checkNow);

  updateBtn.addEventListener("click", function () {
    showConfirmView();
  });

  // cancelBtn only ever appears on the pre-run confirmation screen (see
  // confirmView above) — nothing to dismiss yet, so it's a plain close,
  // not dismissCurrentRun. modalCloseX/modalCloseBtn only show once
  // setTerminalIcon marks the run terminal, which is exactly what needs
  // remembering across a reload.
  cancelBtn.addEventListener("click", closeModal);
  modalCloseX.addEventListener("click", dismissCurrentRun);
  modalCloseBtn.addEventListener("click", dismissCurrentRun);

  logToggleBtn.addEventListener("click", function () {
    var hidden = logPanel.classList.toggle("hidden");
    logToggleChevron.style.transform = hidden ? "" : "rotate(180deg)";
    logToggleBtn.querySelector("span").textContent = hidden ? "Show details" : "Hide details";
  });

  confirmBtn.addEventListener("click", function () {
    lastRenderedTerminal = null;
    showProgressView();
    setTerminalIcon("running");
    statusTextEl.textContent = "Starting...";
    logStagesEl.innerHTML = "";
    logBuildEl.textContent = "";
    document.getElementById("derivations-list").classList.add("hidden");
    renderSteps({ log: [], buildLog: "", state: "running" });
    setUpdateEnabled(false);

    fetch("/update/trigger", { method: "POST" })
      .then(function (r) {
        if (r.status === 401) { throw new Error("Not authorized to trigger updates."); }
        if (!r.ok) { throw new Error("Could not start the update."); }
        polling = setInterval(checkNow, 3000);
        checkNow();
      })
      .catch(function (err) {
        statusTextEl.textContent = err.message || "Could not start the update.";
        setTerminalIcon("failed");
        setUpdateEnabled(true);
      });
  });

  checkNow();
})();
</script>

<script>
(function () {
  var enableInput = document.getElementById("smtp-enable");
  var fieldsWrap = document.getElementById("smtp-fields");
  var presetSelect = document.getElementById("smtp-provider-preset");
  var presetHint = document.getElementById("smtp-provider-hint");
  var hostInput = document.getElementById("smtp-host");
  var portInput = document.getElementById("smtp-port");
  var schemeInput = document.getElementById("smtp-scheme");
  var senderInput = document.getElementById("smtp-sender");
  var usernameInput = document.getElementById("smtp-username");
  var passwordInput = document.getElementById("smtp-password");
  var messageEl = document.getElementById("smtp-message");
  var saveBtn = document.getElementById("smtp-save-btn");

  var modal = document.getElementById("smtp-modal");
  var modalCloseX = document.getElementById("smtp-modal-close-x");
  var confirmView = document.getElementById("smtp-modal-confirm-view");
  var progressView = document.getElementById("smtp-modal-progress-view");
  var summaryEl = document.getElementById("smtp-modal-summary");
  var cancelBtn = document.getElementById("smtp-modal-cancel-btn");
  var confirmBtn = document.getElementById("smtp-modal-confirm-btn");
  var spinnerEl = document.getElementById("smtp-modal-spinner");
  var iconSuccessEl = document.getElementById("smtp-modal-icon-success");
  var iconFailedEl = document.getElementById("smtp-modal-icon-failed");
  var statusTextEl = document.getElementById("smtp-modal-status-text");
  var logToggleBtn = document.getElementById("smtp-log-toggle-btn");
  var logToggleChevron = document.getElementById("smtp-log-toggle-chevron");
  var logPanel = document.getElementById("smtp-log-panel");
  var logStagesEl = document.getElementById("smtp-log-stages");
  var logBuildEl = document.getElementById("smtp-log-build");
  var modalCloseBtn = document.getElementById("smtp-modal-close-btn");

  // Purely a client-side convenience — every provider ultimately saves
  // through the same host/port/scheme/sender/username/password fields
  // (modules/dashboard-smtp.nix), unlike the Let's Encrypt accordion's
  // per-provider field sets, so there's no backend provider concept to
  // keep in sync with this list.
  var PROVIDER_PRESETS = {
    gmail: {
      host: "smtp.gmail.com", port: 587, scheme: "submission",
      hint: "Gmail requires an App Password (Google Account → Security → App passwords) if 2-Step Verification is on — your normal password won't work."
    },
    outlook: {
      host: "smtp-mail.outlook.com", port: 587, scheme: "submission",
      hint: "Outlook.com/Hotmail requires an App Password if two-factor authentication is enabled on the account."
    },
    yahoo: {
      host: "smtp.mail.yahoo.com", port: 587, scheme: "submission",
      hint: "Yahoo Mail requires an App Password (Account Security → Generate app password), not your normal sign-in password."
    },
    icloud: {
      host: "smtp.mail.me.com", port: 587, scheme: "submission",
      hint: "iCloud Mail requires an app-specific password, generated at appleid.apple.com under Sign-In and Security."
    },
    sendgrid: {
      host: "smtp.sendgrid.net", port: 587, scheme: "submission",
      hint: "SendGrid: set Username to the literal word \"apikey\" and Password to your SendGrid API key."
    },
    protonmail: {
      host: "127.0.0.1", port: 1025, scheme: "submission",
      hint: "Proton Mail has no direct SMTP access — this requires Proton Mail Bridge running and reachable from this box. Defaults assume Bridge on 127.0.0.1:1025; adjust if yours differs."
    }
  };

  function showMessage(text, kind) {
    messageEl.textContent = text;
    messageEl.classList.remove("hidden");
    messageEl.className = "mt-4 text-sm rounded-lg p-3 " + (
      kind === "error"
        ? "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
        : "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    );
  }
  function hideMessage() { messageEl.classList.add("hidden"); }

  function updateEnabledState() {
    var enabled = enableInput.checked;
    fieldsWrap.classList.toggle("preferences-dimmed", !enabled);
    fieldsWrap.querySelectorAll("input, select").forEach(function (el) { el.disabled = !enabled; });
  }

  function applyPreset() {
    var preset = PROVIDER_PRESETS[presetSelect.value];
    if (!preset) {
      presetHint.classList.add("hidden");
      return;
    }
    hostInput.value = preset.host;
    portInput.value = preset.port;
    schemeInput.value = preset.scheme;
    presetHint.textContent = preset.hint;
    presetHint.classList.remove("hidden");
    refreshSaveVisibility();
  }

  // passwordSet mirrors modules/dashboard-smtp.nix's currentCgi — never
  // the real password, just whether one's already on disk, driving the
  // "blank field = keep existing" placeholder/validation below.
  var baseline = { enable: false, host: "", port: 587, scheme: "submission", sender: "", username: "" };
  var passwordSet = false;

  function buildPayload() {
    var enabled = enableInput.checked;
    var payload = { enable: enabled };
    if (enabled) {
      payload.host = hostInput.value.trim();
      payload.port = parseInt(portInput.value, 10) || 0;
      payload.scheme = schemeInput.value;
      payload.sender = senderInput.value.trim();
      payload.username = usernameInput.value.trim();
    }
    return payload;
  }

  function isDirty() {
    var p = buildPayload();
    if (p.enable !== baseline.enable) { return true; }
    if (!p.enable) { return false; }
    if (p.host !== baseline.host || p.port !== baseline.port || p.scheme !== baseline.scheme ||
        p.sender !== baseline.sender || p.username !== baseline.username) { return true; }
    return !!passwordInput.value;
  }

  function refreshSaveVisibility() {
    saveBtn.classList.toggle("hidden", !isDirty());
  }

  [hostInput, portInput, schemeInput, senderInput, usernameInput, passwordInput].forEach(function (el) {
    el.addEventListener("input", refreshSaveVisibility);
    el.addEventListener("change", refreshSaveVisibility);
  });
  enableInput.addEventListener("change", function () {
    updateEnabledState();
    refreshSaveVisibility();
  });
  presetSelect.addEventListener("change", applyPreset);

  // Pre-fills the form from the build-time state snapshot
  // (modules/dashboard-smtp.nix's environment.etc JSON, plus a live
  // passwordSet check) and takes that as the dirty-tracking baseline —
  // same shape as the Services accordion's own baseline fetch.
  fetch("/preferences/smtp/current", { cache: "no-store" })
    .then(function (r) { return r.json(); })
    .then(function (data) {
      baseline = {
        enable: !!data.enable,
        host: data.host || "",
        port: data.port || 587,
        scheme: data.scheme || "submission",
        sender: data.sender || "",
        username: data.username || ""
      };
      passwordSet = !!data.passwordSet;
      enableInput.checked = baseline.enable;
      hostInput.value = baseline.host;
      portInput.value = baseline.port;
      schemeInput.value = baseline.scheme;
      senderInput.value = baseline.sender;
      usernameInput.value = baseline.username;
      passwordInput.placeholder = passwordSet ? "Already set — leave blank to keep" : "Required";
      updateEnabledState();
      refreshSaveVisibility();
    })
    .catch(function () {
      updateEnabledState();
      refreshSaveVisibility();
    });

  function openModal() { modal.classList.remove("hidden"); }
  function closeModal() { modal.classList.add("hidden"); }

  function showConfirmView(payload) {
    summaryEl.textContent = payload.enable
      ? "Enable the SMTP relay through " + payload.host + ":" + payload.port + "."
      : "Disable the SMTP relay. Password-reset and alert emails fall back to a local file until re-enabled.";
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

  // Same shape as the Services/Network modals' own STEPS/render — see
  // modules/system-rebuild.nix's applyScript for the literal log
  // phrases these regexes match against.
  var SMTP_STEPS = [
    { key: "download", re: /rebuilding \(this can take a while\)|checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "rebuild", re: /checking switch inhibitors|activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "inhibitors", re: /activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "activate", re: /setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "etc", re: /reloading|restarting|done\. the new configuration/i },
    { key: "reload", re: /done\. the new configuration/i },
    { key: "done", re: null }
  ];

  function renderSmtpSteps(data) {
    var stageText = (data.log || []).map(function (e) { return e.message; }).join(" | ");
    var buildLog = data.buildLog || "";
    var combined = stageText + "\n" + buildLog;

    SMTP_STEPS.forEach(function (step) {
      var isDone = step.key === "done" ? data.state === "success" : step.re.test(combined);
      var li = document.querySelector('[data-smtp-step="' + step.key + '"]');
      var icon = document.querySelector('[data-smtp-step-icon="' + step.key + '"]');
      if (!li || !icon) { return; }
      li.classList.toggle("update-step-done", isDone);
      icon.innerHTML = isDone ? "&#10003;" : "&#9675;";
    });

    var derivationsList = document.getElementById("smtp-derivations-list");
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
    renderSmtpSteps(data);
  }

  var polling = null;
  function stopPolling() {
    if (polling) { clearInterval(polling); polling = null; }
  }

  var pendingPayload = null;

  function poll() {
    fetch("/preferences/smtp/status", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        showProgressView();
        setTerminalIcon(data.state);
        statusTextEl.textContent = data.message || data.state;
        renderLog(data);
        if (data.state === "success") {
          stopPolling();
          if (pendingPayload) {
            baseline = {
              enable: pendingPayload.enable,
              host: pendingPayload.host || "",
              port: pendingPayload.port || 587,
              scheme: pendingPayload.scheme || "submission",
              sender: pendingPayload.sender || "",
              username: pendingPayload.username || ""
            };
          }
          if (passwordInput.value) { passwordSet = true; }
          passwordInput.value = "";
          passwordInput.placeholder = passwordSet ? "Already set — leave blank to keep" : "Required";
          refreshSaveVisibility();
        } else if (data.state === "failed") {
          stopPolling();
        }
      })
      .catch(function () { /* try again on next tick */ });
  }

  saveBtn.addEventListener("click", function () {
    var payload = buildPayload();
    if (payload.enable) {
      if (!payload.host || !payload.sender || !payload.username) {
        showMessage("Host, sender address, and username are all required.", "error");
        return;
      }
      if (!passwordInput.value && !passwordSet) {
        showMessage("A password is required the first time SMTP is enabled.", "error");
        return;
      }
    }
    hideMessage();
    pendingPayload = payload;
    showConfirmView(payload);
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
    document.getElementById("smtp-derivations-list").classList.add("hidden");
    renderSmtpSteps({ log: [], buildLog: "", state: "running" });

    var body = Object.assign({}, pendingPayload);
    if (body.enable) { body.password = passwordInput.value; }

    fetch("/preferences/smtp/save", {
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
