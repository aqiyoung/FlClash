The group icons in this directory are the Color set from Koolson/Qure
(https://github.com/Koolson/Qure, `IconSet/Color`), the set the default config
at https://github.com/aqiyoung/flclash-config points its proxy groups at. They
are carried in the bundle so a group wears the same picture offline: the
routing groups by what they do (默认代理 rocket, 自动选择 and the per-region auto
groups auto, 故障转移 round_robin, 负载均衡 stack, 漏网之鱼 final, 直连 direct,
其他节点 world_map), the region groups by their flag (香港, 日本, 美国, 新加坡,
台湾), and the service groups by their mark (YouTube, Google, ChatGPT, GitHub,
Netflix and the rest). A group none of these name keeps the picture its config
gives it, and the app's own logo (`assets/images/icon.png`, not part of this
set) stands in when that picture is missing or unreadable.

Koolson/Qure publishes no licence, so this set is redistributed here by the
fork owner's decision rather than under a granted one. If the upstream objects,
drop the directory, the `assets/images/groups/` entry in `pubspec.yaml` and the
maps in `GroupIconSource`, and the app falls back to each config's own `icon`
and then to the app logo.

Names and marks belong to their respective owners.
