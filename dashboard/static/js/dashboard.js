(function () {
  "use strict";

  function setText(el, text) {
    if (el) el.textContent = text;
  }

  function renderDisks(disks) {
    (disks || []).forEach(function (d) {
      var card = document.querySelector('[data-disk="' + d.name + '"]');
      if (!card) return;
      setText(card.querySelector(".disk-pct"), d.pct + "% used");
      setText(
        card.querySelector(".disk-detail"),
        d.used + " used / " + d.avail + " free / " + d.total + " total"
      );
      var bar = card.querySelector(".disk-bar");
      if (bar) bar.style.width = Math.min(d.pct, 100) + "%";
    });
  }

  function renderLoad(load) {
    var el = document.getElementById("load-widget");
    if (!el || !load) return;
    el.textContent =
      load.one + " (1m)  ·  " + load.five + " (5m)  ·  " + load.fifteen + " (15m)";
  }

  function renderMemory(mem) {
    var el = document.getElementById("memory-widget");
    if (!el || !mem) return;
    el.textContent = mem.used + " used of " + mem.total + " (" + mem.pct + "%)";
  }

  function renderNetwork(network) {
    (network || []).forEach(function (n) {
      var card = document.querySelector('[data-iface="' + n.iface + '"]');
      if (!card) return;
      var status = card.querySelector(".net-status");
      if (status) {
        status.textContent = n.up ? "up" : "down";
        status.className =
          "net-status text-sm px-2 py-0.5 rounded " +
          (n.up
            ? "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300"
            : "bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-300");
      }
      setText(card.querySelector(".net-ip"), n.ip || "no address");
    });
  }

  function refresh() {
    fetch("/metrics.json", { cache: "no-store" })
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        renderDisks(data.disks);
        renderLoad(data.load);
        renderMemory(data.memory);
        renderNetwork(data.network);
        setText(
          document.getElementById("metrics-updated"),
          new Date(data.generated_at).toLocaleTimeString()
        );
      })
      .catch(function () {
        setText(document.getElementById("metrics-updated"), "unavailable");
      });
  }

  refresh();
  setInterval(refresh, 30000);
})();
