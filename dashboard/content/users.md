---
title: Users
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Add, remove, and modify the accounts on this NAS, and reset passwords.
  Admin (wheel) users can sudo and see these same admin pages.
</p>

<div id="users-message" class="mb-4 text-sm hidden"></div>

<div class="overflow-x-auto mb-8">
  <table class="w-full text-sm text-left text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 rounded-lg">
    <thead class="text-xs uppercase bg-gray-50 dark:bg-gray-800 text-gray-500 dark:text-gray-400">
      <tr>
        <th class="px-4 py-3">Username</th>
        <th class="px-4 py-3">Admin</th>
        <th class="px-4 py-3"></th>
      </tr>
    </thead>
    <tbody id="users-table-body">
      <tr><td class="px-4 py-3" colspan="3">Loading&hellip;</td></tr>
    </tbody>
  </table>
</div>

<div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-8">
  <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-3">Add a user</h3>
  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-3">
    <div>
      <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Username</span>
      <input type="text" id="users-add-name" placeholder="lowercase, no spaces" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
    </div>
    <div class="flex items-end pb-2">
      <label class="switch mr-2"><input type="checkbox" id="users-add-wheel"><span class="slider"></span></label>
      <span class="text-sm font-medium text-gray-900 dark:text-white">Admin (sudo) access</span>
    </div>
    <div>
      <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Password</span>
      <input type="password" id="users-add-password" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
    </div>
    <div>
      <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Confirm password</span>
      <input type="password" id="users-add-password-confirm" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
    </div>
  </div>
  <button id="users-add-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Add User</button>
  <p class="text-xs text-gray-500 dark:text-gray-400 mt-3">
    Adding a user rebuilds the system in place (like Service
    Configuration's own checkboxes) &mdash; this can take several
    minutes. The new account becomes available for console/SMB login,
    SSO/web login, and Samba file shares once it finishes.
  </p>
</div>

<!-- Add/modify/remove modal — same confirm-then-progress shape as
     Service Configuration's own modal, since this goes through the same
     shared rebuild runner (modules/system-rebuild.nix, kind: "users"). -->
<div id="users-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="users-modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <div id="users-modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply this change?</h3>
      <p id="users-modal-summary" class="text-sm text-gray-700 dark:text-gray-300 mb-6"></p>
      <div class="flex justify-end gap-2">
        <button id="users-modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="users-modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Apply</button>
      </div>
    </div>
    <div id="users-modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Applying changes</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="users-modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="users-modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="users-modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="users-modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="users-step-list" class="text-sm mb-4">
        <li class="update-step" data-users-step="download"><span class="update-step-icon" data-users-step-icon="download">&#9675;</span>Downloading release</li>
        <li class="update-step" data-users-step="rebuild"><span class="update-step-icon" data-users-step-icon="rebuild">&#9675;</span>Rebuilding<ul id="users-derivations-list" class="update-derivations-list hidden"></ul></li>
        <li class="update-step" data-users-step="inhibitors"><span class="update-step-icon" data-users-step-icon="inhibitors">&#9675;</span>Check switch inhibitors</li>
        <li class="update-step" data-users-step="activate"><span class="update-step-icon" data-users-step-icon="activate">&#9675;</span>Activate configuration</li>
        <li class="update-step" data-users-step="etc"><span class="update-step-icon" data-users-step-icon="etc">&#9675;</span>Setting up /etc</li>
        <li class="update-step" data-users-step="reload"><span class="update-step-icon" data-users-step-icon="reload">&#9675;</span>Reloading &amp; restarting units</li>
        <li class="update-step" data-users-step="done"><span class="update-step-icon" data-users-step-icon="done">&#9675;</span>Done</li>
      </ul>
      <button id="users-log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="users-log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="users-log-panel" class="hidden">
        <div id="users-log-stages" class="text-xs update-log-stages mb-2"></div>
        <pre id="users-log-build" class="update-log-output text-xs p-3 rounded-lg overflow-y-auto"></pre>
      </div>
      <div class="flex justify-end mt-4">
        <button id="users-modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Reset-password modal — synchronous (Unix + LLDAP + Samba, no
     rebuild), so this is a much simpler spinner-then-result flow than
     the modal above. -->
