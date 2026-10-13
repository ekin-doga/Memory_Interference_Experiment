function dir_name = create_participant(subj_id, cfg)
% CREATE_PARTICIPANT - Makes the participant folder Participants/sub-XXX
%
% If the folder already exists and holds data (results.mat), asks whether
% to overwrite it. Answering 'n' stops with an error, so existing data is
% never overwritten by accident.
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
    return;
end

fprintf('Participant directory: %s\n', dir_name);

if isfile(fullfile(dir_name, 'results.mat'))
    while true
        r = input('Participant already has data. Overwrite [y/n]? ', 's');
        if strcmpi(r, 'y')
            disp('Files will be overwritten.');
            return;
        elseif strcmpi(r, 'n')
            error(['Participant %d already has data and you chose not to overwrite. ' ...
                   'Use a different participant number.'], subj_id);
        else
            disp('Invalid input. Please enter y or n.');
        end
    end
end
end
