function [cfg] = get_cfg(participant_id)

% GET_CFG - Returns experiment configuration for the new experiment
%
% DESIGN:
%   Set 1: 120 images from 3 categories × 10 typicality bins × 4 per bin
%          Shown once per block (always "new" — no repeats)
%   Set 2: 3 manually-selected attention-check images (bathroom images)
%          Shown repeatedly throughout each block at ~10% of total trials
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

% Attention-check images (Set 2) — 3 images, manually chosen
cfg.attn_check_images = {
    'img_nr8nj.png', 'img_zvi2m.png', 'img_0kqc0.png'};
cfg.attn_check_category = 'Attention';
cfg.attn_check_subfolder = 'stimuli_all';  

%% Experiment settings

% Set 1 composition: 3 categories × 10 bins × 4 per bin = 120 per block
cfg.n_categories      = 3;          % bedrooms, kitchens, living_rooms
cfg.n_bins            = 10;         % typicality bins 1–10
cfg.n_per_bin         = 5;          % images per category per bin
cfg.n_set1_per_block  = cfg.n_categories * cfg.n_bins * cfg.n_per_bin;  % 120

% Set 2: attention-check images
cfg.n_attn_images     = 3;          % number of distinct attention-check images

cfg.attn_check_rate  = 0.10;        % attention checks as fraction of set1 trials
cfg.n_attn_per_block = round(cfg.n_set1_per_block * cfg.attn_check_rate);  % 15

cfg.n_blocks          = 16;          % number of blocks

%% Timing
cfg.stim_dur  = 0.500;              % stimulus duration (s)
cfg.ISI_vals  = [0.900, 1.000, 1.100];  % possible ISI durations (s), sampled randomly per trial

%% Display
cfg.vdist  = 55;    % viewing distance (cm)
cfg.h_img  = 512;   % image height (px)
cfg.w_img  = 512;   % image width (px)

%% Response keys
cfg.keys.Quit     = KbName('ESCAPE');
cfg.keys.respond  = KbName('space');  % press space to indicate repeating image

%% Trigger settings
cfg.triggers.enabled           = true;   % Set to false for debugging (no hardware)
cfg.triggers.record_responses  = false;   % Set to false to skip key-press triggers

% Event triggers
cfg.triggers.experiment_start = 1;
cfg.triggers.experiment_end   = 2;
cfg.triggers.block_text       = 3;
cfg.triggers.key_press        = 4;
cfg.triggers.ESC              = 5;
cfg.triggers.fix_onset        = 6;

% Stimulus triggers: category_base + typicality_bin (bins 1-10)
%   Bedrooms:     11, 12, 13, 14, 15, 16, 17, 18, 19, 20
%   Kitchens:     21, 22, 23, 24, 25, 26, 27, 28, 29, 30
%   Living rooms: 31, 32, 33, 34, 35, 36, 37, 38, 39, 40
%   Attn check:   50

cfg.triggers.base_bedrooms    = 10;
cfg.triggers.base_kitchens    = 20;
cfg.triggers.base_livingrooms = 30;
cfg.triggers.attn_check       = 50;

%% Participant seed
if nargin >= 1 && ~isempty(participant_id)
    cfg.seed           = participant_id * 1000;
    cfg.participant_id = participant_id;
else
    cfg.seed           = 1000;
    cfg.participant_id = NaN;
end

cfg.deviceIndex = [];

end
