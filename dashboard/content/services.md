---
title: Services
---

<div id="cert-pending-banner" class="hidden mb-6 text-sm rounded-lg p-4 bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">
  <p class="font-semibold mb-2"><span id="cert-pending-services"></span> can't finish starting up yet</p>
  <p class="mb-2">
    These services log into Authelia over HTTPS, which needs a valid
    Let's Encrypt certificate for this box's domain. That certificate
    hasn't been issued yet, so they're stuck offline until it is.
  </p>
  <p class="mb-1">To fix it:</p>
  <ol class="list-decimal list-inside space-y-1">
    <li>Open <a href="/preferences/" class="underline">Preferences</a> and expand "Let's Encrypt SSL Certs".</li>
    <li>Pick your DNS provider, enter its API credentials, and save.</li>
    <li>Traefik requests the certificate automatically — this can take a few minutes for DNS propagation.</li>
    <li>Once it's issued, these services retry automatically and should come online within about 2 minutes. No further action needed.</li>
  </ol>
</div>

<div id="service-grid" class="grid grid-cols-2 sm:grid-cols-3 gap-4">
  <a data-service="jellyfin" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/jellyfin.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Jellyfin</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Movies &amp; TV</span>
      </div>
    </div>
  </a>
  <a data-service="plex" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/plex.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Plex</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Movies &amp; TV</span>
      </div>
    </div>
  </a>
  <a data-service="hass" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/hass.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Home Assistant</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Home Automation</span>
      </div>
    </div>
  </a>
  <a data-service="frigate" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/frigate.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Frigate</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Cameras</span>
      </div>
    </div>
  </a>
  <a data-service="seerr" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/seerr.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Seerr</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Request Media</span>
      </div>
    </div>
  </a>
  <a data-service="radarr" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/radarr.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Radarr</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Movie Manager</span>
      </div>
    </div>
  </a>
  <a data-service="sonarr" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/sonarr.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Sonarr</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">TV Manager</span>
      </div>
    </div>
  </a>
  <a data-service="jackett" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/jackett.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Jackett</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Indexer Proxy</span>
      </div>
    </div>
  </a>
  <a data-service="qbittorrent" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/qbittorrent.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">qBittorrent</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Media Downloads</span>
      </div>
    </div>
  </a>
  <a data-service="minio-console" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/minio-console.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">MinIO</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Object Storage</span>
      </div>
    </div>
  </a>
  <a data-service="files" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/files.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Files</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Browse Media &amp; Data</span>
      </div>
    </div>
  </a>
  <a data-service="vaultwarden" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/vaultwarden.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Vaultwarden</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Password Manager</span>
      </div>
    </div>
  </a>
  <a data-service="scrutiny" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/scrutiny.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Scrutiny</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Drive Monitoring</span>
      </div>
    </div>
  </a>
  <a data-service="immich" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/immich.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Immich</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Photos &amp; Videos</span>
      </div>
    </div>
  </a>
  <a data-service="traefik" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/traefik.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Traefik</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Reverse Proxy</span>
      </div>
    </div>
  </a>
  <a data-service="letsencrypt" href="/letsencrypt/" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/letsencrypt.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">Let's Encrypt</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">SSL Certificates</span>
      </div>
    </div>
  </a>
  <a data-service="adguardhome" href="#" target="_blank" rel="noopener noreferrer" class="flex flex-col aspect-square p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm hover:border-primary-500 dark:hover:border-primary-500 text-center transition-opacity">
    <div class="flex justify-end">
      <span class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
        <span class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
        <span class="status-text">&hellip;</span>
      </span>
    </div>
    <div class="flex-1 flex items-center justify-center gap-3">
      <img src="/images/services/adguardhome.svg" alt="" class="w-10 h-10 shrink-0" />
      <div class="flex flex-col items-start text-left">
        <span class="text-lg font-semibold text-gray-900 dark:text-white">AdGuard Home</span>
        <span class="text-sm text-gray-500 dark:text-gray-400">Ad-Blocking &amp; Local DNS</span>
      </div>
    </div>
  </a>
</div>

