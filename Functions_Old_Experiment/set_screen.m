function [Screen_struct, window] = set_screen(ID, W, vdist)
%% Screen setup
screens = Screen('Screens');
if ID == 1
    screen_ID = min(screens);
elseif ID == 2
    screen_ID = max(screens);
end

white = WhiteIndex(screen_ID);

if W == 0

    [window, windowRect] = PsychImaging('OpenWindow', screen_ID, white/2);

    Screen('FillRect', window, [0 0 0], [0 0 1 1]); % zero trigger pixel
    Screen('Flip', window); % flip to clear

    topPriorityLevel = MaxPriority(window);

    Priority(topPriorityLevel);

    [center_X, center_Y] = RectCenter(windowRect);

    ifi = Screen('GetFlipInterval', window);

    [w_screen, h_screen] = Screen('DisplaySize', screen_ID);


elseif W == 1

    % Define window size (windowed mode)
    winWidth  = 900;
    winHeight = 700;
    screenRect = [0 0 winWidth winHeight];  % top-left corner at (0,0)

    [window, windowRect] = PsychImaging('OpenWindow', screen_ID, white/2, screenRect);

    Screen('FillRect', window, [0 0 0], [0 0 1 1]); % zero trigger pixel
    Screen('Flip', window); % flip to clear

    [center_X, center_Y] = RectCenter(windowRect);

    ifi = Screen('GetFlipInterval', window);

    [w_screen, h_screen] = Screen('DisplaySize', screen_ID);


end

[pixperdeg, ~] = VisAng([w_screen/10, h_screen/10] , [windowRect(3), windowRect(4)], vdist);

Screen_struct = struct('screen_ID', screen_ID, 'white', white, 'windowRect',windowRect,'center_X', center_X, 'center_Y', center_Y, ...
    'ifi', ifi, 'width', w_screen, 'height', h_screen, 'pixperdeg', pixperdeg);



end