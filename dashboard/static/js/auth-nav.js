(function () {
  var container = document.getElementById("auth-nav");
  if (!container) return;

  function setNavLinksVisible(visible) {
    var links = document.querySelectorAll("[data-nav-link]");
    for (var i = 0; i < links.length; i++) {
      var link = links[i];
      if (link.hasAttribute("data-nav-public")) continue;
      if (visible) {
        link.classList.remove("hidden");
      } else {
        link.classList.add("hidden");
      }
    }
  }

  function renderLoggedOut() {
    container.innerHTML =
      '<a href="/login/" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Login</a>';
  }

  function renderLoggedIn(info) {
    var items = "";
    if (info.isAdmin) {
      items +=
        '<a href="/preferences/" class="auth-nav-item">System Preferences</a>';
      items +=
        '<a href="/service-configuration/" class="auth-nav-item">Service Configuration</a>';
      items +=
        '<a href="/update/" class="auth-nav-item">System Update</a>';
    }
    items += '<a href="/account/" class="auth-nav-item">Manage Profile</a>';
    items += '<a href="/logout" class="auth-nav-item">Logout</a>';

    container.innerHTML =
      '<button id="auth-nav-toggle" type="button" class="auth-nav-button">' +
      (info.username || "Account") +
      ' <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>' +
      "</button>" +
      '<div id="auth-nav-dropdown" class="hidden auth-nav-dropdown bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm">' +
      items +
      "</div>";

    var toggle = document.getElementById("auth-nav-toggle");
    var dropdown = document.getElementById("auth-nav-dropdown");
    toggle.addEventListener("click", function (e) {
      e.stopPropagation();
      dropdown.classList.toggle("hidden");
    });
    document.addEventListener("click", function (e) {
      if (!container.contains(e.target)) {
        dropdown.classList.add("hidden");
      }
    });
  }

  fetch("/whoami", { cache: "no-store" })
    .then(function (res) {
      return res.json();
    })
    .then(function (info) {
      if (info && info.authenticated) {
        renderLoggedIn(info);
        setNavLinksVisible(true);
      } else {
        renderLoggedOut();
        setNavLinksVisible(false);
      }
    })
    .catch(function () {
      renderLoggedOut();
    });
})();
