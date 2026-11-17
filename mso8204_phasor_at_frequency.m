function V = mso8204_phasor_at_frequency(t, y, f, method)
%MSO8204_PHASOR_AT_FREQUENCY Estimate complex sine phasor at known frequency.
%
% Model:
%   y(t) = dc + a*cos(wt) + b*sin(wt)
% Phasor convention:
%   real(y) ~= real(V * exp(1j*w*t))
% Therefore V = a - j*b.
%
% method:
%   "sinefit"         - least-squares sine fit at f. Good default.
%   "lockin_windowed" - Fourier/lock-in extraction at f with a Hann window.

t = t(:);
y = y(:);
if nargin < 4 || isempty(method)
    method = "sinefit";
end

w = 2*pi*f;

switch string(method)
    case "sinefit"
        y = y - mean(y, "omitnan");
        A = [cos(w*t), sin(w*t), ones(size(t))];
        coef = A \ y;
        a = coef(1);
        b = coef(2);
        V = a - 1j*b;

    case "lockin_windowed"
        y = y - mean(y, "omitnan");
        n = numel(y);
        if n < 4
            error("Not enough samples for phasor extraction.");
        end
        win = 0.5 - 0.5*cos(2*pi*(0:n-1)'/(n-1));  % Hann window.
        V = 2 * sum(win .* y .* exp(-1j*w*t), "omitnan") / sum(win, "omitnan");

    otherwise
        error("Unknown phasor method: %s", method);
end
end
