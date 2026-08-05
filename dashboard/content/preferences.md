---
title: System Preferences
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Admin-only system settings. More will land here over time.
</p>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-update-panel">
    <span>Update</span>
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
  Mirrors mySystem.features in variables.nix. Preview only &mdash; toggling
  these doesn't change anything yet.
</p>
<div class="flex items-center justify-between py-2">
  <span class="text-sm text-gray-900 dark:text-white">Jellyfin</span>
  <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
</div>
<div class="flex items-center justify-between py-2">
  <span class="text-sm text-gray-900 dark:text-white">Frigate</span>
  <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
</div>
<div class="flex items-center justify-between py-2">
  <span class="text-sm text-gray-900 dark:text-white">MinIO</span>
  <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
</div>
<div class="flex items-center justify-between py-2">
  <span class="text-sm text-gray-900 dark:text-white">FileBrowser</span>
  <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
</div>
<div class="flex items-center justify-between py-2">
  <span class="text-sm font-medium text-gray-900 dark:text-white">SSO</span>
  <label class="switch"><input type="checkbox" checked data-group-toggle="sso"><span class="slider"></span></label>
</div>
<div class="pl-6 space-y-2 mb-2" data-group="sso">
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">Authelia</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
</div>
<div class="flex items-center justify-between py-2">
  <span class="text-sm font-medium text-gray-900 dark:text-white">Home Assistant</span>
  <label class="switch"><input type="checkbox" checked data-group-toggle="homeassistant"><span class="slider"></span></label>
</div>
<div class="pl-6 space-y-2 mb-2" data-group="homeassistant">
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">Z-Wave</span>
    <label class="switch"><input type="checkbox"><span class="slider"></span></label>
  </div>
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">HACS</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
</div>
<div class="flex items-center justify-between py-2">
  <span class="text-sm font-medium text-gray-900 dark:text-white">Media Acquisition</span>
  <label class="switch"><input type="checkbox" checked data-group-toggle="mediaacquisition"><span class="slider"></span></label>
</div>
<div class="pl-6 space-y-2 mb-2" data-group="mediaacquisition">
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">Seerr</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">Radarr</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">Sonarr</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">Jackett</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
  <div class="flex items-center justify-between py-2">
    <span class="text-sm text-gray-700 dark:text-gray-300">qBittorrent</span>
    <label class="switch"><input type="checkbox" checked><span class="slider"></span></label>
  </div>
</div>
  </div>
</div>

<div class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm mb-4">
  <button type="button" class="accordion-toggle w-full flex items-center justify-between p-4 text-left font-semibold text-gray-900 dark:text-white" data-accordion-target="accordion-smtp-panel">
    <span>SMTP</span>
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
  // again, and reopened the modal a moment after Close was clicked.
  var lastRenderedTerminal = null;

  function applyProgress(data) {
    var terminal = data.state === "success" || data.state === "failed";
    if (terminal && lastRenderedTerminal === data.state) {
      return;
    }
    if (!terminal) {
      lastRenderedTerminal = null;
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

  cancelBtn.addEventListener("click", closeModal);
  modalCloseX.addEventListener("click", closeModal);
  modalCloseBtn.addEventListener("click", closeModal);

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
