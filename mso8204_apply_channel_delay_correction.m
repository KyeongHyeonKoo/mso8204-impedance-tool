function Vcorr = mso8204_apply_channel_delay_correction(V, f, delaySeconds, phaseOffsetDeg)
%MSO8204_APPLY_CHANNEL_DELAY_CORRECTION Correct CH2 phase.
%
% delaySeconds is CH2 delay relative to CH1.
% Positive delay means CH2 lags CH1.
% phaseOffsetDeg is an additional constant CH2 phase correction in degrees.
%
% Phasor convention in this project:
%   y(t) = real(V * exp(1j*2*pi*f*t))
%
% If CH2 lags by tau, measured V is Vtrue*exp(-j*w*tau), so correction is
% multiplication by exp(+j*w*tau).

if nargin < 3 || isempty(delaySeconds)
    delaySeconds = 0;
end
if nargin < 4 || isempty(phaseOffsetDeg)
    phaseOffsetDeg = 0;
end

Vcorr = V .* exp(1j * (2*pi*f * delaySeconds + deg2rad(phaseOffsetDeg)));
end