<div id="reset-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center update-modal-overlay p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl update-modal-panel w-full overflow-y-auto p-6 relative">
    <button id="reset-modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>
    <div id="reset-modal-form-view">
      <h3 id="reset-modal-title" class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Reset password</h3>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-3">
        Resets the console/PAM (Unix), SSO/web (LLDAP), and Samba
        passwords together, to the same new password.
      </p>
      <div class="grid grid-cols-1 gap-4 mb-3">
        <div>
          <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">New password</span>
          <input type="password" id="reset-password" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
        </div>
        <div>
          <span class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Confirm new password</span>
          <input type="password" id="reset-password-confirm" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white" />
        </div>
      </div>
      <div id="reset-modal-message" class="mb-4 text-sm hidden"></div>
      <div class="flex justify-end gap-2">
        <button id="reset-modal-cancel-btn" type="button" class="text-gray-700 bg-white border border-gray-300 hover:bg-gray-100 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-700 dark:text-white dark:border-gray-600 dark:hover:bg-gray-600">Cancel</button>
        <button id="reset-modal-confirm-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Reset Password</button>
      </div>
    </div>
    <div id="reset-modal-progress-view" class="hidden">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Resetting password</h3>
      <div class="flex items-center gap-3 mb-4">
        <div id="reset-modal-spinner" class="animate-spin rounded-full h-6 w-6 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600 shrink-0"></div>
        <svg id="reset-modal-icon-success" class="hidden w-6 h-6 text-green-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <svg id="reset-modal-icon-failed" class="hidden w-6 h-6 update-icon-failed shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="reset-modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>
      <ul id="reset-modal-result-list" class="text-sm mb-4"></ul>
      <div class="flex justify-end mt-4">
        <button id="reset-modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
