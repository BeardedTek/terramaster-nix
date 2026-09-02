---
title: Bearded NAS
description: A NixOS based Distribution for Low Powered NAS Devices
params:
  body_class: td-navbar-links-all-active
---

{{% blocks/cover height="auto td-below-navbar" image_anchor="top" color="dark" %}}

{{% param "description" %}}
{.display-6}

<div class="nas-gallery" id="nas-gallery">
  <div class="nas-gallery-stage" id="nas-gallery-stage" role="button" tabindex="0" aria-label="Expand screenshot">
    <img class="nas-gallery-img is-active" src="/terramaster-nix/images/webui/01-dashboard-public.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/webui/03-dashboard-loggedin.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/webui/04-services.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/webui/05-preferences.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/webui/06-users.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/webui/08-service-configuration.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/installer/01-welcome.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/installer/19-services.png" alt="">
    <img class="nas-gallery-img" src="/terramaster-nix/images/installer/27-installing.png" alt="">
  </div>
  <div class="nas-gallery-caption">
    <h3 class="nas-gallery-title"></h3>
    <p class="nas-gallery-desc"></p>
  </div>
  <div class="nas-gallery-thumbs">
    <button class="nas-gallery-thumb is-active" data-index="0" aria-label="Dashboard">
      <img src="/terramaster-nix/images/webui/01-dashboard-public.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="1" aria-label="Dashboard, logged in">
      <img src="/terramaster-nix/images/webui/03-dashboard-loggedin.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="2" aria-label="Services">
      <img src="/terramaster-nix/images/webui/04-services.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="3" aria-label="System Preferences">
      <img src="/terramaster-nix/images/webui/05-preferences.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="4" aria-label="Users">
      <img src="/terramaster-nix/images/webui/06-users.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="5" aria-label="Service Configuration">
      <img src="/terramaster-nix/images/webui/08-service-configuration.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="6" aria-label="Installer welcome">
      <img src="/terramaster-nix/images/installer/01-welcome.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="7" aria-label="Installer services">
      <img src="/terramaster-nix/images/installer/19-services.png" alt="">
    </button>
    <button class="nas-gallery-thumb" data-index="8" aria-label="Installer installing">
      <img src="/terramaster-nix/images/installer/27-installing.png" alt="">
    </button>
  </div>
</div>

<div class="nas-gallery-modal" id="nas-gallery-modal">
  <button class="nas-gallery-modal-close" id="nas-gallery-modal-close" aria-label="Close">&times;</button>
  <img class="nas-gallery-modal-img" id="nas-gallery-modal-img" src="" alt="">
</div>

<a class="btn btn-lg btn-primary me-3 mb-4" href="/docs/">
  Documentation <i class="fa-solid fa-book ms-2"></i>
</a>
<a class="btn btn-lg btn-primary me-3 mb-4" href="https://github.com/BeardedTek/terramaster-nix/releases">
  Download installer ISO <i class="fa-solid fa-compact-disc ms-2"></i>
</a>
<a class="btn btn-lg btn-secondary me-3 mb-4" href="https://github.com/BeardedTek/terramaster-nix">
  Get the code <i class="fab fa-github ms-2"></i>
</a>

{{% /blocks/cover %}}

