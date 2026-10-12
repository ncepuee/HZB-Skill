# Tektronix Waveform Acquisition Notes

Use this reference only when the user requests raw sample acquisition or detailed waveform interpretation. The exact instrument's programmer manual and the live waveform preamble are authoritative; examples below are patterns, not a promise that every model supports the same commands or transport.

## Select a transport and verify it

1. Prefer the connection method documented for the exact model: VISA over the supported LAN interface, LXI/eScope for browser viewing, or a documented raw SCPI socket if that model exposes one.
2. Do not assume a universal TCP port, URI, line terminator, byte order, timeout, or instrument-control library. Obtain it from the user or the model manual.
3. Open one session, use a short bounded timeout, query identity, and verify the response belongs to the requested instrument. Redact serial/asset identifiers in logs and reports.
4. If a query times out, close the session cleanly and diagnose the selected transport, termination, network route, and instrument state. Ping and HTTP checks are separate from VISA/SCPI checks. Do not repeatedly issue commands to an unresponsive live instrument.

## Read a waveform safely

Before issuing commands, decide whether they are read-only queries or commands that change instrument/transfer state. A direct request to acquire data authorizes only the minimum changes required for that acquisition; it does not authorize AutoSet, reset, stopping an unrelated run, clearing memory, changing physical probe settings, or saving a persistent instrument setup.

For models whose manual documents these command groups, waveform retrieval commonly involves:

1. Select the requested waveform source and transfer range.
2. Set/verify the documented encoding, point width, signedness, and byte order only when needed.
3. Query the waveform preamble for point count, units, time increment/origin, and vertical scale/offset fields.
4. Retrieve the payload using the documented waveform query (often `CURVE?`; some models provide a query that also returns the preamble).
5. Validate the IEEE 488.2 block header, declared byte count, expected point width/count, and optional terminator before decoding. Do not split a binary payload as comma-separated text or silently discard bytes.
6. Convert samples using the exact model's documented equation and preamble. Preserve raw codes and preamble so the conversion can be reproduced.

Tektronix's 3 Series MDO Programmer Manual documents waveform transfer through the `DATA`/`WFMOutpre` command groups and IEEE 488.2 binary blocks. For that model family, its time-domain example defines the sample time as `XZERO + XINCR × (i - 1)` and amplitude as `YZERO + YMULT × DataPoint_i` with a one-based sample index. Do not copy that equation blindly to another family, waveform domain, or encoding; follow its manual and cross-check with the scope's own measurement/cursor.

## Validate the data

- Compare payload length and decoded sample count with the preamble and requested record range.
- Check time monotonicity, finite values, units, polarity, min/max, and clipping; verify the resulting time span against the displayed timebase.
- Compare basic metrics (such as peak-to-peak or RMS) with a scope readout or known test signal. Differences may indicate probe attenuation, channel offset, wrong data width/sign, byte order, transfer truncation, averaging, or acquisition-mode mismatch.
- For multiple channels, confirm that samples refer to a common acquisition/time base before calculating phase, instantaneous power, or cross-channel correlation.
- Save raw samples separately from processed results; include a sidecar metadata file with model family/firmware, channel, units, probe ratio, preamble, sample count, acquisition mode, and analysis settings. Omit IP addresses, serial numbers, credentials, and personal paths from shareable artifacts.

## Choose analysis appropriate to the record

- **RMS/frequency/phase:** state whether values are total-signal or fundamental-only, the time interval/cycle count, and how DC and transients were handled.
- **FFT/THD:** use the actual sample interval to calculate sample rate and Nyquist frequency; state window, detrending, coherent-gain/amplitude correction, fundamental bin selection, harmonic range, and THD definition. Check that record length and sampling mode support the requested bandwidth.
- **Power:** use synchronized voltage and current samples, correct units and transducer ratios, and compute average instantaneous power over an explicitly stated steady-state interval. Do not infer active power from independent RMS values alone when phase or distortion matters.
- **Transient response:** state trigger reference/time zero, pre-trigger interval, settling/rise/overshoot definitions, and whether any samples were decimated or envelope-detected.

## Authoritative sources

- [Tektronix 3 Series MDO Oscilloscopes Programmer Manual](https://download.tek.com/manual/3-MDO-Oscilloscope-Programmer-Manual-077149800.pdf) — waveform transfer, preamble, binary-block structure, and scaling examples; use only for models covered by that manual.
- [Tektronix FAQ: How do I program my oscilloscope to get waveform data?](https://www.tek.com/support/faqs/how-do-i-program-my-oscilloscope-get-waveform-data) — distinction between `WAVFRM?` and `CURVE?` and the binary block response.
- [Tektronix FAQ: How do I get a waveform using MATLAB Instrument Control Toolbox?](https://www.tek.com/en/support/faqs/how-do-i-get-waveform-using-instrument-control-toolbox-matlab) — MATLAB connection and waveform retrieval example; verify compatibility with the installed MATLAB/toolbox and instrument.
