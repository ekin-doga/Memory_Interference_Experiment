function [screen_cfg, window] = set_screen(ID, W, cfg)
% SET_SCREEN - Opens the PTB window and returns screen settings
%
% INPUTS:
%   ID  - 1 = main screen (lowest number), 2 = external screen (highest number)
%   W   - 0 = fullscreen (for the experiment), 1 = 900x700 window (for testing)
%   cfg - config from get_cfg (uses cfg.bg_rgb, cfg.refresh_hz, cfg.vdist,
%         cfg.screen_width_cm, cfg.triggers; durations for the frame check)
%
% Fullscreen with cfg.refresh_hz set: the display is switched to that rate
% first (display_mode); run_encoding/run_memory switch it back after sca.
%
% OUTPUTS:
%   screen_cfg - struct with screen_ID, bg, white, windowRect, center_X,
%                center_Y, ifi, width_cm, res_px, pixperdeg
%   window     - PTB window pointer
%
% Colors are in the 0-1 range (PsychDefaultSetup(2)): black = 0, white = 1.

PsychDefaultSetup(2);

screens = Screen('Screens');
if ID == 1
    screen_ID = min(screens);
else
    screen_ID = max(screens);
end

white = WhiteIndex(screen_ID);   % 1 with PsychDefaultSetup(2)
bg    = cfg.bg_rgb / 255 * white; % gray background (cfg.bg_rgb is 0-255, exact on an 8-bit display)

if W == 0
    % Fullscreen: refresh rate from cfg, strict timing checks, top priority, no cursor
    if ~isempty(cfg.refresh_hz)
        display_mode('set', screen_ID, cfg.refresh_hz);
    end
    Screen('Preference', 'SkipSyncTests', 0);
    [window, windowRect] = PsychImaging('OpenWindow', screen_ID, bg);
    Priority(MaxPriority(window));
    HideCursor(screen_ID);
else
    % Windowed (testing only): timing is not reliable here
    Screen('Preference', 'SkipSyncTests', 1);
    [window, windowRect] = PsychImaging('OpenWindow', screen_ID, bg, [0 0 900 700]);
end

% trigger pixel to 0 straight away: until something draws it, it shows the
% background colour, which the ViewPixx would send as a trigger
flip_trig(window, cfg, 0);

[center_X, center_Y] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);
check_refresh(cfg, ifi, W);

% Pixels per degree: always from the FULL screen resolution and the
% physical screen width, also in windowed mode (a window is just a cut-out
% of the same pixels)
full_rect = Screen('Rect', screen_ID);
if isempty(cfg.screen_width_cm)
    [w_mm, ~] = Screen('DisplaySize', screen_ID);
    width_cm  = w_mm / 10;
    warning('cfg.screen_width_cm is empty; using the size reported by the system (%.1f cm). Measure it for the real setup.', width_cm);
else
    width_cm = cfg.screen_width_cm;
end
pixperdeg = VisAng(width_cm, full_rect(3), cfg.vdist);

screen_cfg = struct('screen_ID', screen_ID, 'bg', bg, 'white', white, ...
    'windowRect', windowRect, 'center_X', center_X, 'center_Y', center_Y, ...
    'ifi', ifi, 'width_cm', width_cm, 'res_px', full_rect(3:4), ...
    'pixperdeg', pixperdeg);

fprintf('Screen %d: %d x %d px, %.1f cm wide, %.1f cm away -> %.1f px/deg, %.1f Hz\n', ...
    screen_ID, full_rect(3), full_rect(4), width_cm, cfg.vdist, pixperdeg, 1/ifi);
end


function check_refresh(cfg, ifi, W)
% CHECK_REFRESH - Screen must run at cfg.refresh_hz; durations should fit whole frames
hz = 1 / ifi;
if ~isempty(cfg.refresh_hz) && abs(hz - cfg.refresh_hz) > 1
    msg = sprintf('The screen runs at %.1f Hz, but cfg.refresh_hz = %g.', hz, cfg.refresh_hz);
    if W == 0
        error('set_screen:refresh', '%s Switching the display did not work; set it to %g Hz in the display settings.', ...
            msg, cfg.refresh_hz);
    end
    warning('set_screen:refresh', '%s (windowed test: nothing is switched, continuing)', msg);
end

% every duration should be a whole number of frames, otherwise it is rounded
% to the next frame on screen
durs = [cfg.stim_dur, cfg.ISI_vals, cfg.catch.isi, cfg.block_start_fix, ...
        cfg.mem.img_dur, cfg.mem.isi, cfg.mem.iti];
frames = durs / ifi;
off = abs(frames - round(frames)) > 0.05;
if any(off)
    warning('set_screen:frames', ['At %.1f Hz these durations are not whole frames and ' ...
        'will be rounded on screen: %s s'], hz, mat2str(durs(off), 4));
end
end
