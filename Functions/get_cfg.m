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

%% Response keys
cfg.keys.Quit     = KbName('ESCAPE');
cfg.keys.respond  = KbName('space');  % press space to indicate repeating image

%% Trigger settings

% set up later

cfg.deviceIndex = [];


%% Stimuli list



