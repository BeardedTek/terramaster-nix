---
title: System Preferences
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Admin-only system settings. More will land here over time.
</p>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-update-panel">
    <span>System Update</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" style="transform: rotate(180deg)" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-update-panel" class="border-t border-gray-200 dark:border-gray-700 p-4">
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
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" style="transform: rotate(180deg)" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Media Playback</span>
    </button>
  </div>
  <div id="services-group-playback-panel" class="border-t border-gray-200 dark:border-gray-700 p-3">
    <div class="flex items-center justify-between py-2">
      <span class="text-sm text-gray-900 dark:text-white">Jellyfin</span>
      <label class="switch"><input type="checkbox" checked data-flag="jellyfin.enable"><span class="slider"></span></label>
    </div>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="services-group-storage-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" style="transform: rotate(180deg)" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Storage</span>
    </button>
  </div>
  <div id="services-group-storage-panel" class="border-t border-gray-200 dark:border-gray-700 p-3">
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
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" style="transform: rotate(180deg)" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Home Automation</span>
    </button>
  </div>
  <div id="services-group-homeauto-panel" class="border-t border-gray-200 dark:border-gray-700 p-3">
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
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" style="transform: rotate(180deg)" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Media Acquisition</span>
    </button>
    <label class="switch"><input type="checkbox" checked data-flag="mediaAcquisition.enable" data-group-toggle="mediaacquisition"><span class="slider"></span></label>
  </div>
  <div id="services-group-acquisition-panel" class="border-t border-gray-200 dark:border-gray-700 p-3 space-y-2" data-group="mediaacquisition">
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
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" style="transform: rotate(180deg)" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Authentication</span>
    </button>
  </div>
  <div id="services-group-auth-panel" class="border-t border-gray-200 dark:border-gray-700 p-3">
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

<button id="services-save-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Save</button>
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-smtp-panel">
    <span>OpenSMTP</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-smtp-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  Mirrors mySystem.smtp in variables.nix. Preview only &mdash; this form
  isn't wired up yet.
</p>
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">SMTP Host</span>
    <input type="text" value="mail.beardedtek.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Port</span>
    <input type="number" value="465" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Encryption</span>
    <select class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white">
      <option value="smtp">SMTP (none)</option>
      <option value="submission">Submission (STARTTLS)</option>
      <option value="submissions" selected>Submissions (implicit TLS)</option>
    </select>
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Sender Address</span>
    <input type="email" value="NO-REPLY@beardedtek.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Username</span>
    <input type="text" value="no-reply@beardedtek.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Password</span>
    <input type="password" placeholder="Not shown — stored outside git" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-network-panel">
    <span>Network</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-network-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  Preview only &mdash; this form isn't wired up yet.
</p>
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Hostname</span>
    <input type="text" value="young" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Domain</span>
    <input type="text" value="beardedtek.com" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
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
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4" data-mode="net-mode:static">
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">IP Address</span>
    <input type="text" placeholder="192.168.3.181" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Subnet Mask / CIDR</span>
    <input type="text" placeholder="255.255.255.0" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Gateway</span>
    <input type="text" placeholder="192.168.3.1" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
  <div>
    <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">DNS Servers</span>
    <input type="text" placeholder="1.1.1.1, 8.8.8.8" disabled class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
  </div>
</div>
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
    "sso.authelia.enable": "Authelia"
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
    if (!payload["sso.enable"]) { payload["sso.authelia.enable"] = false; }
    if (!payload["homeAssistant.enable"]) {
      payload["homeAssistant.zwave.enable"] = false;
      payload["homeAssistant.hacs.enable"] = false;
    }
    if (!payload["mediaAcquisition.enable"]) {
      payload["mediaAcquisition.seerr.enable"] = false;
      payload["mediaAcquisition.radarr.enable"] = false;
      payload["mediaAcquisition.sonarr.enable"] = false;
      payload["mediaAcquisition.jackett.enable"] = false;
      payload["mediaAcquisition.qbittorrent.enable"] = false;
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
