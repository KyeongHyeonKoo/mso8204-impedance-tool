function [t, y1, y2] = mso8204_align_waveforms(t1, y1in, t2, y2in)
%MSO8204_ALIGN_WAVEFORMS Put two channel waveforms on one time grid.

if numel(t1) == numel(t2) && max(abs(t1 - t2)) < 10*eps(max(abs(t1)) + 1)
    t = t1(:);
    y1 = y1in(:);
    y2 = y2in(:);
    return;
end

tStart = max(min(t1), min(t2));
tStop = min(max(t1), max(t2));
n = min(numel(t1), numel(t2));
t = linspace(tStart, tStop, n)';
y1 = interp1(t1(:), y1in(:), t, "linear", "extrap");
y2 = interp1(t2(:), y2in(:), t, "linear", "extrap");
end
