The group icons in this directory are the Color set from Koolson/Qure
(https://github.com/Koolson/Qure, `IconSet/Color`), the set the default config
at https://github.com/aqiyoung/flclash-config points its proxy groups at. They
are carried in the bundle so a group wears the same picture offline: the region
groups 香港, 日本, 美国, 新加坡 and 台湾 with their flags, and the service groups
(YouTube, Google, ChatGPT, GitHub, Netflix and the rest) with their marks. The
routing groups the same config builds — 默认代理, 自动选择, 故障转移, 负载均衡,
漏网之鱼, 直连 and 其他节点 — wear the app's own logo instead, which is
`assets/images/icon.png`.

Koolson/Qure publishes no licence, so this set is redistributed here by the
fork owner's decision rather than under a granted one. If the upstream objects,
drop the directory, the `assets/images/groups/` entry in `pubspec.yaml` and the
maps in `GroupIconSource`, and the app falls back to each config's own `icon`
and then to the app logo.

Names and marks belong to their respective owners.
