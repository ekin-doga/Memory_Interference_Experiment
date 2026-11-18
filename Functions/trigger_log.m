function trigger_log(action, varargin)
% TRIGGER_LOG - Log of every EEG trigger code sent (Day 1 and Day 2)
%
% flip_trig adds every code > 0 it sends, with the onset of the frame that
% carried it (the time PTB returns for that flip). The result is the
% complete list of triggers that SHOULD be in the EEG, incl. block start/end
% and experiment start/end/resume, which the results table does not have.
% Aligned to the BioSemi Status channel (offset + clock drift, fitted on the
% triggers that arrived correctly), it can replace missing or wrong codes.
%
%   trigger_log('open', file, cfg, subj_id, session_date, part)
%       start logging to file (CSV; appended if it exists, e.g. on resume)
%   trigger_log('context', block, trial)
%       block/trial written with the following codes (NaN = none)
%   trigger_log('add', code, flip_time, missed) - called by flip_trig
%   trigger_log('flush')
%       append the codes not written yet to the file; call it where timing
%       does not matter (ISI, block end, end of session, after an error)
%   trigger_log('close')                       - flush and stop logging
%
% Without 'open' (e.g. a test script) nothing is logged.
%
% CSV columns: subj_id, session_date, part ('encoding'/'memory'), code,
% name (as in trigger_codes.txt), flip_time (GetSecs, s), block, trial
% (seq.trial / mseq.trial; NaN for block and session events), missed (1 =
% PTB reports that this frame was shown later than requested, i.e. a dropped
% frame: the event is late by about one frame or more; check these trials).
% missed is only meaningful for flips with a requested time (image onsets
% and offsets, Day 2 trial events); flips 'as soon as possible' (start, break
% and end screens) are always 0 or close to it.
% Codes are logged also when cfg.triggers.enabled = false (then the pixel
% stays black and nothing reaches the EEG).

persistent L

switch action
    case 'open'
        [file, cfg, subj_id, session_date, part] = varargin{:};
        [names, codes] = trigger_list(cfg);
        L = struct('file', file, 'subj_id', subj_id, 'session_date', session_date, ...
            'part', part, 'names', {names}, 'codes', codes, ...
            'block', NaN, 'trial', NaN, ...
            'rows', zeros(1000, 5), 'n', 0, 'n_written', 0);
        % rows: code, flip_time, block, trial, missed

    case 'context'
        if isempty(L), return; end
        L.block = varargin{1};
        L.trial = varargin{2};

    case 'add'
        if isempty(L), return; end
        if L.n == size(L.rows, 1)
            L.rows(end + 1000, :) = 0;          % grow in steps, not every code
        end
        L.n = L.n + 1;
        L.rows(L.n, :) = [varargin{1}, varargin{2}, L.block, L.trial, varargin{3}];

    case 'flush'
        if isempty(L) || L.n_written == L.n, return; end
        new_file = ~isfile(L.file);
        fid = fopen(L.file, 'a');
        if fid < 0
            warning('Could not write the trigger log %s.', L.file);
            return;
        end
        if new_file
            fprintf(fid, 'subj_id,session_date,part,code,name,flip_time,block,trial,missed\n');
        end
        for k = L.n_written + 1:L.n
            r = L.rows(k, :);
            name = L.names(L.codes == r(1));
            if isempty(name), name = {'unknown'}; end
            fprintf(fid, '%d,%s,%s,%d,%s,%.6f,%g,%g,%d\n', L.subj_id, L.session_date, ...
                L.part, r(1), name{1}, r(2), r(3), r(4), r(5));
        end
        fclose(fid);
        L.n_written = L.n;

    case 'close'
        trigger_log('flush');
        L = [];

    otherwise
        error('trigger_log:action', 'Unknown action "%s".', action);
end
end
