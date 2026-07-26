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

<script>
(function () {
  var passwordEl = document.getElementById("admin-password");
  var currentEl = document.getElementById("current-version");
  var latestEl = document.getElementById("latest-version");
  var releaseLinkEl = document.getElementById("release-link");
  var messageEl = document.getElementById("update-message");
  var checkBtn = document.getElementById("check-btn");
  var updateBtn = document.getElementById("update-btn");

  var polling = null;

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

  function applyProgress(data) {
    if (data.state === "running") {
      showMessage(data.message || "Update in progress...", "info");
    } else if (data.state === "success") {
      showMessage(data.message || "Update complete.", "success");
      stopPolling();
      checkNow();
    } else if (data.state === "failed") {
      showMessage(data.message || "Update failed.", "error");
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
            polling = setInterval(checkNow, 4000);
          }
          return;
        }
        currentEl.textContent = data.current || "unknown";
        if (data.error) {
          showMessage(data.error, "error");
          return;
        }
        latestEl.textContent = data.latest || "unknown";
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
    if (!confirm("This rebuilds the system in place. It can take several minutes and services may briefly restart. Continue?")) {
      return;
    }
    setUpdateEnabled(false);
    showMessage("Starting update...", "info");
    fetch("/update/trigger", { method: "POST", headers: { Authorization: authHeader() } })
      .then(function (r) {
        if (r.status === 401) { throw new Error("Wrong password."); }
        if (!r.ok) { throw new Error("Could not start the update."); }
        polling = setInterval(checkNow, 4000);
        checkNow();
      })
      .catch(function (err) {
        showMessage(err.message || "Could not start the update.", "error");
        setUpdateEnabled(true);
      });
  });

  checkNow();
})();
</script>
