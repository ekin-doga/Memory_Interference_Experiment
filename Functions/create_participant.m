function dir_name = create_participant(subj_id, cfg)
% CREATE_PARTICIPANT - Makes the participant folder Participants/sub-XXX
%
% Only creates the folder. Whether earlier data is resumed or overwritten
% is asked by ask_resume.
%
% INPUTS:
%   subj_id - participant number
%   cfg     - config from get_cfg (uses cfg.participants_dir)
%
% OUTPUT:
%   dir_name - full path of the participant folder

dir_name = fullfile(cfg.participants_dir, sprintf('sub-%03d', subj_id));

if ~isfolder(dir_name)
    fprintf('Creating new participant directory: %s\n', dir_name);
    mkdir(dir_name);
else
    fprintf('Participant directory: %s\n', dir_name);
end
end
