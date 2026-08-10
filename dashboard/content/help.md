---
title: Help Topics
---

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="help-samba-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Windows File Sharing (Samba)</span>
    </button>
  </div>
  <div id="help-samba-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
      Two shares are available: <strong class="font-semibold text-gray-900 dark:text-white">media</strong>
      and <strong class="font-semibold text-gray-900 dark:text-white">data</strong>.
      You'll need your username and password to connect. If the hostname
      (<code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code>)
      doesn't resolve on your network, use one of the IP addresses instead.
    </p>
    <div class="overflow-x-auto mb-8">
      <table class="w-full text-sm text-left text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 rounded-lg">
        <thead class="text-xs uppercase bg-gray-50 dark:bg-gray-800 text-gray-500 dark:text-gray-400">
          <tr>
            <th class="px-4 py-3">Address</th>
            <th class="px-4 py-3">When to use it</th>
            <th class="px-4 py-3">Value</th>
          </tr>
        </thead>
        <tbody>
          <tr class="border-t border-gray-200 dark:border-gray-700">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Hostname</td>
            <td class="px-4 py-3">Local network, if name resolution works</td>
            <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">young</code></td>
          </tr>
          <tr class="border-t border-gray-200 dark:border-gray-700">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Nebula IP</td>
            <td class="px-4 py-3">Connected over the Nebula mesh (remote)</td>
            <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">10.100.0.17</code></td>
          </tr>
          <tr class="border-t border-gray-200 dark:border-gray-700">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Local Ethernet IP</td>
            <td class="px-4 py-3">On the same LAN as the NAS</td>
            <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">192.168.3.181</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Windows</h3>
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
      Open <strong class="font-semibold text-gray-900 dark:text-white">File Explorer</strong>, type one of these
      into the address bar, and press Enter:
    </p>
    <ul class="list-disc pl-6 space-y-1 mb-6 text-gray-700 dark:text-gray-300">
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">\\young\</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">\\10.100.0.17\</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">\\192.168.3.181\</code></li>
    </ul>
    <p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
      Enter your username and password when prompted, then open
      <strong class="font-semibold text-gray-900 dark:text-white">media</strong> or
      <strong class="font-semibold text-gray-900 dark:text-white">data</strong>.
      Optional: right-click <strong class="font-semibold text-gray-900 dark:text-white">This PC</strong> &rarr;
      <strong class="font-semibold text-gray-900 dark:text-white">Map network drive</strong> to make a share
      show up as its own drive letter every time you log in.
    </p>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">macOS</h3>
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
      In <strong class="font-semibold text-gray-900 dark:text-white">Finder</strong>, press
      <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">Cmd+K</code>
      (or <strong class="font-semibold text-gray-900 dark:text-white">Go &rarr; Connect to Server</strong>),
      enter one of these, and click <strong class="font-semibold text-gray-900 dark:text-white">Connect</strong>:
    </p>
    <ul class="list-disc pl-6 space-y-1 mb-8 text-gray-700 dark:text-gray-300">
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">smb://young/</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">smb://10.100.0.17/</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">smb://192.168.3.181/</code></li>
    </ul>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Phone / tablet</h3>
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
      Most file-browser apps (Files, FE File Explorer, Documents, etc.) support
      adding an SMB/network share. In the "server" field, use one of:
    </p>
    <ul class="list-disc pl-6 space-y-1 mb-4 text-gray-700 dark:text-gray-300">
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">10.100.0.17</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">192.168.3.181</code></li>
    </ul>
    <p class="text-gray-700 dark:text-gray-300">
      Username / password: same as above.
    </p>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="help-nfs-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Linux / Mac File Sharing (NFS)</span>
    </button>
  </div>
  <div id="help-nfs-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
      NFS is available for Linux (and other Nebula-connected) clients that prefer
      it over Samba. Two exports are available:
    </p>
    <ul class="list-disc pl-6 space-y-1 mb-8 text-gray-700 dark:text-gray-300">
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young:/rust/media</code></li>
      <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young:/rust/data</code></li>
    </ul>
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
      If the hostname (<code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code>)
      doesn't resolve on your network, use one of the IP addresses instead.
    </p>
    <div class="overflow-x-auto mb-8">
      <table class="w-full text-sm text-left text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 rounded-lg">
        <thead class="text-xs uppercase bg-gray-50 dark:bg-gray-800 text-gray-500 dark:text-gray-400">
          <tr>
            <th class="px-4 py-3">Address</th>
            <th class="px-4 py-3">When to use it</th>
            <th class="px-4 py-3">Value</th>
          </tr>
        </thead>
        <tbody>
          <tr class="border-t border-gray-200 dark:border-gray-700">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Hostname</td>
            <td class="px-4 py-3">Local network, if name resolution works</td>
            <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">young</code></td>
          </tr>
          <tr class="border-t border-gray-200 dark:border-gray-700">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Nebula IP</td>
            <td class="px-4 py-3">Connected over the Nebula mesh (remote)</td>
            <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">10.100.0.17</code></td>
          </tr>
          <tr class="border-t border-gray-200 dark:border-gray-700">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Local Ethernet IP</td>
            <td class="px-4 py-3">On the same LAN as the NAS</td>
            <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">192.168.3.181</code></td>
          </tr>
        </tbody>
      </table>
    </div>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Mount on demand</h3>
    <pre class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 mb-8 overflow-x-auto text-sm font-mono text-gray-800 dark:text-gray-200">sudo mkdir -p /mnt/young-media /mnt/young-data
