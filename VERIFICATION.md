# Verification

Target: Gen1Recomp 0.3.22, Pokemon FireRed (USA) 1.0.

- Manifest/content lint: passed (`modkit lint`).
- LuaJIT compilation and service-rule tests: passed under LÖVE 11.5.
- Real-engine entry-load smoke test: passed against the 0.3.22 modules.
- Celadon Dept. Store 2F NPC spawn: passed against the supplied ROM cache;
  the chosen cell was verified walkable and the spawned graphics ID was the
  native FireRed Gentleman.
- ROM evolution table: Kadabra -> Alakazam trade evolution passed.
- Everstone prevention: passed.
- Held-item trade evolution: Scyther + Metal Coat -> Scizor passed, including
  native Metal Coat consumption.
- Service charge boundary tests: ¥1999 rejected without mutation; ¥2000 and
  larger balances deduct exactly ¥2000.
- Supplied ROM size: 16,777,216 bytes.
- Supplied ROM SHA-1: `41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc`.
- Supplied ROM MD5: `e26ee0d44e809351c8ce2d73c7400cdd`.

The strict `modkit validate` Lua runner could not execute because this source
archive does not bundle a standalone `luajit.exe`. The same LuaJIT used by the
bundled LÖVE runtime compiled the package, ran the rule tests, loaded the entry
against the real engine modules, and performed the ROM-backed integration
checks successfully.
