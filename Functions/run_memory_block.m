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
% conditions). Results are saved to E.results_file (.mat) after every trial,
% so an ESC loses at most the current trial. The results CSV (E.results_csv)
% is rewritten every cfg.mem.csv_every completed trials and at the end of the
% block. Trials that already have a confidence
% rating (when resuming) are skipped.
%
% INPUTS:
%   E    - struct from run_memory (win, scr, cfg, tex1, tex2, img_rect, ...)
%   mseq - memory sequence (from create_memory_sequence)
%   b    - block number

cfg  = E.cfg;
m    = cfg.mem;
win  = E.win;
ifi  = E.scr.ifi;
trials = find(mseq.block == b & isnan(mseq.confidence))';   % trials not done yet

% for the progress print: condition 1 or 2 (order for this participant)
in_block = find(mseq.block == b);
part     = 1 + ~strcmp(mseq.condition{in_block(1)}, mseq.condition{1});
n_trials = numel(in_block);
outcome  = {'wrong', 'correct'};

for k = 1:numel(trials)
    t = trials(k);
    % fixation (inter-trial interval)
    E.draw_fix();
    vbl = Screen('Flip', win);

    % image 1
    Screen('DrawTexture', win, E.tex1(t), [], E.img_rect);
    mseq.onset1(t) = Screen('Flip', win, vbl + m.iti - ifi/2);

    % fixation between the images
    E.draw_fix();
    mseq.offset1(t) = Screen('Flip', win, mseq.onset1(t) + m.img_dur - ifi/2);

    % image 2
    Screen('DrawTexture', win, E.tex2(t), [], E.img_rect);
    mseq.onset2(t) = Screen('Flip', win, mseq.offset1(t) + m.isi - ifi/2);

    % choice screen (replaces image 2)
    DrawFormattedText(win, m.choice_text, 'center', 'center', 0);
    mseq.choice_onset(t) = Screen('Flip', win, mseq.onset2(t) + m.img_dur - ifi/2);

    [choice, t_key] = wait_for_keys(cfg, cfg.keys.choice);
    mseq.choice(t)    = choice;
    mseq.choice_rt(t) = t_key - mseq.choice_onset(t);
    mseq.correct(t)   = double(choice == mseq.correct_choice(t));

    % confidence screen
    DrawFormattedText(win, m.conf_text, 'center', 'center', 0);
    mseq.conf_onset(t) = Screen('Flip', win);

    [conf, t_key] = wait_for_keys(cfg, cfg.keys.conf);
    mseq.confidence(t) = conf;
    mseq.conf_rt(t)    = t_key - mseq.conf_onset(t);

    save_results(E, mseq);

    % progress print (command window)
    fprintf('Memory | condition %d (%s) | trial %d/%d | %s, confidence %d\n', ...
        part, mseq.condition{t}, mseq.trial_in_block(t), n_trials, ...
        outcome{mseq.correct(t) + 1}, conf);

    % CSV every cfg.mem.csv_every completed trials (counted over the session,
    % so the rhythm continues after a resume); written after the confidence
    % rating, before the next trial starts, so it does not affect timing
    if mod(sum(~isnan(mseq.confidence)), m.csv_every) == 0
        writetable(mseq, E.results_csv);
    end
end

% fixation after the last trial
E.draw_fix();
Screen('Flip', win);

all_trials = find(mseq.block == b);
acc = mean(mseq.correct(all_trials));
fprintf('Memory block %d (%s) done: %d trials, %.0f%% correct, median choice RT %.2f s\n', ...
    b, mseq.condition{all_trials(1)}, numel(all_trials), 100 * acc, median(mseq.choice_rt(all_trials)));
writetable(mseq, E.results_csv);   % CSV with everything so far, at the break
end


function save_results(E, mseq)
cfg = E.cfg;  scr = E.scr;  stim_list = E.stim_list; %#ok<NASGU>
subj_id = mseq.subj_id(1);  session_date = mseq.session_date{1}; %#ok<NASGU>
save(E.results_file, 'mseq', 'cfg', 'scr', 'stim_list', 'subj_id', 'session_date');
end
