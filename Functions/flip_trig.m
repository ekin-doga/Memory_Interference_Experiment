function vbl = flip_trig(win, cfg, code, when)
% FLIP_TRIG - Screen('Flip') with the EEG trigger pixel. Use it for EVERY flip.
%
% Draw the screen as usual, then call flip_trig instead of Screen('Flip').
% Because every flip draws the pixel, a flip without a trigger cannot send
% the gray background (= code 6) by accident.
%
%   code = 0 -> black pixel (no trigger), one normal flip
%   code > 0 -> the frame shown at 'when' sends the code; the next frame
%               shows the same picture with the pixel back at 0. The trigger
%               lines therefore always go 0 -> code -> 0 (no mixed codes),
%               and each code lasts exactly one frame.
%
% INPUTS:
%   win  - PTB window
%   cfg  - config from get_cfg (cfg.triggers)
%   code - trigger code 0-255 (codes are defined in get_cfg)
%   when - optional, as in Screen('Flip', win, when); default 0 (next frame)
%
% OUTPUT:
%   vbl  - onset of the frame that sent the code (as Screen('Flip') returns it)
%
% Note: with code > 0 this returns one frame after the onset, because it
% waits for the reset frame. Timing that is planned from vbl is not affected.

if nargin < 4
    when = 0;
end

draw_trigger(win, cfg, code);
if code == 0
    vbl = Screen('Flip', win, when);
else
    vbl = Screen('Flip', win, when, 1);     % 1 = keep the picture for the reset frame
    draw_trigger(win, cfg, 0);
    Screen('Flip', win, vbl + 0.5 * Screen('GetFlipInterval', win));
end
end
