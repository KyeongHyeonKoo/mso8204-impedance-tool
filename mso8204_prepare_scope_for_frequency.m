function mso8204_prepare_scope_for_frequency(dev, cfg, f)
%MSO8204_PREPARE_SCOPE_FOR_FREQUENCY Adjust timebase and acquisition depth.

if cfg.setTimebase
    secondsPerDiv = cfg.cyclesToCapture / f / 10;
    writeline(dev, sprintf(":TIMebase:MAIN:SCALe %.12g", secondsPerDiv));
end

if cfg.setVerticalScale
    writeline(dev, sprintf(":CHANnel%d:SCALe %.12g", cfg.chTotal, cfg.ch1Scale));
    writeline(dev, sprintf(":CHANnel%d:SCALe %.12g", cfg.chShunt, cfg.ch2Scale));
end

% Start acquisition. The caller waits cfg.settleSeconds, then stops before
% reading waveforms. This makes the settling time apply to the captured data.
writeline(dev, ":RUN");
end
