import 'dart:async';

import 'package:skyward/common/cache.dart';
import 'package:skyward/common/common.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/plugins/app.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/svg.dart';

const _maxCachedIconBytes = 16 << 20;

// The precache and the widget must resolve equal providers to share one
// ImageCache entry; 192 physical pixels cover a 48 dp icon box at 4x.
const _iconDecodeExtent = 192;

ImageProvider _iconImage(Uint8List bytes) {
  return ResizeImage(
    MemoryImage(bytes),
    width: _iconDecodeExtent,
    height: _iconDecodeExtent,
    policy: ResizeImagePolicy.fit,
  );
}

class _IconBytesCache {
  _IconBytesCache(this.maxBytes);

  final int maxBytes;
  final _entries = <String, Uint8List?>{};
  var _bytes = 0;

  bool contains(String key) => _entries.containsKey(key);

  Uint8List? operator [](String key) {
    if (!_entries.containsKey(key)) {
      return null;
    }
    return _entries[key] = _entries.remove(key);
  }

  void operator []=(String key, Uint8List? value) {
    remove(key);
    final size = value?.lengthInBytes ?? 0;
    if (size > maxBytes) {
      return;
    }
    _entries[key] = value;
    _bytes += size;
    while (_bytes > maxBytes) {
      remove(_entries.keys.first);
    }
  }

  void remove(String key) {
    _bytes -= _entries.remove(key)?.lengthInBytes ?? 0;
  }
}

final _decodedIcons = _IconBytesCache(_maxCachedIconBytes);
final _remoteIcons = _IconBytesCache(_maxCachedIconBytes);

Uint8List? _decodeIcon(String src) {
  if (!src.contains('base64,')) {
    return null;
  }
  if (_decodedIcons.contains(src)) {
    return _decodedIcons[src];
  }
  return _decodedIcons[src] = src.getBase64;
}

class CommonTargetIcon extends StatelessWidget {
  final String src;

  /// Shown while [src] is empty, loading or unreadable.
  final Widget? fallback;

  const CommonTargetIcon({super.key, required this.src, this.fallback});

  Widget _defaultIcon() {
    return fallback ?? const _ImagePlaceholder();
  }

  Widget _buildIcon() {
    if (src.isEmpty) {
      return _defaultIcon();
    }

    final base64 = _decodeIcon(src);
    if (base64 != null) {
      return _BytesImage(
        bytes: base64,
        isSvg: src.isSvg,
        fallback: _defaultIcon(),
      );
    }

    return ImageCacheWidget(src: src, defaultWidget: _defaultIcon());
  }

  @override
  Widget build(BuildContext context) {
    return _buildIcon();
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final size = IconTheme.of(context).size ?? 24;
    final colorScheme = context.colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: GlyphIcon(
          AppGlyphs.photos,
          size: size * 0.7,
          color: Color.alphaBlend(
            colorScheme.onSurfaceVariant.opacity50,
            colorScheme.surface,
          ),
        ),
      ),
    );
  }
}

/// Stands for a proxy group without an icon: the first letter or digit of
/// its name, past any leading emoji the name already shows. [GroupName.GLOBAL]
/// is the Core's own group, so it wears [globeMark] -- or, whenever the caller
/// knows it, the flag of the country traffic leaves by.
class GroupMonogram extends StatelessWidget {
  final String name;

  /// The two-letter code of the country traffic leaves by, for callers that
  /// have it at hand.
  final String? exitCountryCode;

  const GroupMonogram(this.name, {super.key, this.exitCountryCode});

  static final _letter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// What GLOBAL shows when nothing says where it exits.
  static const globeMark = '🌐';

  /// Whether [name] is the Core's own GLOBAL group.
  static bool isGlobal(String name) => name == GroupName.GLOBAL.name;

  String get _mark {
    if (isGlobal(name)) {
      final code = exitCountryCode;
      return code == null || code.isEmpty ? globeMark : code.countryFlagEmoji;
    }
    final letter = _letter.firstMatch(name)?.group(0);
    if (letter != null) {
      return letter.toUpperCase();
    }
    return name.characters.firstOrNull ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    final mark = _mark;
    if (mark.isEmpty) {
      return const _ImagePlaceholder();
    }
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: EmojiText(
          mark,
          maxLines: 1,
          style: AppTextStyle.custom(
            context,
            size: size * 0.62,
            leading: size * 0.62,
            weight: FontWeight.w600,
          ).copyWith(color: iconTheme.color),
        ),
      ),
    );
  }
}

