import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:skyward/common/common.dart';
import 'package:skyward/database/database.dart';
import 'package:skyward/enum/enum.dart';
import 'package:skyward/models/models.dart';
import 'package:skyward/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app.dart';
import 'config.dart';
import 'core.dart';
import 'database.dart';

part 'generated/state.g.dart';
part 'state/proxies.dart';
part 'state/navigation.dart';
part 'state/system.dart';
part 'state/theme.dart';
part 'state/profile.dart';
part 'state/custom.dart';
part 'state/custom_import.dart';