<style>
#td-cover-block-0 {
  padding-top: 5rem !important;
}
.nas-gallery {
  max-width: 675px;
  margin: 0 auto;
  padding: 1rem 1rem 0;
}
.nas-gallery-stage {
  position: relative;
  width: 100%;
  aspect-ratio: 1280 / 800;
  border-radius: 0.5rem;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.15);
  box-shadow: 0 0.5rem 1.5rem rgba(0, 0, 0, 0.35);
  background: rgba(255, 255, 255, 0.05);
  cursor: zoom-in;
}
.nas-gallery-modal {
  display: none;
  position: fixed;
  inset: 0;
  z-index: 1080;
  background: rgba(0, 0, 0, 0.85);
  align-items: center;
  justify-content: center;
}
.nas-gallery-modal.is-open {
  display: flex;
}
.nas-gallery-modal-img {
  max-width: 90vw;
  max-height: 90vh;
  object-fit: contain;
  border-radius: 0.25rem;
  box-shadow: 0 1rem 3rem rgba(0, 0, 0, 0.5);
}
.nas-gallery-modal-close {
  position: absolute;
  top: 1.5rem;
  right: 1.5rem;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  border: none;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  font-size: 1.75rem;
  line-height: 1;
  cursor: pointer;
}
.nas-gallery-modal-close:hover {
  background: rgba(255, 255, 255, 0.25);
}
.nas-gallery-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  opacity: 0;
  transition: opacity 0.6s ease;
}
.nas-gallery-img.is-active {
  opacity: 1;
}
.nas-gallery-caption {
  text-align: center;
  min-height: 4.5rem;
  padding: 1rem 1rem 0;
}
.nas-gallery-title {
  font-size: 1.15rem;
  font-weight: 700;
  margin-bottom: 0.25rem;
  color: #fff;
}
.nas-gallery-desc {
  color: rgba(255, 255, 255, 0.75);
  margin-bottom: 0;
}
.nas-gallery-title,
.nas-gallery-desc {
  opacity: 0;
  transform: translateY(4px);
  transition: opacity 0.4s ease, transform 0.4s ease;
}
.nas-gallery-caption.is-visible .nas-gallery-title,
.nas-gallery-caption.is-visible .nas-gallery-desc {
  opacity: 1;
  transform: translateY(0);
}
.nas-gallery-thumbs {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.5rem 0 1.5rem;
}
.nas-gallery-thumb {
  width: 3.9rem;
  height: 2.44rem;
  padding: 0;
  border-radius: 0.25rem;
  overflow: hidden;
  border: 2px solid transparent;
  background: none;
  cursor: pointer;
  opacity: 0.55;
  transition: opacity 0.2s ease, border-color 0.2s ease;
}
.nas-gallery-thumb:hover {
  opacity: 0.85;
}
.nas-gallery-thumb.is-active {
  opacity: 1;
  border-color: var(--bs-primary);
}
.nas-gallery-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top;
  display: block;
}
@media (max-width: 576px) {
  .nas-gallery-thumb {
    width: 3.4rem;
    height: 2.1rem;
  }
}
</style>

<script>
(function () {
  var slides = [
    { title: "Dashboard", desc: "Live storage, load, memory, and network status — no login needed." },
    { title: "Dashboard, logged in", desc: "The same live status, plus Services and admin navigation once signed in." },
    { title: "Services", desc: "Every enabled service, one click away, with a live up/down badge." },
    { title: "System Preferences", desc: "Network and outbound email — managed from the box itself." },
    { title: "Users", desc: "Add, remove, and reset passwords for accounts — no config edit or SSH needed." },
    { title: "Service Configuration", desc: "Enable, disable, and configure individual services, right down to each one's own settings." },
    { title: "Guided installer", desc: "One wizard, whether you're driving it from the NAS's own screen, a TUI console, or a remote browser." },
    { title: "Pick your services", desc: "Jellyfin, the *arr stack, Home Assistant, Frigate, and more — enable only what you need." },
    { title: "Unattended install", desc: "Writes the config, partitions storage, and installs NixOS, with a live log the whole way through." }
  ];

  var root = document.getElementById("nas-gallery");
  if (!root) return;
  var imgs = root.querySelectorAll(".nas-gallery-img");
  var thumbs = root.querySelectorAll(".nas-gallery-thumb");
  var titleEl = root.querySelector(".nas-gallery-title");
  var descEl = root.querySelector(".nas-gallery-desc");
  var captionEl = root.querySelector(".nas-gallery-caption");
  var current = 0;
  var timer = null;

  function show(index) {
    current = index;
    imgs.forEach(function (img, i) {
      img.classList.toggle("is-active", i === index);
    });
    thumbs.forEach(function (t, i) {
      t.classList.toggle("is-active", i === index);
    });
    captionEl.classList.remove("is-visible");
    window.setTimeout(function () {
      titleEl.textContent = slides[index].title;
      descEl.textContent = slides[index].desc;
      captionEl.classList.add("is-visible");
    }, 150);
  }

  function next() {
    show((current + 1) % slides.length);
  }

  function start() {
    stop();
    timer = window.setInterval(next, 4500);
  }

  function stop() {
    if (timer) {
      window.clearInterval(timer);
      timer = null;
    }
  }

  thumbs.forEach(function (t) {
    t.addEventListener("click", function () {
      show(parseInt(t.getAttribute("data-index"), 10));
      start();
    });
  });

  root.addEventListener("mouseenter", stop);
  root.addEventListener("mouseleave", start);
  root.addEventListener("focusin", stop);
  root.addEventListener("focusout", start);

  var stage = document.getElementById("nas-gallery-stage");
  var modal = document.getElementById("nas-gallery-modal");
  var modalImg = document.getElementById("nas-gallery-modal-img");
  var modalClose = document.getElementById("nas-gallery-modal-close");

  function openModal() {
    modalImg.src = imgs[current].src;
    modalImg.alt = slides[current].title;
    modal.classList.add("is-open");
    stop();
  }

  function closeModal() {
    modal.classList.remove("is-open");
    modalImg.src = "";
    start();
  }

  stage.addEventListener("click", openModal);
  stage.addEventListener("keydown", function (e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      openModal();
    }
  });
  modalClose.addEventListener("click", closeModal);
  modal.addEventListener("click", closeModal);
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && modal.classList.contains("is-open")) closeModal();
  });

  show(0);
  start();
})();
</script>

