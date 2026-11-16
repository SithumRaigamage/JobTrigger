import 'package:flutter/services.dart';

import '../../domain/tools/tool_catalog.dart';

/// Reads the bundled release manifest (`config/tools.json`) into
/// [ToolCatalog.current]. Called once from `main()` before the first frame.
/// A missing or malformed asset throws, so a broken build fails at launch
/// instead of offering the wrong tools.
Future<void> loadToolCatalog([AssetBundle? bundle]) async {
  ToolCatalog.current = ToolCatalog.parse(
    await (bundle ?? rootBundle).loadString('config/tools.json'),
  );
}
