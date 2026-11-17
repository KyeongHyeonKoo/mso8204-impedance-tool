function mso8204_set_generator_frequency(dev, cfg, f)
%MSO8204_SET_GENERATOR_FREQUENCY Set generator frequency for step sweep.

writeline(dev, sprintf(cfg.awgFrequencyCmd, cfg.sourceChannel, f));
mso8204_log_error(dev, "set generator frequency");
end
