# MSO8204A Impedance Measurement Tool

A MATLAB GUI for frequency-swept impedance measurements with a RIGOL MSO8204A oscilloscope. It checks instrument identity over LAN, acquires two voltage waveforms, estimates their fundamental phasors, and plots impedance magnitude, series resistance and reactance, inductance, and parallel resistance as the sweep runs.

This repository contains the MATLAB implementation only. It does not require Python, the separate RIGOL Control GUI, or LiteVNA software.

## Open the GUI

Requires desktop MATLAB. The application was checked on MATLAB R2025b on Windows. Hardware is **not** required to open the GUI. No executable or separate installer is needed.

1. Download the repository ZIP from **Code > Download ZIP**, or clone the repository.
2. In MATLAB, set the Current Folder to the folder containing `mso8204_launcher.m`.
3. In the MATLAB Command Window, enter:

```matlab
mso8204_launcher
```

The GUI starts disconnected, without a prefilled instrument address.

## Run a Measurement

1. Connect the oscilloscope to the LAN. Connect the circuit as **generator output > device under test > sense resistor > common ground**. CH1 measures the generator-side voltage and CH2 measures the sense-resistor voltage. Verify the wiring and probe settings before enabling the generator.
2. Enter the oscilloscope IP address or hostname and select **Test Connection**. The application queries `*IDN?` on TCP port 5555 and enables **Run Sweep** only after identifying an MSO8204A.
3. Set the start and stop frequencies (kHz), number of points, and the actual sense resistance (ohms). The initial settings are 10-100 kHz, 100 points, and 390 ohms.
4. Select **Run Sweep**, confirm the generator settings, and choose an output folder. The app uses the scope's internal generator and updates four plots in the same window. It saves a timestamped Excel workbook and a MATLAB MAT file.

The calculation uses `I = Vshunt / Rshunt` and `Z = (Vtotal - Vshunt) / I`, where voltages are complex fundamental phasors. The sweep requires an actual instrument; the application does not generate simulated measurements. The GUI and live plot updates were checked without a scope using test data, not as an end-to-end hardware validation of this release.

Generated data files are excluded from version control. A MAT output can include the instrument address and identification response.