sudo mount -t nfs young:/rust/media /mnt/young-media
sudo mount -t nfs young:/rust/data /mnt/young-data</pre>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Mount automatically at boot</h3>
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">Add to <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">/etc/fstab</code>:</p>
    <pre class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono text-gray-800 dark:text-gray-200">young:/rust/media  /mnt/young-media  nfs  defaults,noatime  0  0
young:/rust/data   /mnt/young-data   nfs  defaults,noatime  0  0</pre>
    <p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
      Then run <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">sudo mount -a</code>
      to mount it immediately without rebooting.
    </p>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Notes</h3>
    <ul class="list-disc pl-6 space-y-2 text-gray-700 dark:text-gray-300">
      <li>Only reachable from the local network or over the Nebula mesh &mdash; not from the wider internet.</li>
    </ul>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="help-services-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Using Services</span>
    </button>
  </div>
  <div id="help-services-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
      Every service on the <a href="/services/" class="text-primary-700 dark:text-primary-500 hover:underline">Services</a>
      page is reachable the same way whether you're on the LAN, connected
      over Nebula, or connected over Tailscale &mdash; just click its card.
    </p>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Media &amp; Entertainment</h3>
    <ul class="list-disc pl-6 space-y-2 mb-6 text-gray-700 dark:text-gray-300">
      <li><strong class="font-semibold text-gray-900 dark:text-white">Jellyfin</strong> &mdash; movies and TV. Official apps for Android, iOS, Android TV, Roku, Fire TV, and most smart TVs, or any DLNA/Kodi client.</li>
      <li><strong class="font-semibold text-gray-900 dark:text-white">Plex</strong> &mdash; movies and TV. Official Plex apps on the same range of platforms; signs in with its own plex.tv account, separate from anything else on this NAS.</li>
      <li><strong class="font-semibold text-gray-900 dark:text-white">Seerr</strong> &mdash; request movies and shows to be added. No dedicated app, but its web UI works well on a phone &mdash; add it to your home screen.</li>
    </ul>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Home &amp; Cameras</h3>
    <ul class="list-disc pl-6 space-y-2 mb-6 text-gray-700 dark:text-gray-300">
      <li><strong class="font-semibold text-gray-900 dark:text-white">Home Assistant</strong> &mdash; home automation. Official Home Assistant Companion app for iOS and Android.</li>
      <li><strong class="font-semibold text-gray-900 dark:text-white">Frigate</strong> &mdash; camera recording and detection. Viewed through its own web UI, or embedded as a card inside Home Assistant &mdash; no separate app.</li>
    </ul>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Files &amp; Storage</h3>
    <ul class="list-disc pl-6 space-y-2 mb-6 text-gray-700 dark:text-gray-300">
      <li><strong class="font-semibold text-gray-900 dark:text-white">Files</strong> &mdash; browse and upload to media/data storage from any browser, phone included. See the Samba/NFS sections above for direct filesystem access instead.</li>
      <li><strong class="font-semibold text-gray-900 dark:text-white">MinIO</strong> &mdash; S3-compatible object storage, mainly for developer/admin use.</li>
      <li><strong class="font-semibold text-gray-900 dark:text-white">Vaultwarden</strong> &mdash; password manager, Bitwarden-compatible. Use any official Bitwarden app or browser extension on any platform, pointed at this server as your "self-hosted" server.</li>
    </ul>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Admin &amp; Automation</h3>
    <p class="text-gray-700 dark:text-gray-300 mb-2 leading-relaxed">
      These mostly run in the background — most households never need to
      open them directly.
    </p>
    <ul class="list-disc pl-6 space-y-2 text-gray-700 dark:text-gray-300">
      <li><strong class="font-semibold text-gray-900 dark:text-white">Radarr, Sonarr, Jackett, qBittorrent</strong> &mdash; the automation behind Seerr requests: finding, downloading, and organizing media once you've requested it.</li>
      <li><strong class="font-semibold text-gray-900 dark:text-white">Scrutiny</strong> &mdash; hard drive health monitoring and history.</li>
    </ul>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="help-troubleshooting-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Troubleshooting</span>
    </button>
  </div>
  <div id="help-troubleshooting-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
      Quick answers for common issues. This NAS is meant to just stay on and
      run &mdash; you shouldn't need to do much here.
    </p>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Restarting or shutting down safely</h3>
    <p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
      <strong class="font-semibold text-gray-900 dark:text-white">Never just unplug it.</strong>
      That can corrupt files that were mid-write.
    </p>
    <ol class="list-decimal pl-6 space-y-2 mb-4 text-gray-700 dark:text-gray-300">
      <li>Press the power button on the front of the NAS <strong class="font-semibold text-gray-900 dark:text-white">once, briefly</strong>.</li>
      <li>Wait &mdash; the drive lights will keep blinking for a bit while it shuts down cleanly. This can take a minute or two.</li>
      <li>Once all the lights are off, it's safe to unplug it if you need to.</li>
      <li>To turn it back on, press the power button again.</li>
    </ol>
    <p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
      There's no separate "restart" button &mdash; to restart, shut it down
      (above), then press the power button again to turn it back on.
    </p>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">A share or service isn't working</h3>
    <ul class="list-disc pl-6 space-y-2 mb-8 text-gray-700 dark:text-gray-300">
      <li>Give it a minute and try again &mdash; something may just be restarting.</li>
      <li>Check that your own device is connected to the network / Nebula properly.</li>
      <li>Check the <a href="/" class="text-primary-700 dark:text-primary-500 hover:underline">Dashboard</a> page &mdash; if the network cards show "down", the problem is the NAS's connection, not yours.</li>
      <li>Still stuck? Contact the admin rather than trying to fix it yourself.</li>
    </ul>
    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mt-6 mb-3">Can't connect to Samba or NFS</h3>
    <p class="text-gray-700 dark:text-gray-300">
      See the file-sharing sections above for setup steps.
      Double-check your username and password if it's asking again.
    </p>
  </div>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-3">
  <div class="flex items-center justify-between p-3">
    <button type="button" class="accordion-toggle flex items-center gap-2 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="help-contact-panel">
      <svg class="accordion-chevron w-4 h-4 transition-transform shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
      <span>Getting Help</span>
    </button>
  </div>
  <div id="help-contact-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-3">
    <p class="text-gray-700 dark:text-gray-300 mb-3">
      For anything not covered here, get in touch:
    </p>
    {{< contact >}}
  </div>
</div>
