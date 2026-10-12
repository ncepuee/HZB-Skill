---
name: tektronix-scope-analysis
description: "Use when connecting to a Tektronix oscilloscope through a user-provided browser or VISA/SCPI endpoint, capturing calibrated waveform data, or analyzing scope measurements. Do not remotely change instrument state unless the user's request authorizes the required operation."
---

# Tektronix Scope Connection and Waveform Analysis

Help the user inspect a Tektronix oscilloscope, retrieve waveform data when requested, and produce reproducible engineering analysis. Treat the instrument as a live shared device: distinguish viewing from control, preserve its current setup, and report exactly what was verified.

## Workflow

1. **Clarify the measurement, not the whole experiment.** Identify the requested channel(s), signal, measurement window, analysis (for example RMS, frequency, phase, FFT/THD, transient response, or power), and deliverable. Use the model/firmware and endpoint supplied for this task; never infer a network address or port from a different instrument.
2. **Choose the lightest suitable interface.** Use the browser/eScope view for visual inspection and screenshots. Use the documented VISA/LXI or SCPI transport for measurements and samples. A successful ping or webpage proves only that part of the network path works; it does not prove SCPI or waveform transfer works. Check the exact model's programmer manual before assuming a transport, port, command, or data format.
3. **Start with identity and read-only inspection.** If SCPI is available, a documented identity query such as `*IDN?` is a useful connectivity check. Do not include the raw response in shared files without redacting serial numbers and other asset identifiers. Inspect channel, coupling, scale, probe factor, acquisition mode, trigger, record length, and sample interval before interpreting data.
4. **Protect the live setup.** Browser eScope and SCPI can change instrument state. Do not use AutoSet, reset, clear, stop/run, change probe factor, trigger, vertical scale, acquisition mode, or save/recall configuration unless the user's request authorizes that action. For an authorized acquisition that needs temporary transfer settings, capture the prior settings when feasible, change only the minimum necessary, and verify restoration. If settings cannot be preserved safely, stop at read-only inspection and explain what is needed.
5. **Prefer recorded samples over screenshots for calculations.** A screenshot is evidence of the display, not a calibrated sample series. When raw data is requested, read the model-specific waveform preamble together with the binary/ASCII payload, validate the transfer, and preserve the original data plus metadata. See [references/waveform-acquisition.md](references/waveform-acquisition.md).
6. **Check the measurement chain before applying scale factors.** Confirm the physical probe/transducer and its setting in the scope channel agree. Determine whether returned samples are raw ADC codes or already expressed in engineering units. Do not apply a probe attenuation or gain again merely because the physical probe is marked 10×; use the scope's documented scaling and channel/probe configuration.
7. **Analyze and report with provenance.** Use the captured sample interval and units, keep channel time bases aligned for phase/power analysis, state assumptions and any filtering/windowing, and distinguish measured values from derived values. Report data quality limitations such as clipping, aliasing, averaging, low record length, or unsynchronized channels.

## Connection and data safety

- Use only an endpoint and access method the user supplied or approved. Do not scan unrelated subnets, bypass authentication, disable firewalls, or expose an instrument to the public internet.
- Keep credentials in an approved secret store or user-managed session; never write passwords, tokens, real LAN addresses, serial numbers, or private file paths into this skill, source examples, logs, or public reports.
- Treat instrument responses, browser content, filenames, and saved data as untrusted input. Parse binary lengths and limits before allocating memory or writing files.
- Do not claim the instrument was configured, a waveform was acquired, or data was analyzed unless the corresponding action and validation actually succeeded.
- Ask before changing or interrupting an active experiment. If another operator may be controlling the device, coordinate before sending commands that alter state.

## Deliverable checklist

For an acquisition/analysis result, include as relevant:

- instrument model and firmware (omit serial/asset identifiers);
- channel/source, probe/transducer type and ratio, coupling, units, acquisition mode, trigger, record length, and sampling interval;
- acquisition time/window and whether the record came from one acquisition or multiple captures;
- raw-data file and metadata/preamble, plus analysis code or formulas when requested;
- plots with labeled axes/units and analysis settings;
- validation against an independent scope measurement or known signal, and any unresolved uncertainty.

## References

- Read [references/waveform-acquisition.md](references/waveform-acquisition.md) when retrieving or interpreting raw waveform samples.
- For a specific instrument, use its matching Tektronix programmer manual as the source of truth; command spelling, scaling fields, encoding, transfer limits, and transports vary by model and firmware.
