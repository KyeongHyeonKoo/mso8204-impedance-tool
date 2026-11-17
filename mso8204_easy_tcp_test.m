function idn = mso8204_easy_tcp_test(cfg)
%MSO8204_EASY_TCP_TEST Easiest connection test without VISA.
%
% This uses MATLAB tcpclient directly. It avoids VISA resource discovery.
%
% Run:
%   mso8204_easy_tcp_test
%   idn = mso8204_easy_tcp_test(cfg)

if nargin < 1
    cfg = mso8204_config();
end

fprintf("Opening TCP socket %s:5555 ...\n", cfg.ip);
d = tcpclient(cfg.ip, 5555, "Timeout", 10);
configureTerminator(d, "LF");

writeline(d, "*IDN?");
idn = strtrim(readline(d));
fprintf("Connected: %s\n", idn);

clear d;
fprintf("TCP connection test finished.\n");
end
