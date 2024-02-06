# wifiutil

<!-- BADGES -->
<!--span class="badge-paypal"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=X3KS6KJP63MG4" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span-->

<!-- DESCRIPTION -->
iOS command-line tool for WiFi-related operation.

# Installation
<ul>
<li>Search <code>wifiutil</code> in the Cydia on your jailbroken iOS device.</li>
<li>Install and access it using MobileTerminal or remote SSH.</li>
</ul>

# Usage
<ul>
<li>To enable wifi on iphone: <code>wifiutil enable-wifi</code></li>
<li>To disable wifi on iphone: <code>wifiutil disable-wifi</code></li>
<li>To scan available wifi hotspot: <code>wifiutil scan</code></li>
<li>To associate with wifi hotspot named {ssid}: <code>wifiutil associate {ssid}</code></li>
<li>To associate with wifi hotspot named {ssid} and with password {passwd}: <code>wifiutil associate {ssid} -p {passwd}</code></li>
<li>To disassociate with current wifi network: <code>wifiutil disassociate</code></li>
<li>To ping an ip address: <code>wifiutil ping {ip}</code></li>
</ul>

# Note:
Crapple doens't want you using NSTask.h and indeed it stops working in later versions of IOS (app sigining I think) so you'll need to get a copy of NSTask.h and drop it in hte `headers` dir.

# License
Licensed under:
<ul><li><a href="http://spdx.org/licenses/MIT.html">MIT License</a></li></ul>
