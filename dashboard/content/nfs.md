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

<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
  If the hostname (<code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code>)
  doesn't resolve on your network, use one of the IP addresses instead.
</p>

<div class="overflow-x-auto mb-8">
  <table class="w-full text-sm text-left text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 rounded-lg">
    <thead class="text-xs uppercase bg-gray-50 dark:bg-gray-800 text-gray-500 dark:text-gray-400">
      <tr>
        <th class="px-4 py-3">Address</th>
        <th class="px-4 py-3">When to use it</th>
        <th class="px-4 py-3">Value</th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-t border-gray-200 dark:border-gray-700">
        <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Hostname</td>
        <td class="px-4 py-3">Local network, if name resolution works</td>
        <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">young</code></td>
      </tr>
      <tr class="border-t border-gray-200 dark:border-gray-700">
        <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Nebula IP</td>
        <td class="px-4 py-3">Connected over the Nebula mesh (remote)</td>
        <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">10.100.0.17</code></td>
      </tr>
      <tr class="border-t border-gray-200 dark:border-gray-700">
        <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">Local Ethernet IP</td>
        <td class="px-4 py-3">On the same LAN as the NAS</td>
        <td class="px-4 py-3"><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded font-mono">192.168.3.181</code></td>
      </tr>
    </tbody>
  </table>
</div>

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
</ul>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Trouble connecting?</h2>
<p class="text-gray-700 dark:text-gray-300">
  See the <a href="/troubleshooting/" class="text-primary-700 dark:text-primary-500 hover:underline">Troubleshooting</a> page.
</p>