/// The colour icon set the fork's default config dresses its groups in. A group
/// that carries no picture of its own borrows the entry its kind is known by,
/// so it keeps the same face as the config's own groups.
abstract final class GroupIconSource {
  static const _set =
      'https://cdn.jsdmirror.com/gh/Koolson/Qure@master/IconSet/Color/';

  /// The names the default config gives the groups it builds.
  static const _named = {
    '默认代理': 'Rocket.png',
    '自动选择': 'Auto.png',
    '故障转移': 'Round_Robin.png',
    '负载均衡': 'Stack.png',
    '漏网之鱼': 'Final.png',
    '直连': 'Direct.png',
    '其他节点': 'World_Map.png',
  };

  /// A group's own icon, or the set's entry for its kind, or empty for a
  /// [GroupMonogram] to stand in. A selector without a name the set knows keeps
  /// the monogram: which picture would suit an arbitrary group is a guess.
  static String of({
    required String name,
    required GroupType type,
    required String icon,
  }) {
    if (icon.isNotEmpty) {
      return icon;
    }
    if (GroupMonogram.isGlobal(name)) {
      return '';
    }
    final entry =
        _named[name] ??
        switch (type) {
          GroupType.URLTest => 'Auto.png',
          GroupType.Fallback => 'Round_Robin.png',
          GroupType.LoadBalance => 'Stack.png',
          GroupType.Selector || GroupType.Relay => null,
        };
    return entry == null ? '' : '$_set$entry';
  }
}

/// Stands in for a group the config gave no icon: the glyph of what the group
/// does, in the hue that kind of group wears. [GroupName.GLOBAL] keeps
/// [GroupMonogram]'s flag, which says where traffic leaves rather than what the
/// group is.
class GroupGlyph extends StatelessWidget {
  const GroupGlyph({
    super.key,
    required this.name,
    required this.type,
    this.exitCountryCode,
  });

  final String name;
  final GroupType type;
  final String? exitCountryCode;

  static Glyph glyphOf(GroupType type) => switch (type) {
    GroupType.Selector => AppGlyphs.proxies,
    GroupType.URLTest => AppGlyphs.speed,
    GroupType.Fallback => AppGlyphs.layers,
    GroupType.LoadBalance => AppGlyphs.split,
    GroupType.Relay => AppGlyphs.link,
  };

  /// Fixed rather than seeded: the kinds have to stay apart whatever colour the
  /// theme takes. Each is a tone that reads on both a light and a dark surface.
  static Color colorOf(BuildContext context, GroupType type) {
    final dark = context.colorScheme.brightness == Brightness.dark;
    return switch (type) {
      GroupType.Selector =>
        dark ? const Color(0xFF8AB4F8) : const Color(0xFF1A63C7),
      GroupType.URLTest =>
        dark ? const Color(0xFF7BD8A4) : const Color(0xFF1D8A55),
      GroupType.Fallback =>
        dark ? const Color(0xFFF5B85E) : const Color(0xFFB26A0B),
      GroupType.LoadBalance =>
        dark ? const Color(0xFFC4A6F7) : const Color(0xFF7A45C9),
      GroupType.Relay =>
        dark ? const Color(0xFF6FD3D0) : const Color(0xFF0E8684),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (GroupMonogram.isGlobal(name)) {
      return GroupMonogram(name, exitCountryCode: exitCountryCode);
    }
    return GlyphIcon(glyphOf(type), color: colorOf(context, type));
  }
}

class _BytesImage extends StatelessWidget {
  const _BytesImage({
    required this.bytes,
    required this.isSvg,
    required this.fallback,
    this.onError,
  });

  final Uint8List bytes;
  final bool isSvg;
  final Widget fallback;
  final VoidCallback? onError;

