---
title: Samba (File Shares)
---

<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Two shares are available: <strong class="font-semibold text-gray-900 dark:text-white">media</strong>
  and <strong class="font-semibold text-gray-900 dark:text-white">data</strong>.
  You'll need your username and password to connect. If the hostname
  (<code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code>)
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

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Windows</h2>
<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
  Open <strong class="font-semibold text-gray-900 dark:text-white">File Explorer</strong>, type one of these
  into the address bar, and press Enter:
</p>
<ul class="list-disc pl-6 space-y-1 mb-6 text-gray-700 dark:text-gray-300">
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">\\young\</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">\\10.100.0.17\</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">\\192.168.3.181\</code></li>
</ul>
<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Enter your username and password when prompted, then open
  <strong class="font-semibold text-gray-900 dark:text-white">media</strong> or
  <strong class="font-semibold text-gray-900 dark:text-white">data</strong>.
  Optional: right-click <strong class="font-semibold text-gray-900 dark:text-white">This PC</strong> &rarr;
  <strong class="font-semibold text-gray-900 dark:text-white">Map network drive</strong> to make a share
  show up as its own drive letter every time you log in.
</p>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">macOS</h2>
<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
  In <strong class="font-semibold text-gray-900 dark:text-white">Finder</strong>, press
  <code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">Cmd+K</code>
  (or <strong class="font-semibold text-gray-900 dark:text-white">Go &rarr; Connect to Server</strong>),
  enter one of these, and click <strong class="font-semibold text-gray-900 dark:text-white">Connect</strong>:
</p>
<ul class="list-disc pl-6 space-y-1 mb-8 text-gray-700 dark:text-gray-300">
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">smb://young/</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">smb://10.100.0.17/</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">smb://192.168.3.181/</code></li>
</ul>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Phone / tablet</h2>
<p class="text-gray-700 dark:text-gray-300 mb-3 leading-relaxed">
  Most file-browser apps (Files, FE File Explorer, Documents, etc.) support
  adding an SMB/network share. In the "server" field, use one of:
</p>
<ul class="list-disc pl-6 space-y-1 mb-4 text-gray-700 dark:text-gray-300">
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">young</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">10.100.0.17</code></li>
  <li><code class="px-1.5 py-0.5 bg-gray-100 dark:bg-gray-800 rounded text-sm font-mono">192.168.3.181</code></li>
</ul>
<p class="text-gray-700 dark:text-gray-300 mb-8 leading-relaxed">
  Username / password: same as above.
</p>

<h2 class="text-xl font-semibold text-gray-900 dark:text-white mt-8 mb-3">Trouble connecting?</h2>
<p class="text-gray-700 dark:text-gray-300">
  See the <a href="/troubleshooting/" class="text-primary-700 dark:text-primary-500 hover:underline">Troubleshooting</a> page.
</p>
