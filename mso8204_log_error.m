function mso8204_log_error(dev, context)
%MSO8204_LOG_ERROR Query SCPI error queue when supported.

try
    writeline(dev, ":SYSTem:ERRor?");
    err = strtrim(readline(dev));
    if ~startsWith(err, "+0") && ~startsWith(err, "0")
        warning("SCPI error after %s: %s", context, err);
    end
catch
    % Some modes/devices may not support this exact query. Ignore for now.
end
end
