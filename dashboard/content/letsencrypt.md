---
title: Let's Encrypt
---

<div class="flex items-center gap-3 mb-6">
  <span id="le-status-badge" class="status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
    <span id="le-status-dot" class="status-dot w-1.5 h-1.5 rounded-full bg-gray-400"></span>
    <span id="le-status-text">&hellip;</span>
  </span>
</div>

<div id="le-diagnostics" class="hidden mb-6 text-sm rounded-lg p-4 bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">
  <p class="font-semibold mb-2">Most recent error</p>
  <p id="le-last-error" class="mb-4 font-mono text-xs break-all">&mdash;</p>

  <p class="font-semibold mb-2">Suggested next steps</p>
  <ul id="le-hints" class="list-disc list-inside space-y-1 mb-4"></ul>

  <p class="font-semibold mb-2">Current DNS records for this domain</p>
  <dl class="text-xs font-mono mb-4 space-y-1">
    <div><dt class="inline font-semibold">NS</dt> <dd class="inline">&mdash; <span id="le-dns-ns">&mdash;</span></dd></div>
    <div><dt class="inline font-semibold">SOA</dt> <dd class="inline">&mdash; <span id="le-dns-soa">&mdash;</span></dd></div>
    <div><dt class="inline font-semibold">A / AAAA</dt> <dd class="inline">&mdash; <span id="le-dns-a">&mdash;</span> <span class="not-italic text-yellow-700 dark:text-yellow-400">(not required for DNS-01)</span></dd></div>
    <div><dt class="inline font-semibold">TXT _acme-challenge</dt> <dd class="inline">&mdash; <span id="le-dns-txt">&mdash;</span> <span class="text-yellow-700 dark:text-yellow-400">(ephemeral &mdash; normal to be empty except right after a save)</span></dd></div>
  </dl>

  <button id="le-diag-refresh-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Refresh diagnostics</button>
</div>

<p class="text-gray-700 dark:text-gray-300 mb-4 leading-relaxed">
  This system uses DNS-01 Certificate Issuance for SSL Certs which
  does not require your NAS to be exposed to the general internet,
  but requires you to have a registered domain name.
</p>
<p class="text-gray-700 dark:text-gray-300 mb-4 leading-relaxed">
  Choose your DNS provider and fill in your credentials.
  All fields are required.
</p>
<p class="text-gray-700 dark:text-gray-300 mb-4 leading-relaxed">
  NOTE: you must have either a DNS server with records for this
  domain pointed at this NAS or on each computer manually edit
  the hosts file in order for domain resolution to properly work.
  If you have questions about this please contact your admin
  listed in the footer of this page.
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
            refreshLeStatus();
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

  // --- Status badge + on-demand diagnostics ---------------------------
  // The badge reuses the same coarse state modules/dashboard.nix's
  // metricsScript already computes for the Services-page card (one
  // fetch of the already-polled /metrics.json, no extra endpoint).
  // Diagnostics (the real DNS lookups + log scan) are deliberately NOT
  // part of that 30s loop — they're only ever triggered here, either
  // automatically once when this page loads with a WARNING state, or
  // manually via the Refresh button.
  var badgeEl = document.getElementById("le-status-badge");
  var dotEl = document.getElementById("le-status-dot");
  var textEl = document.getElementById("le-status-text");
  var diagBox = document.getElementById("le-diagnostics");
  var diagRefreshBtn = document.getElementById("le-diag-refresh-btn");
  var lastErrorEl = document.getElementById("le-last-error");
  var hintsEl = document.getElementById("le-hints");
  var dnsNsEl = document.getElementById("le-dns-ns");
  var dnsSoaEl = document.getElementById("le-dns-soa");
  var dnsAEl = document.getElementById("le-dns-a");
  var dnsTxtEl = document.getElementById("le-dns-txt");
  var diagAutoTriggered = false;
  var diagPolling = null;

  function setBadge(kind) {
    var classes, dotClasses, text;
    if (kind === "online") {
      classes = "status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300";
      dotClasses = "status-dot w-1.5 h-1.5 rounded-full bg-green-500";
      text = "ONLINE";
    } else if (kind === "warning") {
      classes = "status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-300";
      dotClasses = "status-dot w-1.5 h-1.5 rounded-full bg-yellow-500";
      text = "WARNING";
    } else {
      classes = "status-badge inline-flex items-center gap-1 px-2 py-0.5 text-xs font-semibold rounded bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-300";
      dotClasses = "status-dot w-1.5 h-1.5 rounded-full bg-red-500";
      text = "DISABLED";
    }
    badgeEl.className = classes;
    dotEl.className = dotClasses;
    textEl.textContent = text;
  }

  function renderDiag(data) {
    lastErrorEl.textContent = data.lastError || "No recent ACME error found in the log.";
    hintsEl.innerHTML = "";
    (data.hints || []).forEach(function (h) {
      var li = document.createElement("li");
      li.textContent = h;
      hintsEl.appendChild(li);
    });
    dnsNsEl.textContent = data.dns && data.dns.ns ? data.dns.ns.replace(/\n/g, ", ") : "none found";
    dnsSoaEl.textContent = data.dns && data.dns.soa ? data.dns.soa : "none found";
    var aRecords = [data.dns && data.dns.a, data.dns && data.dns.aaaa].filter(Boolean).join(", ");
    dnsAEl.textContent = aRecords ? aRecords.replace(/\n/g, ", ") : "none found";
    dnsTxtEl.textContent = data.dns && data.dns.txt ? data.dns.txt.replace(/\n/g, ", ") : "none right now";
  }

  function pollDiag() {
    var attempts = 0;
    if (diagPolling) { clearInterval(diagPolling); }
    diagPolling = setInterval(function () {
      attempts++;
      fetch("/letsencrypt/diagnose/status", { cache: "no-store" })
        .then(function (r) { return r.json(); })
        .then(function (data) {
          if (data.state === "ok") {
            clearInterval(diagPolling);
            diagPolling = null;
            renderDiag(data);
          } else if (attempts >= 20) {
            clearInterval(diagPolling);
            diagPolling = null;
          }
        })
        .catch(function () {
          if (attempts >= 20) { clearInterval(diagPolling); diagPolling = null; }
        });
    }, 1000);
  }

  function runDiag() {
    fetch("/letsencrypt/diagnose/trigger", { method: "POST" })
      .then(pollDiag)
      .catch(function () {});
  }

  diagRefreshBtn.addEventListener("click", runDiag);

  function refreshLeStatus() {
    fetch("/metrics.json", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var entry = (data.services || []).filter(function (s) { return s.name === "letsencrypt"; })[0];
        var kind = entry ? entry.state : "disabled";
        setBadge(kind);
        if (kind === "warning") {
          diagBox.classList.remove("hidden");
          if (!diagAutoTriggered) {
            diagAutoTriggered = true;
            runDiag();
          }
        } else {
          diagBox.classList.add("hidden");
        }
      })
      .catch(function () {});
  }

  refreshLeStatus();
})();
</script>
