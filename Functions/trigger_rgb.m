function rgb = trigger_rgb(code)
% TRIGGER_RGB - Colour (0-255) of the trigger pixel for a trigger code
%
% Same encoding as drawTriggerPixelInternal in
% Functions_Old_Experiment/ViewPixxTrigger.m (ViewPixx pixel mode, BioSemi
% cable with pins 2-9 -> 1-8). Only the encoding is here; draw_trigger
% draws the pixel.
%
% INPUT:
%   code - integer 0-255 (0 = no trigger, black pixel)
% OUTPUT:
%   rgb  - 1x3 in 0-255 (divide by 255 for PTB colours in the 0-1 range)

if ~isscalar(code) || code < 0 || code > 255 || code ~= round(code)
    error('trigger_rgb:range', 'Trigger code must be an integer 0-255 (got %g).', code);
end

bits = dec2bin(code, 24) - '0';   % 24 bits, most significant first
bits = [bits(2:end) 0];           % BioSemi cable shift (pins 2-9 -> 1-8)

% ViewPixx pins carried by each colour channel, in the order of the
% channel's bit values 1, 2, 4, ..., 128
pins = [1, 13,  2, 14,  3, 15,  4, 16;     % red
        5, 17,  6, 18,  7, 19,  8, 20;     % green
        9, 21, 10, 22, 11, 23, 12, 24];    % blue
weights = 2 .^ (0:7);

rgb = zeros(1, 3);
for c = 1:3
    rgb(c) = sum(weights .* bits(25 - pins(c, :)));
end
end
