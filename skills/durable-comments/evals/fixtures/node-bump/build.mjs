import * as esbuild from "esbuild";

// site.config.ts is plain TypeScript, imported directly; package.json's build
// script runs node with --experimental-strip-types so this import works.
const { default: config } = await import("./site.config.ts");

await esbuild.build({
  entryPoints: config.entryPoints,
  bundle: true,
  minify: true,
  outdir: "dist",
});
