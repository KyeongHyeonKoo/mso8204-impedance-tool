function [t, y] = mso8204_read_waveform_tcp(d, channel)
%MSO8204_READ_WAVEFORM_TCP Read one channel over raw TCP socket.

% Clear stale bytes from any previous query before starting a new waveform
% transfer. This is especially important for raw sockets after timeouts.
pause(0.02);
if d.NumBytesAvailable > 0
    read(d, d.NumBytesAvailable, "uint8");
end

writeline(d, sprintf(":CHANnel%d:DISPlay ON", channel));
pause(0.05);
writeline(d, sprintf(":WAVeform:SOURce CHANnel%d", channel));
pause(0.05);
writeline(d, ":WAVeform:MODE NORMal");
writeline(d, ":WAVeform:FORMat BYTE");
try
    writeline(d, ":WAVeform:POINts 1000");
catch
end
try
    writeline(d, ":WAVeform:STARt 1");
    writeline(d, ":WAVeform:STOP 1000");
catch
end
pause(0.05);

writeline(d, ":WAVeform:PREamble?");
pre = strtrim(readline(d));
p = str2double(split(pre, ","));
if numel(p) < 10 || any(isnan(p(5:10)))
    error("Could not parse waveform preamble: %s", pre);
end

xincrement = p(5);
xorigin = p(6);
xreference = p(7);
yincrement = p(8);
yorigin = p(9);
yreference = p(10);

writeline(d, ":WAVeform:DATA?");
raw = local_read_ieee_block(d);

raw = double(raw(:));
y = (raw - yorigin - yreference) * yincrement;
n = numel(y);
t = ((0:n-1)' - xreference) * xincrement + xorigin;
end

function data = local_read_ieee_block(d)
% Read SCPI definite-length binary block: #<nDigits><length><payload>.

header = local_read_exact(d, 2);
if numel(header) < 2 || char(header(1)) ~= '#'
    error("Waveform data did not start with IEEE block header.");
end

nDigits = str2double(char(header(2)));
if isnan(nDigits) || nDigits <= 0
    error("Unsupported IEEE block header.");
end

lenBytes = local_read_exact(d, nDigits);
nData = str2double(char(lenBytes(:)'));
if isnan(nData) || nData <= 0
    error("Invalid IEEE block payload length.");
end

data = local_read_exact(d, nData);

% Consume optional LF terminator.
pause(0.01);
if d.NumBytesAvailable > 0
    read(d, d.NumBytesAvailable, "uint8");
end
end

function bytes = local_read_exact(d, nBytes)
% Read exactly nBytes from a TCP stream, allowing the payload to arrive in
% chunks. A single read(..., nBytes) can time out on Rigol waveform blocks.

bytes = zeros(1, nBytes, 'uint8');
offset = 1;
lastProgress = tic;
maxIdleSeconds = max(10, d.Timeout);

while offset <= nBytes
    available = d.NumBytesAvailable;
    remaining = nBytes - offset + 1;

    if available > 0
        chunkCount = min(available, remaining);
        chunk = read(d, chunkCount, "uint8");
        got = numel(chunk);
        if got > 0
            bytes(offset:offset+got-1) = chunk(:).';
            offset = offset + got;
            lastProgress = tic;
        end
    else
        pause(0.005);
    end

    if toc(lastProgress) > maxIdleSeconds
        error("Timed out while reading waveform block: got %d of %d bytes.", offset - 1, nBytes);
    end
end
end
