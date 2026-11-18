function [names, codes] = trigger_list(cfg)
% TRIGGER_LIST - All trigger codes in cfg.triggers with their names
%
% Used by write_trigger_codes (checks + trigger_codes.txt) and trigger_log
% (name of every code in the trigger log), so both use the same names.
%
% OUTPUTS:
%   names - 1xN cell, e.g. 'target.Animals', 'foil.Animals', 'fixation.high',
%           'block_start.low', 'catch_image', 'experiment_start'
%   codes - 1xN numeric, the matching codes

tr    = cfg.triggers;
skip  = {'enabled', 'codes_file', 'category_names', 'target_base', 'foil_base'};
names = {};
codes = [];
% image onsets: one code per category for targets and for foils
for k = 1:numel(tr.category_names)
    names{end + 1} = sprintf('target.%s', tr.category_names{k}); %#ok<AGROW>
    codes(end + 1) = tr.target_base + k;                         %#ok<AGROW>
    names{end + 1} = sprintf('foil.%s', tr.category_names{k});   %#ok<AGROW>
    codes(end + 1) = tr.foil_base + k;                           %#ok<AGROW>
end
f = fieldnames(tr);
for k = 1:numel(f)
    if any(strcmp(f{k}, skip))
        continue;
    end
    v = tr.(f{k});
    if isstruct(v)                                % e.g. fixation.high, fixation.low
        sub = fieldnames(v);
        for j = 1:numel(sub)
            names{end + 1} = sprintf('%s.%s', f{k}, sub{j}); %#ok<AGROW>
            codes(end + 1) = v.(sub{j});                      %#ok<AGROW>
        end
    else
        names{end + 1} = f{k};                                %#ok<AGROW>
        codes(end + 1) = v;                                   %#ok<AGROW>
    end
end
end
