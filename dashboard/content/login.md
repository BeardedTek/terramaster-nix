---
title: Login
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Sign in with your NAS account (the same username and password used
  everywhere else on this NAS) to view the rest of this dashboard.
</p>

<div class="max-w-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-sm p-6 mb-8">
  <label for="login-username" class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Username</label>
  <input type="text" id="login-username" autocomplete="username" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white mb-4" />

  <label for="login-password" class="block mb-2 text-sm font-medium text-gray-900 dark:text-white">Password</label>
  <input type="password" id="login-password" autocomplete="current-password" class="bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white mb-4" />

  <div id="login-message" class="mb-4 text-sm text-red-600 dark:text-red-400 hidden"></div>

  <button id="login-btn" type="button" class="text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800">Login</button>
</div>

<script>
(function () {
  var usernameEl = document.getElementById("login-username");
  var passwordEl = document.getElementById("login-password");
  var messageEl = document.getElementById("login-message");
  var loginBtn = document.getElementById("login-btn");

  function showError(text) {
    messageEl.textContent = text;
    messageEl.classList.remove("hidden");
  }

  function attemptLogin() {
    messageEl.classList.add("hidden");
    loginBtn.disabled = true;

    fetch("/login/submit", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: usernameEl.value, password: passwordEl.value })
    })
      .then(function (res) {
        if (res.ok) {
          window.location.href = "/";
          return;
        }
        loginBtn.disabled = false;
        showError("Incorrect username or password.");
      })
      .catch(function () {
        loginBtn.disabled = false;
        showError("Something went wrong reaching the server. Try again.");
      });
  }

  loginBtn.addEventListener("click", attemptLogin);
  passwordEl.addEventListener("keydown", function (e) {
    if (e.key === "Enter") attemptLogin();
  });
})();
</script>
