function mseq = run_memory_block(E, mseq, b)
% RUN_MEMORY_BLOCK - Runs all 2AFC trials of memory block b
%
% Each trial:
%   fixation (cfg.mem.iti)
%   -> image 1 (cfg.mem.img_dur) -> fixation (cfg.mem.isi)
%   -> image 2 (cfg.mem.img_dur)
%   -> choice screen: "first or second?", no time limit
%   -> confidence screen: 1-4, no time limit
%
% No breaks within a block (run_memory shows one break between the two
% conditions). Results are saved to E.results_file after every trial, so an
% ESC loses nothing.
%
% Triggers (see draw_trigger, codes in cfg.triggers.mem) are drawn into
% the flip they belong to:
%   image 1 onset, image 2 onset (code says high/low and target/foil),
%   choice screen onset, the choice (sent with the confidence screen, i.e.
%   within one frame of the key press), and the confidence rating (sent with
%   the next fixation screen).
%
% INPUTS:
%   E    - struct from run_memory (win, scr, cfg, tex1, tex2, img_rect, ...)
%   mseq - memory sequence (from create_memory_sequence)
%   b    - block number

cfg  = E.cfg;
m    = cfg.mem;
trig = cfg.triggers.mem;
win  = E.win;
ifi  = E.scr.ifi;
trials = find(mseq.block == b)';
pending = 0;                                    % trigger waiting for the next flip

for k = 1:numel(trials)
    t = trials(k);
    row  = 1 + strcmp(mseq.condition{t}, 'low');                 % 1 = high, 2 = low
    col1 = 2 - mseq.target_first(t);                              % 1 = target, 2 = foil
    col2 = 3 - col1;

    % fixation (inter-trial interval)
    E.draw_fix();  draw_trigger(win, cfg, pending);  pending = 0;
    vbl = Screen('Flip', win);

    % image 1
    Screen('DrawTexture', win, E.tex1(t), [], E.img_rect);
    E.draw_fix();  draw_trigger(win, cfg, trig.img1(row, col1));
    mseq.onset1(t) = Screen('Flip', win, vbl + m.iti - ifi/2);

    % fixation between the images
    E.draw_fix();  draw_trigger(win, cfg, 0);
    mseq.offset1(t) = Screen('Flip', win, mseq.onset1(t) + m.img_dur - ifi/2);

    % image 2
    Screen('DrawTexture', win, E.tex2(t), [], E.img_rect);
    E.draw_fix();  draw_trigger(win, cfg, trig.img2(row, col2));
    mseq.onset2(t) = Screen('Flip', win, mseq.offset1(t) + m.isi - ifi/2);

    % choice screen (replaces image 2)
    DrawFormattedText(win, m.choice_text, 'center', 'center', 0);
    draw_trigger(win, cfg, trig.choice_screen);
    mseq.choice_onset(t) = Screen('Flip', win, mseq.onset2(t) + m.img_dur - ifi/2);

    [choice, t_key] = wait_for_keys(cfg, cfg.keys.choice);
    mseq.choice(t)    = choice;
    mseq.choice_rt(t) = t_key - mseq.choice_onset(t);
    mseq.correct(t)   = double(choice == mseq.correct_choice(t));

    % confidence screen (its onset carries the choice trigger)
    DrawFormattedText(win, m.conf_text, 'center', 'center', 0);
    draw_trigger(win, cfg, trig.choice(choice));
    mseq.conf_onset(t) = Screen('Flip', win);

    [conf, t_key] = wait_for_keys(cfg, cfg.keys.conf);
    mseq.confidence(t) = conf;
    mseq.conf_rt(t)    = t_key - mseq.conf_onset(t);
    pending = trig.confidence(conf);            % sent with the next fixation

    save_results(E, mseq);
end

% send the last confidence trigger
E.draw_fix();  draw_trigger(win, cfg, pending);
Screen('Flip', win);

acc = mean(mseq.correct(trials));
fprintf('Memory block %d (%s) done: %d trials, %.0f%% correct, median choice RT %.2f s\n', ...
    b, mseq.condition{trials(1)}, numel(trials), 100 * acc, median(mseq.choice_rt(trials)));
end


function save_results(E, mseq)
cfg = E.cfg;  scr = E.scr;  stim_list = E.stim_list; %#ok<NASGU>
save(E.results_file, 'mseq', 'cfg', 'scr', 'stim_list');
end
