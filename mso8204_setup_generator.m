function mso8204_setup_generator(dev, cfg)
%MSO8204_SETUP_GENERATOR Configure the embedded AWG/function generator.

ch = cfg.sourceChannel;
writeline(dev, sprintf(cfg.awgFunctionCmd, ch));
writeline(dev, sprintf(cfg.awgAmplitudeCmd, ch, cfg.sourceVpp));
writeline(dev, sprintf(cfg.awgOffsetCmd, ch, cfg.sourceOffset));
writeline(dev, sprintf(cfg.awgOutputOnCmd, ch));
mso8204_log_error(dev, "generator setup");
end
