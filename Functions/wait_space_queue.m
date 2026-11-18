function wait_space_queue(cfg)
% WAIT_SPACE_QUEUE - Waits for SPACE, read through the key queues (Day 1 start/resume screen)
%
% Uses the same key queues as the blocks (kb_queue), so the start screen only
% continues if a space press reaches the queues. If space does nothing here,
% space presses during the blocks would not be recorded either, so this is
% found before the session instead of afterwards. ESC stops the session
% (error 'session:quit').

fprintf(['Start screen: waiting for SPACE. If the participant presses space and nothing ' ...
         'happens, the key queue does not receive that keyboard - stop with ESC and check.\n']);

KbReleaseWait(cfg.deviceIndex);       % a key still held from before does not count
kb_queue('start');
cleanup = onCleanup(@() kb_queue('stop')); %#ok<NASGU>
while true
    [pressed, first_press] = kb_queue('check');
    if pressed
        if first_press(cfg.keys.Quit)
            error('session:quit', 'Session stopped with ESC.');
        end
        if first_press(cfg.keys.respond)
            return;
        end
    end
    WaitSecs(0.005);
end
end
