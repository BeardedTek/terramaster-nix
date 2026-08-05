---
title: Account
---

<p class="text-gray-700 dark:text-gray-300 mb-4 leading-relaxed">
  Account management (changing your own password, and for admins,
  managing users) happens in LLDAP's own admin interface, not here.
  It's LAN-only by design, reachable at the same address as this
  dashboard but on port <span class="font-mono">17170</span>.
</p>

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Redirecting you there now &mdash; if it doesn't work (for example, if
  you're viewing this dashboard over the mesh network rather than the
  local network), use the link below instead.
</p>

<a id="lldap-link" href="#" class="text-primary-700 dark:text-primary-500 hover:underline font-mono"></a>

<script>
(function () {
  var url = "http://" + window.location.hostname + ":17170";
  var link = document.getElementById("lldap-link");
  link.href = url;
  link.textContent = url;
  window.location.href = url;
})();
</script>
