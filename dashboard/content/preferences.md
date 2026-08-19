---
title: System Preferences
---

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-network-panel">
    <span>Network</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-network-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
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
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-smtp-panel">
    <span>Email Settings</span>
    <svg class="accordion-chevron w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
  </button>
  <div id="accordion-smtp-panel" class="hidden border-t border-gray-200 dark:border-gray-700 p-4">
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  In order to send emails, we need to configure an SMTP server.<br>
  This system uses OpenSMTP which opens an email relay ONLY on localhost.
</p>
<p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
  Choose your email service, fill in the required information and click save
  or choose Custom / Other SMTP to set it up manually.
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