(function () {
  var tableBody = document.getElementById("users-table-body");
  var messageEl = document.getElementById("users-message");
  var addNameInput = document.getElementById("users-add-name");
  var addWheelInput = document.getElementById("users-add-wheel");
  var addPasswordInput = document.getElementById("users-add-password");
  var addPasswordConfirmInput = document.getElementById("users-add-password-confirm");
  var addBtn = document.getElementById("users-add-btn");

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

  // ---- Add/modify/remove modal (rebuild-driven) ----

  var modal = document.getElementById("users-modal");
  var modalCloseX = document.getElementById("users-modal-close-x");
  var confirmView = document.getElementById("users-modal-confirm-view");
  var progressView = document.getElementById("users-modal-progress-view");
  var summaryEl = document.getElementById("users-modal-summary");
  var cancelBtn = document.getElementById("users-modal-cancel-btn");
  var confirmBtn = document.getElementById("users-modal-confirm-btn");
  var spinnerEl = document.getElementById("users-modal-spinner");
  var iconSuccessEl = document.getElementById("users-modal-icon-success");
  var iconFailedEl = document.getElementById("users-modal-icon-failed");
  var statusTextEl = document.getElementById("users-modal-status-text");
  var logToggleBtn = document.getElementById("users-log-toggle-btn");
  var logToggleChevron = document.getElementById("users-log-toggle-chevron");
  var logPanel = document.getElementById("users-log-panel");
  var logStagesEl = document.getElementById("users-log-stages");
  var logBuildEl = document.getElementById("users-log-build");
  var modalCloseBtn = document.getElementById("users-modal-close-btn");

  var pendingRequest = null;

  function showConfirmView(summary) {
    summaryEl.textContent = summary;
    confirmView.classList.remove("hidden");
    progressView.classList.add("hidden");
    modalCloseX.classList.add("hidden");
    modal.classList.remove("hidden");
  }
  function showProgressView() {
    confirmView.classList.add("hidden");
    progressView.classList.remove("hidden");
    modal.classList.remove("hidden");
  }
  function closeModal() {
    modal.classList.add("hidden");
    pendingRequest = null;
  }
  function setTerminalIcon(state) {
    spinnerEl.classList.toggle("hidden", state !== "running");
    iconSuccessEl.classList.toggle("hidden", state !== "success");
    iconFailedEl.classList.toggle("hidden", state !== "failed");
    modalCloseBtn.classList.toggle("hidden", state === "running");
    modalCloseX.classList.toggle("hidden", state === "running");
  }

  var STEPS = [
    { key: "download", re: /rebuilding|activating|setting up .etc|reloading|restarting|done\. the new configuration/i },
    { key: "rebuild", re: /activating the configuration|setting up .etc|reloading|restarting|done\. the new configuration/i },
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
      var li = document.querySelector('[data-users-step="' + step.key + '"]');
      var icon = document.querySelector('[data-users-step-icon="' + step.key + '"]');
      if (!li || !icon) { return; }
      li.classList.toggle("update-step-done", isDone);
      icon.innerHTML = isDone ? "&#10003;" : "&#9675;";
    });

    var derivationsList = document.getElementById("users-derivations-list");
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
    renderSteps(data);
  }

  var polling = null;
  function stopPolling() {
    if (polling) { clearInterval(polling); polling = null; }
  }

  function poll() {
    fetch("/preferences/users/status", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        showProgressView();
        setTerminalIcon(data.state);
        statusTextEl.textContent = data.message || data.state;
        renderLog(data);
        if (data.state === "success") {
          stopPolling();
          loadUsers();
        } else if (data.state === "failed") {
          stopPolling();
        }
      })
      .catch(function () { /* try again on next tick */ });
  }

  cancelBtn.addEventListener("click", closeModal);
  modalCloseX.addEventListener("click", closeModal);
  modalCloseBtn.addEventListener("click", closeModal);

  logToggleBtn.addEventListener("click", function () {
    var hidden = logPanel.classList.toggle("hidden");
    logToggleChevron.style.transform = hidden ? "" : "rotate(180deg)";
    logToggleBtn.querySelector("span").textContent = hidden ? "Show details" : "Hide details";
  });

  confirmBtn.addEventListener("click", function () {
    if (!pendingRequest) { return; }
    showProgressView();
    setTerminalIcon("running");
    statusTextEl.textContent = "Starting...";
    logStagesEl.innerHTML = "";
    logBuildEl.textContent = "";
    document.getElementById("users-derivations-list").classList.add("hidden");
    renderSteps({ log: [], buildLog: "", state: "running" });

    fetch("/preferences/users/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(pendingRequest)
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

  function confirmAction(request, summary) {
    hideMessage();
    pendingRequest = request;
    showConfirmView(summary);
  }

  // ---- Reset-password modal (synchronous) ----

  var resetModal = document.getElementById("reset-modal");
  var resetModalCloseX = document.getElementById("reset-modal-close-x");
  var resetFormView = document.getElementById("reset-modal-form-view");
  var resetProgressView = document.getElementById("reset-modal-progress-view");
  var resetTitle = document.getElementById("reset-modal-title");
  var resetPasswordInput = document.getElementById("reset-password");
  var resetPasswordConfirmInput = document.getElementById("reset-password-confirm");
  var resetMessageEl = document.getElementById("reset-modal-message");
  var resetCancelBtn = document.getElementById("reset-modal-cancel-btn");
  var resetConfirmBtn = document.getElementById("reset-modal-confirm-btn");
  var resetSpinnerEl = document.getElementById("reset-modal-spinner");
  var resetIconSuccessEl = document.getElementById("reset-modal-icon-success");
  var resetIconFailedEl = document.getElementById("reset-modal-icon-failed");
  var resetStatusTextEl = document.getElementById("reset-modal-status-text");
  var resetResultListEl = document.getElementById("reset-modal-result-list");
  var resetCloseBtn = document.getElementById("reset-modal-close-btn");

  var resetTargetName = null;

  function showResetMessage(text) {
    resetMessageEl.textContent = text;
    resetMessageEl.classList.remove("hidden");
    resetMessageEl.className = "mb-4 text-sm rounded-lg p-3 bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300";
  }

  function openResetModal(name) {
    resetTargetName = name;
    resetTitle.textContent = "Reset password for \"" + name + "\"";
    resetPasswordInput.value = "";
    resetPasswordConfirmInput.value = "";
    resetMessageEl.classList.add("hidden");
    resetFormView.classList.remove("hidden");
    resetProgressView.classList.add("hidden");
    resetModalCloseX.classList.add("hidden");
    resetModal.classList.remove("hidden");
  }
  function closeResetModal() {
    resetModal.classList.add("hidden");
    resetTargetName = null;
  }

  resetCancelBtn.addEventListener("click", closeResetModal);
  resetModalCloseX.addEventListener("click", closeResetModal);
  resetCloseBtn.addEventListener("click", closeResetModal);

  function resetPoll() {
    fetch("/preferences/users/status", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (!data.unix && !data.lldap && !data.samba && data.state !== "success" && data.state !== "failed") {
          // Still running (either flow) — keep waiting.
          return;
        }
        clearInterval(resetPolling);
        resetPolling = null;
        var success = data.state === "success";
        resetSpinnerEl.classList.add("hidden");
        resetIconSuccessEl.classList.toggle("hidden", !success);
        resetIconFailedEl.classList.toggle("hidden", success);
        resetStatusTextEl.textContent = data.message || (success ? "Password reset." : "Reset failed.");
        resetCloseBtn.classList.remove("hidden");
        resetModalCloseX.classList.remove("hidden");
        resetResultListEl.innerHTML = "";
        [["Console / SMB login (Unix)", data.unix], ["SSO / web login (LLDAP)", data.lldap], ["Samba file shares", data.samba]].forEach(function (pair) {
          if (!pair[1]) { return; }
          var li = document.createElement("li");
          li.textContent = pair[0] + ": " + (pair[1] === "ok" ? "OK" : pair[1]);
          resetResultListEl.appendChild(li);
        });
        if (success) { loadUsers(); }
      })
      .catch(function () { /* try again on next tick */ });
  }
  var resetPolling = null;

  resetConfirmBtn.addEventListener("click", function () {
    if (!resetTargetName) { return; }
    var pw = resetPasswordInput.value;
    var pw2 = resetPasswordConfirmInput.value;
    if (!pw) { showResetMessage("Enter a new password."); return; }
    if (pw !== pw2) { showResetMessage("Passwords don't match."); return; }

    resetFormView.classList.add("hidden");
    resetProgressView.classList.remove("hidden");
    resetSpinnerEl.classList.remove("hidden");
    resetIconSuccessEl.classList.add("hidden");
    resetIconFailedEl.classList.add("hidden");
    resetStatusTextEl.textContent = "Resetting...";
    resetResultListEl.innerHTML = "";
    resetCloseBtn.classList.add("hidden");

    fetch("/preferences/users/reset-password", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: resetTargetName, password: pw })
    })
      .then(function (r) {
        return r.json().then(function (data) { return { ok: r.ok, data: data }; });
      })
      .then(function (result) {
        if (!result.ok) {
          throw new Error((result.data && result.data.error) || "Reset failed.");
        }
        resetPolling = setInterval(resetPoll, 2000);
        resetPoll();
      })
      .catch(function (err) {
        resetSpinnerEl.classList.add("hidden");
        resetIconFailedEl.classList.remove("hidden");
        resetStatusTextEl.textContent = err.message || "Could not reset password.";
        resetCloseBtn.classList.remove("hidden");
        resetModalCloseX.classList.remove("hidden");
      });
  });

  // ---- Table + add form ----

  function loadUsers() {
    fetch("/preferences/users/current", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var users = data.users || [];
        tableBody.innerHTML = "";
        users.forEach(function (u) {
          var tr = document.createElement("tr");
          tr.className = "border-t border-gray-200 dark:border-gray-700";

          var nameTd = document.createElement("td");
          nameTd.className = "px-4 py-3 font-medium text-gray-900 dark:text-white";
          nameTd.textContent = u.name;
          tr.appendChild(nameTd);

          var wheelTd = document.createElement("td");
          wheelTd.className = "px-4 py-3";
          var label = document.createElement("label");
          label.className = "switch";
          var checkbox = document.createElement("input");
          checkbox.type = "checkbox";
          checkbox.checked = !!u.wheel;
          checkbox.addEventListener("change", function () {
            var newWheel = checkbox.checked;
            confirmAction(
              { action: "modify", name: u.name, wheel: newWheel },
              (newWheel ? "Grant" : "Remove") + " admin (sudo) access " + (newWheel ? "to" : "from") + " \"" + u.name + "\"."
            );
            // Revert the visible switch until the change is actually
            // confirmed+applied — loadUsers() re-renders it correctly
            // either way once the modal resolves or is cancelled.
            checkbox.checked = !newWheel;
          });
          var slider = document.createElement("span");
          slider.className = "slider";
          label.appendChild(checkbox);
          label.appendChild(slider);
          wheelTd.appendChild(label);
          tr.appendChild(wheelTd);

          var actionsTd = document.createElement("td");
          actionsTd.className = "px-4 py-3 text-right";
          var resetBtn = document.createElement("button");
          resetBtn.type = "button";
          resetBtn.className = "text-primary-700 dark:text-primary-500 hover:underline text-sm mr-4";
          resetBtn.textContent = "Reset Password";
          resetBtn.addEventListener("click", function () { openResetModal(u.name); });
          actionsTd.appendChild(resetBtn);
          var removeBtn = document.createElement("button");
          removeBtn.type = "button";
          removeBtn.className = "text-red-700 dark:text-red-500 hover:underline text-sm";
          removeBtn.textContent = "Remove";
          removeBtn.addEventListener("click", function () {
            confirmAction(
              { action: "remove", name: u.name },
              "Remove \"" + u.name + "\" from managed users. Their existing Unix, LLDAP, and Samba accounts are not deleted — this only stops managing them here."
            );
          });
          actionsTd.appendChild(removeBtn);
          tr.appendChild(actionsTd);

          tableBody.appendChild(tr);
        });
        if (users.length === 0) {
          tableBody.innerHTML = '<tr><td class="px-4 py-3" colspan="3">No users yet.</td></tr>';
        }
      })
      .catch(function () {
        tableBody.innerHTML = '<tr><td class="px-4 py-3" colspan="3">Could not load users.</td></tr>';
      });
  }
  loadUsers();

  addBtn.addEventListener("click", function () {
    hideMessage();
    var name = addNameInput.value.trim();
    var wheel = addWheelInput.checked;
    var pw = addPasswordInput.value;
    var pw2 = addPasswordConfirmInput.value;
    if (!/^[a-z_][a-z0-9_-]*$/.test(name)) {
      showMessage("Enter a valid lowercase username (letters, numbers, - and _ only).", "error");
      return;
    }
    if (!pw) { showMessage("Enter a password.", "error"); return; }
    if (pw !== pw2) { showMessage("Passwords don't match.", "error"); return; }

    confirmAction(
      { action: "add", name: name, wheel: wheel, password: pw },
      "Add user \"" + name + "\"" + (wheel ? " with admin (sudo) access." : ".")
    );
  });
})();
</script>
