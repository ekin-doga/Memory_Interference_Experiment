% RUN_ENCODING -
%
%   1. get_cfg                       - settings
%   2. create_participant / ask_resume - participant folder; resume or overwrite earlier data
%   3. load Stimulus_lists/stimuli_sub-XXX.csv - targets/foils for this participant
%      (pre-made with create_stimuli_list_balanced; never regenerated here)
%   4. create_sequence               - trial order, conditions kept separate
%   5. set_screen                    - open the window, preload the images
%   6. run_encoding_high / run_encoding_low
%                                    - one condition after the other

%      (odd subj_id: high first; even subj_id: low first) % recondider this
%   


clearvars; sca;

%% ===== SET THESE BEFORE EACH RUN =====
subj_id  = 1;      % participant number
windowed = true;    % true = 900x700 test window, false = fullscreen
%% ======================================

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'Functions'));

%% 1. Settings
cfg = get_cfg(subj_id);

%% 2. Participant folder and output files (if data exists: resume, overwrite or quit)
sub_dir = create_participant(subj_id, cfg);
[resume, session_date] = ask_resume(sub_dir, subj_id, 'encoding');
prefix        = fullfile(sub_dir, sprintf('sub-%03d_encoding', subj_id));
sequence_file = sprintf('%s_sequence_%s.csv', prefix, session_date);
results_file  = sprintf('%s_results_%s.mat', prefix, session_date);
results_csv   = sprintf('%s_results_%s.csv', prefix, session_date);

%% 3. Stimulus list and 4. sequence
list_file = fullfile(root, 'Stimulus_lists', sprintf('stimuli_sub-%03d.csv', subj_id));
if ~isfile(list_file)
    error('No stimulus list for participant %d (%s). Make it first with create_stimuli_list_balanced(%d).', ...
        subj_id, list_file, subj_id);
end
stim_list = readtable(list_file, 'TextType', 'char');
fprintf('Loaded %s (concept set %d)\n', list_file, stim_list.concept_set(1));
seq       = create_sequence(stim_list, cfg, subj_id);
seq.onset  = nan(height(seq), 1);    % measured image onset (GetSecs time)
seq.offset = nan(height(seq), 1);    % measured image offset
seq = addvars(seq, repmat(subj_id, height(seq), 1), repmat({session_date}, height(seq), 1), ...
    'Before', 1, 'NewVariableNames', {'subj_id', 'session_date'});

if resume
    % continue with the saved sequence: images with a measured offset are done
    old = load(results_file, 'seq');
    if height(old.seq) ~= height(seq) || ~isequal(old.seq.image_id, seq.image_id)
        error(['The saved results of participant %d do not match the sequence made now ' ...
               '(was get_cfg changed, e.g. max_images_per_block or high_order?).'], subj_id);
    end
    seq = old.seq;
    n_done = sum(~isnan(seq.offset));
    if n_done == height(seq)
        error('Participant %d already finished encoding; nothing to resume.', subj_id);
    end
    fprintf('Resuming: %d of %d images already shown, continuing with image %d.\n', ...
        n_done, height(seq), n_done + 1);
else
    writetable(seq, sequence_file);
end

pool_dir = fullfile(cfg.stimuli_dir, 'Selection20_resized');

try
    %% 5. Screen
    [scr, win] = set_screen(2, double(windowed), cfg);
    ppd = scr.pixperdeg;

    img_px = round(cfg.img_size_deg * ppd);
    fprintf('Image %.1f deg = %d px, fixation point %.2f deg = %d px\n', ...
        cfg.img_size_deg, img_px, cfg.fix_size_deg, round(cfg.fix_size_deg * ppd));

    % everything the condition functions need
    E = struct();
    E.win          = win;
    E.scr          = scr;
    E.cfg          = cfg;
    E.stim_list    = stim_list;
    E.results_file = results_file;
    E.img_rect     = CenterRectOnPointd([0 0 img_px img_px], scr.center_X, scr.center_Y);
    E.draw_fix     = @() my_optimal_fixationpoint(win, scr.center_X, scr.center_Y, ...
                           cfg.fix_size_deg, cfg.fix_color, scr.bg, ppd);

    % preload every target once (each is shown cfg.repeat times)
    DrawFormattedText(win, 'Loading images...', 'center', 'center', 0);
    Screen('Flip', win);
    [ids, first] = unique(seq.image_id);
    tex_map = containers.Map();
    for k = 1:numel(ids)
        img = imread(fullfile(pool_dir, seq.path{first(k)}));
        tex_map(ids{k}) = Screen('MakeTexture', win, img);
    end
    E.tex = cellfun(@(id) tex_map(id), seq.image_id);   % texture per trial

    %% Start screen
    DrawFormattedText(win, ['Pictures will appear one after the other.\n\n' ...
        'Please try to remember them; you will be tested tomorrow.\n' ...
        'Keep your eyes on the dot in the centre.\n\n' ...
        'Press any key to start.'], 'center', 'center', 0);
    Screen('Flip', win);
    wait_key(cfg);

    %% 6. Conditions, one after the other
    if strcmp(seq.condition{1}, 'high')
        parts = {@run_encoding_high, @run_encoding_low};
    else
        parts = {@run_encoding_low, @run_encoding_high};
    end

    first_done = all(~isnan(seq.offset(strcmp(seq.condition, seq.condition{1}))));
    seq = parts{1}(E, seq);              % skips blocks/images already shown

    if ~first_done                       % no break if resuming in the second part
        DrawFormattedText(win, ['Break\n\n' ...
            'The first part is done.\n\n' ...
            'Press any key to continue with the second part.'], 'center', 'center', 0);
        Screen('Flip', win);
        wait_key(cfg);
    end

    seq = parts{2}(E, seq);

    DrawFormattedText(win, 'Done! Thank you very much.', 'center', 'center', 0);
    Screen('Flip', win);
    WaitSecs(2);

    Screen('Close');
    sca; ShowCursor; Priority(0);
    writetable(seq, results_csv);
    fprintf('Session finished. Results saved to %s (and .csv)\n', results_file);

catch err
    sca; ShowCursor; Priority(0);
    if ~strcmp(err.identifier, 'encoding:quit')
        rethrow(err);
    end
    disp(err.message);
    fprintf(['All images shown so far are saved in %s\n' ...
             'Run again with the same subj_id and choose r to resume.\n'], results_file);
end
