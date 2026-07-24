---
title: Troubleshooting
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Quick answers for common issues. This NAS is meant to just stay on and
  run &mdash; you shouldn't need to do much here.
</p>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Restarting or shutting down safely</h2>
<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
  <strong class="font-semibold text-gray-900 dark:text-white">Never just unplug it.</strong>
  That can corrupt files that were mid-write.
</p>
<ol class="list-decimal pl-6 space-y-2 mb-4 text-gray-700 dark:text-gray-300">
  <li>Press the power button on the front of the NAS <strong class="font-semibold text-gray-900 dark:text-white">once, briefly</strong>.</li>
  <li>Wait &mdash; the drive lights will keep blinking for a bit while it shuts down cleanly. This can take a minute or two.</li>
  <li>Once all the lights are off, it's safe to unplug it if you need to.</li>
  <li>To turn it back on, press the power button again.</li>
</ol>
<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  There's no separate "restart" button &mdash; to restart, shut it down
  (above), then press the power button again to turn it back on.
</p>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">A share or service isn't working</h2>
<ul class="list-disc pl-6 space-y-2 mb-8 text-gray-700 dark:text-gray-300">
  <li>Give it a minute and try again &mdash; something may just be restarting.</li>
  <li>Check that your own device is connected to the network / Nebula properly.</li>
  <li>Check the <a href="/" class="text-primary-700 dark:text-primary-500 hover:underline">Dashboard</a> page &mdash; if the network cards show "down", the problem is the NAS's connection, not yours.</li>
  <li>Still stuck? Contact the admin rather than trying to fix it yourself.</li>
</ul>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Can't connect to Samba or NFS</h2>
<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  See the <a href="/samba/" class="text-primary-700 dark:text-primary-500 hover:underline">Samba</a> or
  <a href="/nfs/" class="text-primary-700 dark:text-primary-500 hover:underline">NFS</a> pages for setup steps.
  Double-check your username and password if it's asking again.
</p>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Who to contact</h2>
<p class="text-gray-700 dark:text-gray-300 mb-3">
  For anything not covered here, get in touch:
</p>
{{< contact >}}
