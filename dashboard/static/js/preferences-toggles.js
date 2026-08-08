(function () {
  // Group toggles: a checkbox with data-group-toggle="name" enables or
  // disables (and dims) every input inside the [data-group="name"]
  // wrapper. Pure client-side preview — nothing here is persisted or
  // wired to a real backend yet.
  document.querySelectorAll("[data-group-toggle]").forEach(function (toggle) {
    var name = toggle.getAttribute("data-group-toggle");
    var wrapper = document.querySelector('[data-group="' + name + '"]');
    if (!wrapper) return;

    function sync() {
      wrapper.querySelectorAll("input, textarea, select").forEach(function (input) {
        input.disabled = !toggle.checked;
      });
      wrapper.classList.toggle("preferences-dimmed", !toggle.checked);
    }

    toggle.addEventListener("change", sync);
    sync();
  });

  // Mode toggles: a radio group sharing data-mode-toggle="name" shows
  // which [data-mode="name:value"] block is active, disabling (and
  // dimming) the inputs in every other block sharing that name.
  var modeNames = {};
  document.querySelectorAll("input[data-mode-toggle]").forEach(function (radio) {
    modeNames[radio.getAttribute("data-mode-toggle")] = true;
    radio.addEventListener("change", function () {
      syncMode(radio.getAttribute("data-mode-toggle"));
    });
  });

  function syncMode(name) {
    var checked = document.querySelector('input[data-mode-toggle="' + name + '"]:checked');
    var activeValue = checked ? checked.value : null;
    document.querySelectorAll('[data-mode^="' + name + ':"]').forEach(function (block) {
      var value = block.getAttribute("data-mode").slice(name.length + 1);
      var active = value === activeValue;
      block.querySelectorAll("input").forEach(function (input) {
        input.disabled = !active;
      });
      block.classList.toggle("preferences-dimmed", !active);
    });
  }

  Object.keys(modeNames).forEach(syncMode);
})();
