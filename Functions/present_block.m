function seq = present_block(E, seq, b)
% PRESENT_BLOCK - Shows all trials of block b
%
% Each trial: image (cfg.stim_dur) with fixation point, then fixation point
% only for the trial's ISI. Starts with 1 s of fixation. Stores the measured
% onset/offset of each image in seq, saves results.mat, and prints the
% measured image durations.
%
% INPUTS:
%   E - struct from run_encoding (win, scr, cfg, tex, img_rect, ...)
%   seq - trial sequence (from create_sequence)
%   b   - block number
%
% ESC during the block stops the session (error 'encoding:quit').

cfg    = E.cfg;
win    = E.win;
ifi    = E.scr.ifi;
trials = find(seq.block == b)';

E.draw_fix();
vbl = Screen('Flip', win);
next_onset = vbl + 1.0;                       % 1 s fixation before the block

for t = trials
    % image + fixation point
    Screen('DrawTexture', win, E.tex(t), [], E.img_rect);
    E.draw_fix();
    seq.onset(t) = Screen('Flip', win, next_onset - ifi/2);

    % fixation point only, after stim_dur
    E.draw_fix();
    seq.offset(t) = Screen('Flip', win, seq.onset(t) + cfg.stim_dur - ifi/2);
    next_onset = seq.offset(t) + seq.ISI(t);

    % check for ESC while waiting
    while GetSecs < next_onset - 0.05
        [down, ~, code] = KbCheck(cfg.deviceIndex);
        if down && code(cfg.keys.Quit)
            error('encoding:quit', 'Session stopped with ESC (block %d, trial %d).', b, t);
        end
        WaitSecs(0.001);
    end
end

% save after every block
scr = E.scr;  stim_list = E.stim_list; %#ok<NASGU>
save(E.results_file, 'seq', 'cfg', 'scr', 'stim_list');

dur = seq.offset(trials) - seq.onset(trials);
fprintf('Block %d (%s) done. Image duration: mean %.3f s, min %.3f, max %.3f\n', ...
    b, seq.condition{trials(1)}, mean(dur), min(dur), max(dur));
end
