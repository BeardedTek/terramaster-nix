---
title: NFS
---

<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
  NFS is available for Linux (and other Nebula-connected) clients that prefer
  it over Samba. Two exports are available:
</p>
<ul class="list-disc pl-6 space-y-1 mb-8 text-gray-700 dark:text-gray-300">
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young:/rust/media</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young:/rust/data</code></li>
</ul>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Mount on demand</h2>
<pre class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 mb-8 overflow-x-auto text-sm font-mono text-gray-800 dark:text-gray-200">sudo mkdir -p /mnt/young-media /mnt/young-data
sudo mount -t nfs young:/rust/media /mnt/young-media
sudo mount -t nfs young:/rust/data /mnt/young-data</pre>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Mount automatically at boot</h2>
<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">Add to <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">/etc/fstab</code>:</p>
<pre class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono text-gray-800 dark:text-gray-200">young:/rust/media  /mnt/young-media  nfs  defaults,noatime  0  0
young:/rust/data   /mnt/young-data   nfs  defaults,noatime  0  0</pre>
<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Then run <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">sudo mount -a</code>
  to mount it immediately without rebooting.
</p>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Notes</h2>
<ul class="list-disc pl-6 space-y-2 mb-8 text-gray-700 dark:text-gray-300">
  <li>Only reachable from the local network or over the Nebula mesh &mdash; not from the wider internet.</li>
  <li>If <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code> doesn't resolve, use the NAS's IP address instead.</li>
</ul>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Trouble connecting?</h2>
<p class="text-gray-700 dark:text-gray-300">
  See the <a href="/troubleshooting/" class="text-primary-700 dark:text-primary-500 hover:underline">Troubleshooting</a> page.
</p>
