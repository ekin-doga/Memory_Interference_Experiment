function [startTrial, instructions, Info, Log] = init_experiment_new(cfg, participant_dir, participant_id, screen_cfg)
% INIT_EXPERIMENT_NEW - Initialises a fresh session of the new experiment
%
% INPUTS:
%   cfg             - Configuration struct from get_cfg()
%   participant_dir - Participant directory path
%   participant_id  - Participant ID number
%   screen_cfg      - Screen configuration (from set_screen)
%
% OUTPUTS:
%   startTrial    - Always 1 for fresh starts
%   instructions  - Instruction string
%   Info          - Trial table
%   Log           - Log structure

startTrial = 1;

%% Select stimuli
[set1, set2] = select_stimuli_new(cfg);

%% Generate trial sequence
Info = create_sequence_new(set1, set2, cfg);

fprintf('Participant seed: %d\n', cfg.seed);

%% Save participant-specific files
writetable(set1, fullfile(participant_dir, 'set1_stimuli.csv'),  'Delimiter', ',');
writetable(set2, fullfile(participant_dir, 'set2_stimuli.csv'),  'Delimiter', ',');
writetable(Info, fullfile(participant_dir, 'all_trials.csv'),    'Delimiter', ',');

%% Build instruction string
instructions = [...
    'Bilder erscheinen nacheinander.\n\n' ...
    'Nur diese drei Bilder werden sich wiederholen.\n\n' ...
    'Drücke die LEERTASTE so schnell wie möglich, wenn du eines davon siehst.\n\n' ...
    'Bei allen anderen Bildern nichts tun.\n\n' ...
    'Nach jeder Antwort ändert der Fixationspunkt die Farbe:\n' ...
    'Grün = richtig.   Rot = falsch.\n\n' ...
    'Wenn du blinzeln musst, tue dies bitte während des Fixationskreuzes.'];

%% Initialise log
Log = struct();
Log.response_key  = 'space';
Log.name          = num2str(participant_id);
Log.logfilename   = ['Log_', Log.name, '_experiment_.mat'];
Log.date          = {datetime('now')};
Log.cfg           = cfg;
Log.screen_cfg    = screen_cfg;
Log.lastTrial     = 0;

end
