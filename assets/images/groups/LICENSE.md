The group icons in this directory are the Color set from Koolson/Qure
(https://github.com/Koolson/Qure, `IconSet/Color`), the set the default config
at https://github.com/aqiyoung/flclash-config points its proxy groups at. They
are carried in the bundle so a group wears the same picture offline, and are
used for the groups that config builds: 默认代理 (rocket), 自动选择 and the
per-region auto groups (auto), 故障转移 (round_robin), 负载均衡 (stack),
漏网之鱼 (final), 直连 (direct), 其他节点 (world_map), and the region groups
香港, 日本, 美国, 新加坡 and 台湾.

Koolson/Qure publishes no licence, so this set is redistributed here by the
fork owner's decision rather than under a granted one. If the upstream objects,
drop the directory, the `assets/images/groups/` entry in `pubspec.yaml` and the
`GroupIconSource` map that names them, and the app falls back to each config's
own `icon` and to its glyphs.

Names and marks belong to their respective owners.
