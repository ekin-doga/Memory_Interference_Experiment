function [screen_cfg, window] = set_screen(ID, W, cfg)
% SET_SCREEN - Opens the PTB window and returns screen settings
%
% INPUTS:
%   ID  - 1 = main screen (lowest number), 2 = external screen (highest number)
%   W   - 0 = fullscreen (for the experiment), 1 = 900x700 window (for testing)
%   cfg - config from get_cfg (uses cfg.vdist and cfg.screen_width_cm)
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
bg    = white / 2;               % gray background

if W == 0
    % Fullscreen: strict timing checks, top priority, no cursor
    Screen('Preference', 'SkipSyncTests', 0);
    [window, windowRect] = PsychImaging('OpenWindow', screen_ID, bg);
    Priority(MaxPriority(window));
    HideCursor(screen_ID);
else
    % Windowed (testing only): timing is not reliable here
    Screen('Preference', 'SkipSyncTests', 1);
    [window, windowRect] = PsychImaging('OpenWindow', screen_ID, bg, [0 0 900 700]);
end

Screen('Flip', window);

[center_X, center_Y] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);

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
