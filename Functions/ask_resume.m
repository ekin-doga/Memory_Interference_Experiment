function [resume, session_date] = ask_resume(sub_dir, subj_id, part)
% ASK_RESUME - Checks for earlier data of this session part and asks what to do
%
% Output files are named sub-XXX_<part>_<type>_<date>.<ext>, e.g.
% sub-001_encoding_results_2026-10-19.mat. This looks for an existing
% sub-XXX_<part>_results_*.mat. If there is none, a new session starts with
% today's date. If there is one, it asks:
%   r - resume: continue in the same files (their date is kept)
%   o - overwrite: the old files of this part are deleted, new files get today's date
%   q - quit (error), nothing is changed
%
% INPUTS:
%   sub_dir - participant folder
%   subj_id - participant number
%   part    - 'encoding' or 'memory'
%
% OUTPUTS:
%   resume       - true if the existing session should be continued
%   session_date - 'yyyy-MM-dd' used in the file names

resume       = false;
session_date = char(datetime('now', 'Format', 'yyyy-MM-dd'));

old = dir(fullfile(sub_dir, sprintf('sub-%03d_%s_results_*.mat', subj_id, part)));
if isempty(old)
    return;
end
[~, i] = max([old.datenum]);              % most recent, if there are several
old = old(i);
old_date = regexp(old.name, '_results_(.+)\.mat$', 'tokens', 'once');

while true
    r = input(sprintf('Participant %d already has %s data (%s). Resume, overwrite or quit [r/o/q]? ', ...
        subj_id, part, old.name), 's');
    if strcmpi(r, 'r')
        resume       = true;
        session_date = old_date{1};
        return;
    elseif strcmpi(r, 'o')
        delete(fullfile(sub_dir, sprintf('sub-%03d_%s_*', subj_id, part)));
        disp('Old files deleted; starting a new session.');
        return;
    elseif strcmpi(r, 'q')
        error('Participant %d already has %s data and you chose not to overwrite.', subj_id, part);
    else
        disp('Invalid input. Please enter r, o or q.');
    end
end
end
