(function () {
  "use strict";

  var stageLabelEl = document.getElementById("stage-label");
  var lostBanner = document.getElementById("lost-banner");
  var lostBannerText = document.getElementById("lost-banner-text");
  var connectionBanner = document.getElementById("connection-banner");

  var questionCard = document.getElementById("question-card");
  var titleEl = document.getElementById("q-title");
  var messageEl = document.getElementById("q-message");
  var fieldsEl = document.getElementById("q-fields");
  var formEl = document.getElementById("q-form");
  var submitBtn = document.getElementById("q-submit-btn");
  var noBtn = document.getElementById("q-no-btn");
  var cancelBtn = document.getElementById("q-cancel-btn");

  var progressCard = document.getElementById("progress-card");
  var progressSpinner = document.getElementById("progress-spinner");
  var progressIconSuccess = document.getElementById("progress-icon-success");
  var progressIconFailed = document.getElementById("progress-icon-failed");
  var progressStatusText = document.getElementById("progress-status-text");
  var progressStepList = document.getElementById("progress-step-list");
  var logToggleBtn = document.getElementById("log-toggle-btn");
  var logToggleChevron = document.getElementById("log-toggle-chevron");
  var logPanel = document.getElementById("log-panel");
  var logTailEl = document.getElementById("log-tail");

  var lastRenderedSeq = -1;
  var questionPollTimer = null;
  var progressPollTimer = null;
  var installStarted = false;
  var dotsTimer = null;
  var dotsCount = 0;

  function setConnectionOk(ok) {
    connectionBanner.classList.toggle("hidden", ok);
  }

  function showLost(claimedBy) {
    lostBannerText.textContent = "The installer is being driven from the " +
      (claimedBy || "other") + " interface — continue there.";
    lostBanner.classList.remove("hidden");
    questionCard.classList.add("hidden");
    progressCard.classList.add("hidden");
    if (questionPollTimer) { clearInterval(questionPollTimer); questionPollTimer = null; }
  }

  // Matches whiptail's own checklist output convention exactly (space-
  // separated, double-quoted tags) — see lib/ui-web.sh's wiz_checklist.
  function parseCheckboxValues(container) {
    var boxes = container.querySelectorAll("input[type=checkbox]:checked");
    var values = [];
    for (var i = 0; i < boxes.length; i++) { values.push(boxes[i].value); }
    return values;
  }

  // ---- Message formatting -------------------------------------------
  // The wizard's message strings are plain text built for a whiptail
  // terminal box (key: value lines, ALL-CAPS section headers, indented
  // sub-lists) — this renders that same text as real structure instead
  // of one undifferentiated paragraph, and turns any bare URL into a
  // real clickable link (e.g. the Tailscale login link).

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  var URL_RE = /(https?:\/\/[^\s<>"]+)/g;

  // Runs on RAW (unescaped) text — splits on URL matches while '<'/'>'
  // are still literal characters, then escapes each plain-text segment
  // and the URL's own displayed text independently. Order matters:
  // escaping first would turn a placeholder like "<this box's LAN IP>"
  // into "&lt;this box's LAN IP&gt;", whose literal '<' is gone by the
  // time the regex runs — its exclusion of '<' no longer stops the
  // match, producing a garbled, truncated link ("http://&lt;this").
  // Confirmed the hard way against that exact real message
  // (stages/90-install.sh's sso_note) before this was fixed.
  function linkify(raw) {
    var result = "";
    var lastIndex = 0;
    var m;
    URL_RE.lastIndex = 0;
    while ((m = URL_RE.exec(raw)) !== null) {
      result += escapeHtml(raw.slice(lastIndex, m.index));
      var safeUrl = escapeHtml(m[0]);
      result += '<a href="' + safeUrl + '" target="_blank" rel="noopener noreferrer" ' +
        'class="text-primary-700 dark:text-primary-500 hover:underline break-all">' + safeUrl + "</a>";
      lastIndex = m.index + m[0].length;
    }
    result += escapeHtml(raw.slice(lastIndex));
    return result;
  }

  function looksLikePathOrId(s) {
    return /^[\w.\/-]+$/.test(s) && (s.indexOf("/") !== -1 || /^ata[-_]|_VB[0-9a-f]|\.(nix|env)$/i.test(s));
  }

  function formatMessageHtml(text) {
    if (!text) { return ""; }
    var lines = String(text).split("\n");
    var out = [];
    for (var i = 0; i < lines.length; i++) {
      var raw = lines[i];
      var trimmed = raw.replace(/^\s+/, "");
      var indent = Math.min(raw.length - trimmed.length, 8);
      var indentAttr = indent > 0 ? ' style="margin-left:' + (indent * 0.5) + 'em"' : "";

      if (trimmed === "") {
        out.push('<div class="h-3"></div>');
        continue;
      }

      var sectionMatch = trimmed.match(/^([A-Z][A-Z0-9 /_-]*):$/);
      var kvMatch = trimmed.match(/^([A-Za-z0-9][A-Za-z0-9 _/.-]*): (.+)$/);
      var isWarning = trimmed.length > 15 && /[A-Z]/.test(trimmed) && !/[a-z]/.test(trimmed);

      if (sectionMatch) {
        out.push('<div class="font-semibold text-gray-900 dark:text-white mt-3 mb-1"' + indentAttr + '>' +
          escapeHtml(sectionMatch[1]) + ":</div>");
      } else if (kvMatch) {
        var valueRaw = kvMatch[2];
        var valueClass = "text-gray-700 dark:text-gray-300 break-all" +
          (looksLikePathOrId(valueRaw) ? " font-mono text-xs" : "");
        out.push('<div class="flex flex-wrap gap-2 text-sm"' + indentAttr + '>' +
          '<span class="font-medium text-gray-900 dark:text-white shrink-0">' + escapeHtml(kvMatch[1]) + ':</span>' +
          '<span class="' + valueClass + '">' + linkify(valueRaw) + "</span></div>");
      } else if (isWarning) {
        out.push('<div class="text-sm font-semibold installer-warning mt-1"' + indentAttr + '>' +
          escapeHtml(trimmed) + "</div>");
      } else if (looksLikePathOrId(trimmed)) {
        out.push('<div class="text-sm font-mono text-gray-700 dark:text-gray-300 break-all"' + indentAttr + '>' +
          escapeHtml(trimmed) + "</div>");
      } else {
        out.push('<div class="text-sm text-gray-700 dark:text-gray-300"' + indentAttr + '>' +
          linkify(trimmed) + "</div>");
      }
    }
    return out.join("");
  }

  function postAnswer(body) {
    submitBtn.disabled = true;
    noBtn.disabled = true;
    fetch("/api/answer", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    })
      .then(function (r) { return r.json().then(function (data) { return { status: r.status, data: data }; }); })
      .then(function (res) {
        submitBtn.disabled = false;
        noBtn.disabled = false;
        if (res.status === 409) {
          // Stale/duplicate — res.data IS the real current envelope.
          // Treat it exactly like a normal poll response so there's no
          // separate error-handling path to get wrong.
          render(res.data);
          return;
        }
        // Success — the next poll will pick up the new question. Poll
        // right away instead of waiting out the normal interval, so the
        // UI advances immediately.
        pollQuestion();
      })
      .catch(function () {
        submitBtn.disabled = false;
        noBtn.disabled = false;
        setConnectionOk(false);
      });
  }

  function renderQuestion(seq, q) {
    titleEl.textContent = q.title || "";
    messageEl.innerHTML = formatMessageHtml(q.message || q.prompt || "");
    fieldsEl.innerHTML = "";
    noBtn.classList.add("hidden");
    cancelBtn.classList.add("hidden");
    submitBtn.textContent = "Continue";
    submitBtn.classList.remove("hidden");

    if (q.error) {
      var err = document.createElement("p");
      err.className = "mb-3 text-sm rounded-lg p-3 bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300";
      err.textContent = q.error;
      fieldsEl.appendChild(err);
    }

    var onSubmit = null;

    if (q.type === "msgbox" || q.type === "textbox") {
      if (q.type === "textbox" && q.content_url) {
        var pre = document.createElement("pre");
        pre.className = "update-log-output text-xs p-3 rounded-lg overflow-y-auto";
        pre.style.maxHeight = "40vh";
        pre.textContent = "Loading…";
        fieldsEl.appendChild(pre);
        fetch(q.content_url, { cache: "no-store" })
          .then(function (r) { return r.text(); })
          .then(function (text) { pre.textContent = text; })
          .catch(function () { pre.textContent = "(couldn't load preview)"; });
      }
      onSubmit = function () { postAnswer({ seq: seq }); };
    } else if (q.type === "yesno") {
      submitBtn.textContent = "Yes";
      noBtn.classList.remove("hidden");
      onSubmit = function () { postAnswer({ seq: seq, value: true }); };
      noBtn.onclick = function () { postAnswer({ seq: seq, value: false }); };
    } else if (q.type === "input" || q.type === "password") {
      var input = document.createElement("input");
      input.type = q.type === "password" ? "password" : "text";
      input.value = q.default || "";
      input.autofocus = true;
      input.className = "bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white";
      fieldsEl.appendChild(input);
      onSubmit = function () { postAnswer({ seq: seq, value: input.value }); };
      setTimeout(function () { input.focus(); }, 0);
    } else if (q.type === "textarea") {
      var textarea = document.createElement("textarea");
      textarea.rows = 12;
      textarea.placeholder = "Paste here (leave empty to skip)…";
      textarea.className = "bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white font-mono text-xs";
      fieldsEl.appendChild(textarea);
      onSubmit = function () { postAnswer({ seq: seq, value: textarea.value }); };
      setTimeout(function () { textarea.focus(); }, 0);
    } else if (q.type === "menu") {
      var select = document.createElement("select");
      select.className = "bg-gray-50 border border-gray-300 text-gray-900 rounded-lg block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:text-white";
      (q.options || []).forEach(function (opt) {
        var o = document.createElement("option");
        o.value = opt.tag;
        o.textContent = opt.label;
        select.appendChild(o);
      });
      fieldsEl.appendChild(select);
      onSubmit = function () { postAnswer({ seq: seq, value: select.value }); };
    } else if (q.type === "checklist") {
      var wrap = document.createElement("div");
      var checkboxByTag = {};
      var options = q.options || [];
      var tags = options.map(function (o) { return o.tag; });

      options.forEach(function (opt, idx) {
        var row = document.createElement("div");
        row.className = "installer-option-row";
        var cb = document.createElement("input");
        cb.type = "checkbox";
        cb.value = opt.tag;
        cb.checked = !!opt.checked;
        cb.id = "cb-" + idx;
        checkboxByTag[opt.tag] = cb;
        var label = document.createElement("label");
        label.setAttribute("for", cb.id);
        label.textContent = opt.label;
        row.appendChild(cb);
        row.appendChild(label);
        wrap.appendChild(row);
      });

      // Group toggles (stages/60-features.sh's "sso"/"mediaacq"/
      // "homeassistant") own child options named "<parent>_<child>" —
      // detected generically from the tag list itself (any tag that's a
      // literal "<prefix>_..." of another tag in the SAME checklist is
      // that prefix's child), not hardcoded to these specific names, so
      // this keeps working if the stage adds/renames groups later.
      // Unchecking a group unchecks+disables its children (matching the
      // stage's own prompt text: "their sub-items only matter if the
      // group itself is checked" — a still-checked-but-disabled child
      // would otherwise still get submitted); re-checking the group
      // restores each child to whatever it was checked to when this
      // question was first rendered, not just "all on".
      var childrenByParent = {};
      tags.forEach(function (tag) {
        var underscore = tag.indexOf("_");
        if (underscore === -1) { return; }
        var parent = tag.slice(0, underscore);
        if (tags.indexOf(parent) === -1) { return; }
        (childrenByParent[parent] = childrenByParent[parent] || []).push(tag);
      });

      Object.keys(childrenByParent).forEach(function (parentTag) {
        var parentCb = checkboxByTag[parentTag];
        var childTags = childrenByParent[parentTag];
        var originalChecked = {};
        childTags.forEach(function (t) { originalChecked[t] = checkboxByTag[t].checked; });

        function applyGroupState() {
          var enabled = parentCb.checked;
          childTags.forEach(function (t) {
            var childCb = checkboxByTag[t];
            childCb.disabled = !enabled;
            childCb.checked = enabled ? originalChecked[t] : false;
          });
        }

        parentCb.addEventListener("change", applyGroupState);
        applyGroupState();
      });

      fieldsEl.appendChild(wrap);
      onSubmit = function () { postAnswer({ seq: seq, value: parseCheckboxValues(wrap) }); };
    } else {
      var unknown = document.createElement("p");
      unknown.className = "text-sm installer-warning";
      unknown.textContent = "Unknown question type: " + q.type;
      fieldsEl.appendChild(unknown);
      onSubmit = function () { postAnswer({ seq: seq }); };
    }

    formEl.onsubmit = function (ev) {
      ev.preventDefault();
      if (onSubmit) { onSubmit(); }
    };
  }

  function render(envelope) {
    setConnectionOk(true);

    if (envelope.session_state === "lost") {
      showLost(envelope.claimed_by);
      return;
    }

    lostBanner.classList.add("hidden");
    stageLabelEl.textContent = envelope.stage || "";

    if (envelope.stage === "stage_90_install" && !installStarted) {
      installStarted = true;
      // The wizard's own progress waypoints (Writing config/Running
      // disko/Installing NixOS) are pure log entries on this backend
      // (lib/ui-web.sh's wiz_notice never blocks) — nothing new arrives
      // in question.json for them, so the question-card would otherwise
      // just sit frozen on stage 80's already-answered review/confirm
      // screen for the rest of the install. Hide it now; a genuinely new
      // question (the final "Done" summary, then "Reboot now?") still
      // pops it back up normally below, since those DO bump seq.
      questionCard.classList.add("hidden");
      progressCard.classList.remove("hidden");
      startProgressPolling();
    }

    if (!envelope.question || envelope.seq === lastRenderedSeq) {
      return;
    }
    lastRenderedSeq = envelope.seq;

    questionCard.classList.remove("hidden");
    renderQuestion(envelope.seq, envelope.question);
  }

  function pollQuestion() {
    fetch("/api/question", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (data) { render(data); })
      .catch(function () { setConnectionOk(false); });
  }

  // ---- Install progress ------------------------------------------

  function stopDotsAnimation() {
    if (dotsTimer) { clearInterval(dotsTimer); dotsTimer = null; }
  }

  function startDotsAnimation(labelSpan, baseLabel) {
    dotsCount = 0;
    dotsTimer = setInterval(function () {
      dotsCount = (dotsCount % 3) + 1;
      labelSpan.textContent = baseLabel + ".".repeat(dotsCount);
    }, 500);
  }

  function buildStepIcon(state) {
    var span = document.createElement("span");
    span.className = "update-step-icon";
    if (state === "running") {
      var spinner = document.createElement("span");
      spinner.className = "inline-block align-middle animate-spin rounded-full h-3 w-3 border-2 border-gray-300 dark:border-gray-600 border-t-primary-600";
      span.appendChild(spinner);
    } else if (state === "done") {
      span.innerHTML = "&#10003;";
    } else if (state === "failed") {
      span.innerHTML = "&#10007;";
      span.classList.add("installer-icon-failed");
    } else {
      span.innerHTML = "&#9675;";
    }
    return span;
  }

  function renderProgress(data) {
    stopDotsAnimation();
    progressStepList.innerHTML = "";

    (data.steps || []).forEach(function (step) {
      var li = document.createElement("li");
      li.className = "update-step" + (step.state === "done" ? " update-step-done" : "");
      li.appendChild(buildStepIcon(step.state));
      var labelSpan = document.createElement("span");
      labelSpan.textContent = step.label;
      li.appendChild(labelSpan);
      progressStepList.appendChild(li);

      if (step.state === "running") {
        startDotsAnimation(labelSpan, step.label);
      }
    });

    progressSpinner.classList.toggle("hidden", data.state !== "running" && data.state !== "pending");
    progressIconSuccess.classList.toggle("hidden", data.state !== "done");
    progressIconFailed.classList.toggle("hidden", data.state !== "failed");
    progressStatusText.textContent =
      data.state === "done" ? "Install complete." :
      data.state === "failed" ? "Install failed — see the log below." :
      "Installing…";

    if (data.logTail) {
      logTailEl.textContent = data.logTail;
      logTailEl.scrollTop = logTailEl.scrollHeight;
    }

    if (data.state === "done" || data.state === "failed") {
      if (progressPollTimer) { clearInterval(progressPollTimer); progressPollTimer = null; }
    }
  }

  function pollProgress() {
    fetch("/api/install-progress", { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(renderProgress)
      .catch(function () { /* keep showing the last known state */ });
  }

  function startProgressPolling() {
    pollProgress();
    progressPollTimer = setInterval(pollProgress, 2000);
  }

  logToggleBtn.addEventListener("click", function () {
    var hidden = logPanel.classList.toggle("hidden");
    logToggleChevron.style.transform = hidden ? "" : "rotate(180deg)";
    logToggleBtn.querySelector("span").textContent = hidden ? "Show log" : "Hide log";
  });

  pollQuestion();
  questionPollTimer = setInterval(pollQuestion, 700);
})();
