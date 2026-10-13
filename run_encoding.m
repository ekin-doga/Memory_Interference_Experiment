% RUN_ENCODING -
%
%   1. get_cfg                       - settings
%   2. create_participant            - participant folder
%   3. create_stimuli_list_balanced  - targets/foils for this participant
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

%% 2. Participant folder (asks before overwriting existing data)
sub_dir = create_participant(subj_id, cfg);

%% 3. Stimulus list and 4. sequence
stim_list = create_stimuli_list_balanced(subj_id);
seq       = create_sequence(stim_list, cfg, subj_id);
seq.onset  = nan(height(seq), 1);    % measured image onset (GetSecs time)
seq.offset = nan(height(seq), 1);    % measured image offset
writetable(seq, fullfile(sub_dir, 'sequence.csv'));

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
    E.results_file = fullfile(sub_dir, 'results.mat');
    E.img_rect     = CenterRectOnPointd([0 0 img_px img_px], scr.center_X, scr.center_Y);
    E.draw_fix     = @() my_optimal_fixationpoint(win, scr.center_X, scr.center_Y, ...
                           cfg.fix_size_deg, cfg.fix_color, scr.bg, ppd);

    % preload every target once (each is shown cfg.repeat times)
    DrawFormattedText(win, 'Bilder werden geladen...', 'center', 'center', 0);
    Screen('Flip', win);
    [ids, first] = unique(seq.image_id);
    tex_map = containers.Map();
    for k = 1:numel(ids)
        img = imread(fullfile(pool_dir, seq.path{first(k)}));
        tex_map(ids{k}) = Screen('MakeTexture', win, img);
    end
    E.tex = cellfun(@(id) tex_map(id), seq.image_id);   % texture per trial

    %% Start screen
    DrawFormattedText(win, ['Bilder erscheinen nacheinander.\n\n' ...
        'Bitte schaue auf den Punkt in der Mitte.\n\n' ...
        'Drücke eine Taste, um zu beginnen.'], 'center', 'center', 0);
    Screen('Flip', win);
    wait_key(cfg);

    %% 6. Conditions, one after the other
    if strcmp(seq.condition{1}, 'high')
        parts = {@run_encoding_high, @run_encoding_low};
    else
        parts = {@run_encoding_low, @run_encoding_high};
    end

    seq = parts{1}(E, seq);

    DrawFormattedText(win, ['Pause\n\n' ...
        'Der erste Teil ist geschafft.\n\n' ...
        'Drücke eine Taste, um mit dem zweiten Teil weiterzumachen.'], 'center', 'center', 0);
    Screen('Flip', win);
    wait_key(cfg);

    seq = parts{2}(E, seq);

    DrawFormattedText(win, 'Geschafft! Vielen Dank.', 'center', 'center', 0);
    Screen('Flip', win);
    WaitSecs(2);

    Screen('Close');
    sca; ShowCursor; Priority(0);
    fprintf('Session finished. Results saved to %s\n', E.results_file);

catch err
    sca; ShowCursor; Priority(0);
    if ~strcmp(err.identifier, 'encoding:quit')
        rethrow(err);
    end
    disp(err.message);
    fprintf('All completed blocks are saved in %s\n', fullfile(sub_dir, 'results.mat'));
end
