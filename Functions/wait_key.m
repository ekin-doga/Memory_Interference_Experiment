function wait_key(cfg)
% WAIT_KEY - Wait for any key press; ESC stops the session
KbReleaseWait(cfg.deviceIndex);
while true
    [down, ~, code] = KbCheck(cfg.deviceIndex);
    if down
        if code(cfg.keys.Quit)
            error('encoding:quit', 'Session stopped with ESC.');
        end
        return;
    end
    WaitSecs(0.001);
end
end