<script>
(function () {
  var host = window.location.hostname;
  var onNebula = host.indexOf(".nebula.") !== -1;
  var onLocalPath = window.location.port === "8090";

  // "online"/"warning" (2 legacy up/down states, plus a 3rd for cards
  // like Let's Encrypt that carry an s.state instead of a plain s.up) —
  // "warning" stays full-opacity (still up, just needs attention) while
  // "offline"/"disabled" both dim the card.
  function badgeClasses(kind) {
    if (kind === "online") {
      return {
        badge: "status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300",
        dot: "status-dot w-1.5 h-1.5 rounded-full bg-green-500",
        text: "ONLINE"
      };
    }
    if (kind === "warning") {
      return {
        badge: "status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-300",
        dot: "status-dot w-1.5 h-1.5 rounded-full bg-yellow-500",
        text: "WARNING"
      };
    }
    return {
      badge: "status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-300",
      dot: "status-dot w-1.5 h-1.5 rounded-full bg-red-500",
      text: kind === "disabled" ? "DISABLED" : "OFFLINE"
    };
  }

  function applyStatus(data) {
    var names = {};
    (data.services || []).forEach(function (s) {
      names[s.name] = true;
      var card = document.querySelector('#service-grid a[data-service="' + s.name + '"]');
      if (!card) return;
      // Let's Encrypt's card links to the dedicated /letsencrypt/ page
      // (already set in the markup) — it has no proxied backend/port, so
      // it must never get the generic external-hostname treatment below.
      if (s.name !== "letsencrypt") {
        if (onLocalPath && s.port) {
          card.href = "http://" + host + ":" + s.port + "/";
        } else if (data.host) {
          var target = onNebula
            ? s.name + "-" + data.host + ".nebula.beardedtek.com"
            : s.name + "." + data.host + ".beardedtek.com";
          card.href = "https://" + target + "/";
        }
      }
      var badge = card.querySelector(".status-badge");
      var dot = card.querySelector(".status-dot");
      var text = card.querySelector(".status-text");
      var kind = s.state || (s.up ? "online" : "offline");
      var classes = badgeClasses(kind);
      if (kind === "offline" || kind === "disabled") {
        card.classList.add("opacity-40", "grayscale");
      } else {
        card.classList.remove("opacity-40", "grayscale");
      }
      if (badge) badge.className = classes.badge;
      if (dot) dot.className = classes.dot;
      if (text) text.textContent = classes.text;
    });
    document.querySelectorAll("#service-grid a[data-service]").forEach(function (a) {
      a.style.display = names[a.getAttribute("data-service")] ? "" : "none";
    });

    // Explains an otherwise-mysterious OFFLINE badge on a fresh install:
    // FileBrowser and MinIO both validate their OIDC config against
    // Authelia over HTTPS at startup (see modules/filebrowser.nix,
    // modules/minio.nix), which fails until Traefik actually has a real
    // Let's Encrypt cert for this box's domain. Only shown when SSO is
    // actually enabled (data.ssoEnabled) — without it neither service
    // depends on the cert at all, so a coincidentally-offline card would
    // otherwise get a misleading explanation.
    var certDependentServices = { files: "Files", "minio-console": "MinIO" };
    var pendingLabels = [];
    if (data.ssoEnabled && data.certIssued === false) {
      Object.keys(certDependentServices).forEach(function (svc) {
        if (!names[svc]) return;
        var text = document.querySelector('#service-grid a[data-service="' + svc + '"] .status-text');
        if (text && text.textContent === "OFFLINE") pendingLabels.push(certDependentServices[svc]);
      });
    }
    var banner = document.getElementById("cert-pending-banner");
    if (banner) {
      if (pendingLabels.length > 0) {
        document.getElementById("cert-pending-services").textContent = pendingLabels.join(" and ");
        banner.classList.remove("hidden");
      } else {
        banner.classList.add("hidden");
      }
    }
  }

  function refresh() {
    fetch("/metrics.json", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(applyStatus)
      .catch(function () {});
  }

  refresh();
  setInterval(refresh, 30000);
})();
</script>
