function [cfg] = get_cfg(participant_id)

% GET_CFG - Returns experiment configuration for the new experiment
%
% DESIGN:

%
% USAGE:
%   cfg = get_cfg(participant_id)
%   cfg = get_cfg()   % uses default seed (for testing)

%% Paths (derived from this file's location - portable)
this_file = mfilename('fullpath');
functions_dir = fileparts(this_file);
cfg.experiment_root = fileparts(functions_dir);  % Parent of Functions/

cfg.stimuli_dir       = fullfile(cfg.experiment_root, 'Stimuli');
cfg.participants_dir  = fullfile(cfg.experiment_root, 'Participants');

% Stimulus database (same pool as original experiment)
cfg.path_to_table    = fullfile(cfg.stimuli_dir, 'stim_list.csv');
cfg.stimuli_subfolder = 'stimuli_all';

%% Experiment settings

cfg.repeat      = 1;      % blocks per condition: each target is shown this many times
cfg.n_condition = 2;      % high and low interference, run separately (all high blocks, then all low, or reverse)

% Order of images within each HIGH-interference block:
%   'random'  - all 150 images fully shuffled; exemplars of a concept can appear anywhere
%   'grouped' - the 10 exemplars of a concept are shown one after another; the order of
%               the 15 concepts (and of the exemplars within each concept) is reshuffled
%               in every repetition
% Low-interference blocks are always fully shuffled.
cfg.high_order = 'grouped';

% TESTING ONLY: show at most this many images per block ([] = all 150).
% Set back to [] for the real experiment!
cfg.max_images_per_block = 10;

%% Timing
cfg.stim_dur  = 0.500;              % stimulus duration (s)
cfg.ISI_vals  = [0.900, 1.000, 1.100];  % possible ISI durations (s), sampled randomly per trial

%% Display
cfg.vdist           = 55;    % viewing distance (cm)
cfg.screen_width_cm = [];    % physical width of the visible screen area (cm);
                             % [] = ask the system (often wrong, so measure it
                             % and fill it in for the EEG setup)

% Sizes in degrees of visual angle (converted to pixels at runtime)
cfg.img_size_deg  = 8;       % image width/height (images are square)
cfg.fix_size_deg  = 0.6;     % fixation point diameter (Thaler et al., 2013:
                             % 0.6 deg outer circle, 0.2 deg centre dot)
cfg.fix_color     = [0 0 0]; % fixation point color (0-1 range), black

%% Day 2 memory test (run_memory)
cfg.mem.img_dur     = 0.500;   % each of the two images (s)
cfg.mem.isi         = 1.000;   % fixation between image 1 and image 2 (s)
cfg.mem.iti         = 1.000;   % fixation before image 1 of each trial (s)

% Key names (KbName); changed here, translated to key codes below
cfg.mem.choice_keys = {'1!', '2@'};               % first image, second image
cfg.mem.conf_keys   = {'1!', '2@', '3#', '4$'};   % 1 = guess ... 4 = very sure

% Text shown to participants (English for now)
cfg.mem.instruction_text = ['Memory test\n\n' ...
    'In each trial you will see two pictures, one after the other.\n' ...
    'One of them you saw yesterday, the other one is new.\n\n' ...
    'After the second picture, press\n' ...
    '1 if you saw the FIRST picture yesterday\n' ...
    '2 if you saw the SECOND picture yesterday.\n\n' ...
    'Then rate how sure you are (1 = guess ... 4 = very sure).\n' ...
    'Take as much time as you need.\n\n' ...
    'Press any key to start.'];
cfg.mem.choice_text = ['Which picture did you see yesterday?\n\n' ...
    '1 = first picture          2 = second picture'];
cfg.mem.conf_text = ['How sure are you?\n\n' ...
    '1 = guess\n2 = rather unsure\n3 = rather sure\n4 = very sure'];
cfg.mem.part_break_text = ['Break\n\nThe first part is done.\n\n' ...
    'Press any key to continue with the second part.'];

%% Response keys
if exist('KbName', 'file')                 % Psychtoolbox installed
    KbName('UnifyKeyNames');               % same key names on Mac, Windows and Linux
    cfg.keys.Quit     = KbName('ESCAPE');
    cfg.keys.respond  = KbName('space');  % press space to indicate repeating image
    cfg.keys.choice   = KbName(cfg.mem.choice_keys);
    cfg.keys.conf     = KbName(cfg.mem.conf_keys);
else                                       % no Psychtoolbox: settings and sequences still work,
    cfg.keys.Quit     = NaN;               % presenting (run_encoding / run_memory) does not
    cfg.keys.respond  = NaN;
    cfg.keys.choice   = nan(1, numel(cfg.mem.choice_keys));
    cfg.keys.conf     = nan(1, numel(cfg.mem.conf_keys));
    warning('Psychtoolbox not found: key codes set to NaN. You can build sequences, but not run the experiment.');
end

%% Trigger settings
% Not used yet: with enabled = false, draw_trigger only draws a black pixel.
% The ViewPixx encoding still has to be added to draw_trigger.m.
cfg.triggers.enabled = false;

% Day 2 memory test codes (sent with the flip they belong to)
%   img1 / img2: rows = high, low; columns = target, foil
cfg.triggers.mem.img1          = [111 112; 121 122];   % first image onset
cfg.triggers.mem.img2          = [113 114; 123 124];   % second image onset
cfg.triggers.mem.choice_screen = 130;                  % choice screen onset
cfg.triggers.mem.choice        = [131 132];            % chose first / second (with confidence screen onset)
cfg.triggers.mem.confidence    = [141 142 143 144];    % confidence 1-4 (with next fixation onset)

cfg.deviceIndex = [];


%% Stimuli list



