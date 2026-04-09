# Third-Party Notices

`DOC-1.0` applies only to the original source files authored for this suite and
its included plugin projects.

This suite depends on, links to, or is generated with third-party components that
remain under their own licenses. Those components are not relicensed under `DOC-1.0`.

## Current suite-specific notes

- The plugin DSP source is authored in Faust and uses functions from the Faust standard libraries.
- Generated standalone and plugin binaries may include generated architecture/runtime code and
  link to third-party system libraries.
- The current standalone build uses the Faust `faust2jack` JACK/GTK architecture path.
- Linked runtime dependencies for the current standalone builds include JACK and GTK/GLib-family libraries.
- The VST2 build path depends on the legacy Steinberg VST2 SDK and may carry separate licensing constraints.

## Project policy

- Do not assume that all generated code is covered exclusively by `DOC-1.0`.
- Do not assume that linked libraries are relicensed by this project.
- Any third-party component retains its original license.
- Distribution of binaries must comply with the licenses of all linked or embedded third-party components.

## Recommended release practice

- Ship this file together with binary releases.
- Ship `BINARY_LICENSE_NOTICE.txt` together with binary releases.
- Review the Faust-generated metadata for imported library licenses before release.
- Avoid introducing GPL or AGPL Faust library dependencies into released DSP code unless intentionally accepted.
