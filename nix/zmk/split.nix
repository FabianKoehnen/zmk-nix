{ lib
, buildKeyboard
, runCommand
}:

{ name ? "${args.pname}-${args.version}"
, board
, shield ? null
, parts ? [ "left" "right" ]
, centralPart ? (lib.head parts)
, enableZmkStudio ? false
, ... } @ args:

let
  westDeps = args.westDeps or (buildKeyboard ((lib.removeAttrs args [ "parts" "centralPart" ]) // {
    inherit name;
  })).westDeps;
in runCommand name ((lib.removeAttrs args [ "zephyrDepsHash" "westDeps" "westRoot" "config" "enableZmkStudio" "extraWestBuildFlags" "extraCmakeFlags" ]) // {
  inherit board shield parts centralPart westDeps;
  inherit (westDeps) westRoot;
} // (lib.genAttrs parts (part:
  buildKeyboard ((lib.removeAttrs args [ "board" "shield" "parts" "centralPart" "enableZmkStudio" ]) // {
    name = "${name}-${part}";
    board = lib.replaceStrings [ "%PART%" ] [ part ] board;
    shield = if shield != null then lib.replaceStrings [ "%PART%" ] [ part ] shield else shield;
    enableZmkStudio = if part == centralPart then enableZmkStudio else false;
    inherit westDeps;
  })
))) ''
  mkdir $out
  parts=(${builtins.concatStringsSep " " (map (x: "\"${x}\"") parts)})
  for part in "''${parts[@]}"; do
    ln -s ''$(printenv "''$part")/zmk.uf2 $out/zmk_"$part".uf2
    ln -s ''$(printenv "''$part")/zephyr.dts $out/zephyr_"$part".dts
  done
''
