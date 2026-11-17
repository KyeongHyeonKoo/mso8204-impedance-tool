function result = mso8204_easy_impedance_sweep(cfg, updatePlot)
%MSO8204_EASY_IMPEDANCE_SWEEP Sweep frequency using raw TCP, then save Excel.
%
% Before running this, verify generator commands with:
%   mso8204_easy_generator_test(10000, 20000)
%
% Then run:
%   mso8204_easy_impedance_sweep
%   result = mso8204_easy_impedance_sweep(cfg)
%   result = mso8204_easy_impedance_sweep(cfg, updatePlot)

if nargin < 1
    cfg = mso8204_config();
end
if cfg.spacing == "log"
    freqs = logspace(log10(cfg.fStart), log10(cfg.fStop), cfg.nPoints);
else
    freqs = linspace(cfg.fStart, cfg.fStop, cfg.nPoints);
end

d = tcpclient(cfg.ip, 5555, "Timeout", 60);
configureTerminator(d, "LF");

writeline(d, "*IDN?");
idn = strtrim(readline(d));
fprintf("Connected: %s\n", idn);
if isfield(cfg, "expectedIdn") && ~strcmp(idn, cfg.expectedIdn)
    error("MSO8204:UnexpectedInstrument", ...
        "Instrument identity changed. Run Test Connection again.");
end

if isfield(cfg, "turnOffGeneratorOnExit") && cfg.turnOffGeneratorOnExit
    outputCleanup = onCleanup(@() turnOffGenerator(d, cfg));
end

fprintf("Configuring generator...\n");
mso8204_setup_generator(d, cfg);

cal = [];
if cfg.useCalibration
    if isfile(cfg.calibrationMat)
        tmp = load(cfg.calibrationMat, "cal");
        cal = tmp.cal;
        fprintf("Using calibration: %s\n", cfg.calibrationMat);
    else
        warning("Calibration requested but file was not found: %s", cfg.calibrationMat);
    end
end

n = numel(freqs);
Frequency_Hz = freqs(:);
Vtotal = complex(nan(n, 1), nan(n, 1));
Vshunt = complex(nan(n, 1), nan(n, 1));
Icoil = complex(nan(n, 1), nan(n, 1));
Vcoil = complex(nan(n, 1), nan(n, 1));
Z = complex(nan(n, 1), nan(n, 1));
Rs_Ohm = nan(n, 1);
X_Ohm = nan(n, 1);
Rp_Ohm = nan(n, 1);
Inductance_H = nan(n, 1);
Q = nan(n, 1);

if nargin < 2 || isempty(updatePlot)
    figure("Name", "MSO8204 Easy Impedance Sweep");
    tiledlayout(2, 2);
    updatePlot = mso8204_sweep_charts([nexttile, nexttile, nexttile, nexttile]);
end
updatePlot([], zeros(0, 5));

for k = 1:n
    f = freqs(k);
    fprintf("[%3d/%3d] %.6g Hz\n", k, n, f);

    mso8204_set_generator_frequency(d, cfg, f);
    mso8204_prepare_scope_for_frequency(d, cfg, f);
    pause(cfg.settleSeconds);
    writeline(d, ":STOP");
    pause(0.3);

    [t1, y1] = mso8204_read_waveform_tcp(d, cfg.chTotal);
    [t2, y2] = mso8204_read_waveform_tcp(d, cfg.chShunt);
    y1 = y1 * cfg.chTotalMultiplier;
    y2 = y2 * cfg.chShuntMultiplier;
    [t, vTotal, vShunt] = mso8204_align_waveforms(t1, y1, t2, y2);

    Vtotal(k) = mso8204_phasor_at_frequency(t, vTotal, f, cfg.phasorMethod);
    Vshunt(k) = mso8204_phasor_at_frequency(t, vShunt, f, cfg.phasorMethod);
    Vshunt(k) = mso8204_apply_channel_delay_correction( ...
        Vshunt(k), f, cfg.chShuntDelaySeconds, cfg.chShuntPhaseOffsetDeg);
    Icoil(k) = Vshunt(k) / cfg.rShunt;
    Vcoil(k) = Vtotal(k) - Vshunt(k);
    Zraw = Vcoil(k) / Icoil(k);
    if ~isempty(cal)
        corr = interp1(cal.Frequency_Hz, cal.Correction, f, "linear", "extrap");
        Z(k) = Zraw * corr;
    else
        Z(k) = Zraw;
    end

    Rs_Ohm(k) = real(Z(k));
    X_Ohm(k) = imag(Z(k));
    Rp_Ohm(k) = Rs_Ohm(k) + X_Ohm(k)^2 / Rs_Ohm(k);
    Inductance_H(k) = X_Ohm(k) / (2*pi*f);
    Q(k) = X_Ohm(k) / Rs_Ohm(k);

    samples = 1:k;
    updatePlot(Frequency_Hz(samples), [abs(Z(samples)), Rs_Ohm(samples), ...
        X_Ohm(samples), Inductance_H(samples), Rp_Ohm(samples)]);
    drawnow;
end

result = table( ...
    Frequency_Hz, ...
    real(Vtotal), imag(Vtotal), abs(Vtotal), angle(Vtotal), ...
    real(Vshunt), imag(Vshunt), abs(Vshunt), angle(Vshunt), ...
    real(Icoil), imag(Icoil), abs(Icoil), angle(Icoil), ...
    real(Vcoil), imag(Vcoil), abs(Vcoil), angle(Vcoil), ...
    real(Z), imag(Z), abs(Z), angle(Z), ...
    Rs_Ohm, X_Ohm, Rp_Ohm, Inductance_H, Q, ...
    'VariableNames', { ...
    'Frequency_Hz', ...
    'Vtotal_real', 'Vtotal_imag', 'Vtotal_abs', 'Vtotal_phase_rad', ...
    'V_I_testR_real', 'V_I_testR_imag', 'V_I_testR_abs', 'V_I_testR_phase_rad', ...
    'I_real', 'I_imag', 'I_abs', 'I_phase_rad', ...
    'Vcoil_real', 'Vcoil_imag', 'Vcoil_abs', 'Vcoil_phase_rad', ...
    'Z_real', 'Z_imag', 'Z_abs', 'Z_phase_rad', ...
    'Rs_Ohm', 'X_Ohm', 'Rp_Ohm', 'Inductance_H', 'Q' });

writetable(result, cfg.outputXlsx);
save(cfg.outputMat, "cfg", "result");
fprintf("Saved:\n  %s\n  %s\n", cfg.outputXlsx, cfg.outputMat);
end

function turnOffGenerator(device, cfg)
try
    writeline(device, sprintf(cfg.awgOutputOffCmd, cfg.sourceChannel));
catch err
    warning("MSO8204:OutputOffFailed", ...
        "Could not send generator OFF. Check the instrument directly: %s", err.message);
end
end