{{% blocks/lead color="white" %}}

**Bearded NAS** turns a Low Powered NAS appliance into a fully declarative
NixOS box: ZFS storage (adopt an existing pool or create a new one),
Samba/NFS file sharing, a Jellyfin + \*arr media stack, Home Assistant,
Frigate NVR, and Traefik-fronted access over both the LAN and a Nebula
mesh — all defined in one flake, with a self-contained installer wizard
to bring a new box up from blank disks.

{{% /blocks/lead %}}

{{% blocks/section color="primary" type="row" %}}

{{% blocks/feature title="Declarative storage" icon="fa-solid fa-server" url="/docs/installation/" %}}

ZFS pool creation or adoption, tmpfs root to spare the boot drive, and
`impermanence`-backed persistence — see
[Installation](/docs/installation/) to get started.

{{% /blocks/feature %}}

{{% blocks/feature title="Self-contained installer" icon="fa-solid fa-compact-disc" url="/docs/installation/iso/" %}}

A bootable ISO that partitions disks, collects users and settings, and
installs the system itself — no separate workstation required. Boots
straight into the wizard on the NAS's own screen if one's connected,
falls back to a text console otherwise, and is always reachable from a
remote browser either way. Pre-built for every
[release](https://github.com/BeardedTek/terramaster-nix/releases), or
[see the docs](/docs/installation/iso/) to build your own.

{{% /blocks/feature %}}

{{% blocks/feature title="Media & home automation" icon="fa-solid fa-house-signal" url="/docs/usage/services/" %}}

Jellyfin, Sonarr, Radarr, Jackett, Seerr, Home Assistant, and Frigate,
proxied through Traefik on both the LAN and a Nebula mesh — see
[Available Services](/docs/usage/services/).

{{% /blocks/feature %}}

{{% /blocks/section %}}

{{% blocks/section color="white" type="row" %}}

{{% blocks/feature title="One file to configure" icon="fa-solid fa-sliders" url="/docs/architecture/" %}}

`variables.nix` is the single place to set hostname, users, contact info,
and which services are enabled — see the
[architecture doc](/docs/architecture/).

{{% /blocks/feature %}}

{{% blocks/feature title="Open source" icon="fab fa-github" url="https://github.com/BeardedTek/terramaster-nix" %}}

The whole flake — modules, the installer wizard, and this documentation
site — is open source. Issues and PRs welcome.

{{% /blocks/feature %}}

{{% blocks/feature title="Built on NixOS" icon="fa-solid fa-snowflake" url="https://nixos.org" %}}

Every service is a native NixOS module or a small, well-documented piece
of glue around one — no Docker Compose sprawl to maintain.

{{% /blocks/feature %}}

{{% /blocks/section %}}
