(function () {
  document.querySelectorAll("[data-accordion-target]").forEach(function (toggle) {
    var panel = document.getElementById(toggle.getAttribute("data-accordion-target"));
    var chevron = toggle.querySelector(".accordion-chevron");
    if (!panel) return;
    toggle.addEventListener("click", function () {
      var nowHidden = panel.classList.toggle("hidden");
      if (chevron) chevron.style.transform = nowHidden ? "" : "rotate(180deg)";
    });
  });
})();