  Widget _buildFallback() {
    onError?.call();
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return isSvg
        ? SvgPicture.memory(bytes, errorBuilder: (_, _, _) => _buildFallback())
        : Image(
            image: _iconImage(bytes),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _buildFallback(),
          );
  }
}

final _cacheManager = CacheManager(
  Config(
    DefaultCacheManager.key,
    fileService: HttpFileService()..concurrentFetches = maxConcurrentIconLoads,
  ),
);

Stream<Uint8List> _readCachedIcon(String src) {
  return _cacheManager
      .getFileStreamV2(src)
      .asyncMap((data) => data.file.readAsBytes());
}

var _readRemoteIcon = _readCachedIcon;

@visibleForTesting
set readRemoteIcon(Stream<Uint8List> Function(String src)? value) {
  _readRemoteIcon = value ?? _readCachedIcon;
}

Stream<Uint8List> _loadRemoteIcon(String src) {
  return _readRemoteIcon(src).map((bytes) {
    final current = _remoteIcons[src];
    final next = current != null && listEquals(current, bytes)
        ? current
        : bytes;
    return _remoteIcons[src] = next;
  });
}

Future<void> _decodeAhead(Uint8List bytes) {
  final completer = Completer<void>();
  final stream = _iconImage(bytes).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish() {
    stream.removeListener(listener);
    completer.complete();
  }

  listener = ImageStreamListener(
    (_, _) => finish(),
    onError: (_, _) => finish(),
  );
  stream.addListener(listener);
  return completer.future;
}

Future<void> precacheTargetIcons(Iterable<String> srcs) async {
  final pending = srcs
      .toSet()
      .where(
        (src) =>
            src.isNotEmpty &&
            !src.contains('base64,') &&
            !_remoteIcons.contains(src),
      )
      .map((src) async {
        try {
          await for (final bytes in _loadRemoteIcon(src)) {
            if (!src.isSvg) {
              await _decodeAhead(bytes);
            }
          }
        } catch (error) {
          commonPrint.log('Failed to precache icon $src: $error');
        }
      });
  await Future.wait(pending);
}

class ImageCacheWidget extends StatefulWidget {
  final String src;
  final Widget defaultWidget;

  const ImageCacheWidget({
    super.key,
    required this.src,
    required this.defaultWidget,
  });

  @override
  State<ImageCacheWidget> createState() => _ImageCacheWidgetState();
}

class _ImageCacheWidgetState extends State<ImageCacheWidget> {
  late final ValueNotifier<Uint8List?> _bytesNotifier;
  StreamSubscription? _streamSubscription;
  var _loadEnded = false;

  @override
  void initState() {
    super.initState();
    _bytesNotifier = ValueNotifier(_remoteIcons[widget.src]);
    _getImageFormCache();
  }

  @override
  void didUpdateWidget(covariant ImageCacheWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _bytesNotifier.value = _remoteIcons[widget.src];
      _loadEnded = false;
      _getImageFormCache();
    }
  }

  void _getImageFormCache() {
    final src = widget.src;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    if (src.isEmpty) {
      return;
    }
    _streamSubscription = _loadRemoteIcon(src).listen(
      (bytes) {
        if (mounted) {
          _bytesNotifier.value = bytes;
        }
      },
      onError: (Object error) {
        commonPrint.log('Failed to read icon $src: $error');
      },
      onDone: () {
        if (mounted && _bytesNotifier.value == null) {
          setState(() => _loadEnded = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _bytesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: _bytesNotifier,
      builder: (context, bytes, _) {
        if (bytes == null) {
          return _loadEnded || widget.src.isEmpty
              ? widget.defaultWidget
              : SizedBox.square(dimension: IconTheme.of(context).size ?? 24);
        }
        return _BytesImage(
          bytes: bytes,
          isSvg: widget.src.isSvg,
          fallback: widget.defaultWidget,
          onError: () => _remoteIcons.remove(widget.src),
        );
      },
    );
  }
}

class PackageIcon extends StatefulWidget {
  final String packageName;
  final double size;

  const PackageIcon({super.key, required this.packageName, required this.size});

  @override
  State<PackageIcon> createState() => _PackageIconState();
}

class _PackageIconState extends State<PackageIcon> {
  ImageProvider? _icon;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _showCachedIcon();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant PackageIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _showCachedIcon();
      _loadIcon();
    }
  }

  void _showCachedIcon() {
    _generation++;
    _icon = app?.getCachedPackageIcon(widget.packageName);
  }

  void _loadIcon() {
    final generation = _generation;
    app?.getPackageIcon(widget.packageName).then((icon) {
      if (!mounted ||
          generation != _generation ||
          icon == null ||
          icon == _icon) {
        return;
      }
      setState(() {
        _icon = icon;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    if (icon == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    return Image(
      image: icon,
      gaplessPlayback: true,
      width: widget.size,
      height: widget.size,
    );
  }
}
