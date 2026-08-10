(function () {
  var container = document.getElementById("update-banner");
  if (!container) return;

  // Admin-only, same gating as System Preferences/Service Configuration/
  // System Update in the account dropdown (auth-nav.js) — only admins can
  // actually act on this via /update/trigger, so only they see the nudge.
  fetch("/whoami", { cache: "no-store" })
    .then(function (res) { return res.json(); })
    .then(function (info) {
      if (!info || !info.authenticated || !info.isAdmin) { return; }
      // Same endpoint the System Update page itself polls — already does
      // a live GitHub check on every call, so no new backend work needed
      // here. One check per page load, matching auth-nav.js's own
      // one-shot-on-load style; nothing else on this site polls outside
      // an actively-open progress modal.
      return fetch("/update/status", { cache: "no-store" })
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (data) {
          if (!data || data.state || !data.updateAvailable) { return; }
          container.innerHTML =
            '<a href="/update/" class="block w-full text-center text-sm py-2 px-4 ' +
            'bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-300 ' +
            'border-b border-yellow-200 dark:border-yellow-800 hover:underline">' +
            "System Update Available &mdash; click to review &rarr;</a>";
          container.classList.remove("hidden");
        });
    })
    .catch(function () {});
})();
