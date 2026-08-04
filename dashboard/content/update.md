---
title: Update
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  The current and latest available version are always shown below to
  anyone who can reach this dashboard. Actually applying an update &mdash;
  fetching the new release and rebuilding the system in place &mdash;
  needs the admin password. Ask whoever manages this NAS if you don't
  have it.
</p>

<div class="max-w-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm p-6 mb-8">
  <label for="admin-password" class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Admin password</label>
  <input type="password" id="admin-password" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white mb-4" placeholder="Only needed to apply an update" />

  <div id="update-info" class="mb-4 text-sm text-gray-700 dark:text-gray-300">
    <p>Current version: <span id="current-version" class="font-mono">&mdash;</span></p>
    <p>Latest release: <span id="latest-version" class="font-mono">&mdash;</span> <a id="release-link" href="#" target="_blank" rel="noopener noreferrer" class="text-primary-700 dark:text-primary-500 hover:underline hidden">(notes)</a></p>
  </div>

  <div id="update-message" class="mb-4 text-sm hidden"></div>

  <button id="check-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 mr-2 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Check for updates</button>
  <button id="update-btn" type="button" disabled class="text-white bg-gray-400 cursor-not-allowed font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-gray-600">Update now</button>
</div>

<!-- Modal -->
<div id="update-modal" class="hidden fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
  <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto p-6 relative">
    <button id="modal-close-x" type="button" class="hidden absolute top-4 right-4 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200" aria-label="Close">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
    </button>

    <!-- Confirm view -->
    <div id="modal-confirm-view">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Apply update?</h3>
      <p class="text-sm text-gray-700 dark:text-gray-300 mb-6">
        This fetches <span id="modal-confirm-version" class="font-mono"></span> and rebuilds the system
        in place. It can take several minutes, and services may briefly
        restart as part of activation.
      </p>
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
        <svg id="modal-icon-failed" class="hidden w-6 h-6 text-red-600 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
        <span id="modal-status-text" class="text-sm text-gray-700 dark:text-gray-300">Starting...</span>
      </div>

      <button id="log-toggle-btn" type="button" class="flex items-center gap-1 text-sm text-primary-700 dark:text-primary-500 hover:underline mb-2">
        <svg id="log-toggle-chevron" class="w-4 h-4 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        <span>Show details</span>
      </button>
      <div id="log-panel" class="hidden">
        <div id="log-stages" class="text-xs text-gray-600 dark:text-gray-400 mb-2 space-y-0.5"></div>
        <pre id="log-build" class="bg-gray-900 text-gray-100 text-xs p-3 rounded-lg max-h-64 overflow-y-auto whitespace-pre-wrap break-all"></pre>
      </div>

      <div class="flex justify-end mt-4">
        <button id="modal-close-btn" type="button" class="hidden text-white bg-primary-700 hover:bg-primary-800 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
(function () {
  var passwordEl = document.getElementById("admin-password");
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

  function authHeader() {
    return "Basic " + btoa("admin:" + passwordEl.value);
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
  }

  function applyProgress(data) {
    showProgressView();
    setTerminalIcon(data.state);
    statusTextEl.textContent = data.message || data.state;
    renderLog(data);

    if (data.state === "success") {
      stopPolling();
      checkNow();
    } else if (data.state === "failed") {
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
    if (!passwordEl.value) {
      showMessage("Enter the admin password first.", "error");
      return;
    }
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
    showProgressView();
    setTerminalIcon("running");
    statusTextEl.textContent = "Starting...";
    logStagesEl.innerHTML = "";
    logBuildEl.textContent = "";
    setUpdateEnabled(false);

    fetch("/update/trigger", { method: "POST", headers: { Authorization: authHeader() } })
      .then(function (r) {
        if (r.status === 401) { throw new Error("Wrong password."); }
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
