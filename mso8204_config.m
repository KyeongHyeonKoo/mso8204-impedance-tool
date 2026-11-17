function cfg = mso8204_config()
%MSO8204_CONFIG User-editable settings for scope-based impedance sweep.
%
% Enter the host in mso8204_launcher, or set MSO8204_IP for command-line use.

cfg.ip = strtrim(string(getenv("MSO8204_IP")));
cfg.resource = "TCPIP0::" + cfg.ip + "::5555::SOCKET";

% Sweep settings.
cfg.fStart = 10e3;
cfg.fStop = 100e3;
cfg.nPoints = 100;
cfg.spacing = "linear";  % "linear" or "log"

% Shunt resistor in ohms. Use the measured value, not only the nominal value.
cfg.rShunt = 390.0;

% Generator settings. These commands may need small edits after checking the
% MSO8000A programming manual. They are intentionally isolated here.
cfg.controlGenerator = true;
cfg.sourceChannel = 1;
cfg.sourceVpp = 5.0;
cfg.sourceOffset = 0.0;
cfg.awgFunctionCmd = ":SOURce%d:FUNCtion SINusoid";
cfg.awgFrequencyCmd = ":SOURce%d:FREQuency %.12g";
cfg.awgAmplitudeCmd = ":SOURce%d:VOLTage %.12g";
cfg.awgOffsetCmd = ":SOURce%d:VOLTage:OFFSet %.12g";
cfg.awgOutputOnCmd = ":OUTPut%d ON";
cfg.awgOutputOffCmd = ":OUTPut%d OFF";

% Oscilloscope acquisition settings.
cfg.chTotal = 1;  % CH1 measures generator/output side of coil+shunt.
cfg.chShunt = 2;  % CH2 measures shunt voltage to ground.
cfg.chTotalMultiplier = 1.0;  % Use 10 if CH1 is physically 10X but scope is set to 1X.
cfg.chShuntMultiplier = 1.0;  % Use 10 if CH2 is physically 10X but scope is set to 1X.
cfg.chShuntDelaySeconds = 0.0;  % Physical CH2 delay correction in seconds.
cfg.chShuntPhaseOffsetDeg = 0.0;  % Rs-targeted constant CH2 phase correction.
cfg.phasorMethod = "lockin_windowed";  % "sinefit" or "lockin_windowed".
cfg.cyclesToCapture = 20;
cfg.minSamplesPerCycle = 80;
cfg.maxWaveformPoints = 250000;
cfg.setTimebase = true;
cfg.setVerticalScale = false;
cfg.ch1Scale = 1.0;
cfg.ch2Scale = 0.2;

% Timing. Passive circuits settle quickly, but scope/AWG/UI need margin.
cfg.settleSeconds = 1.0;

% Output.
cfg.outputXlsx = fullfile(pwd, "mso8204_impedance_sweep.xlsx");
cfg.outputMat = fullfile(pwd, "mso8204_impedance_sweep_raw.mat");
cfg.calibrationMat = fullfile(pwd, "mso8204_known_resistor_calibration.mat");
cfg.useCalibration = false;

% Debug.
cfg.verbose = true;
end
