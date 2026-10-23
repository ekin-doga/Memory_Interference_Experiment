function write_trigger_codes(cfg)
% WRITE_TRIGGER_CODES - Checks the trigger codes and writes trigger_codes.txt
%
% The codes are defined in get_cfg (cfg.triggers) only. get_cfg calls this
% every time it runs, so the reference file for the EEG analysis
% (cfg.triggers.codes_file) always matches the codes the experiment sends.
%
% Errors if a code is outside 1-255, is used twice, or equals the code of
% the gray background (cfg.triggers.bg_code).

tr    = cfg.triggers;
skip  = {'enabled', 'bg_code', 'codes_file', 'category_names', 'target_base', 'foil_base'};
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
    if isstruct(v)                                % e.g. image.high, image.low
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

bad = codes < 1 | codes > 255 | codes ~= round(codes);
if any(bad)
    error('triggers:code', 'Trigger codes must be integers 1-255: %s', strjoin(names(bad), ', '));
end
if any(codes == tr.bg_code)
    error('triggers:code', 'Code %d is what the gray background sends; do not use it (%s).', ...
        tr.bg_code, strjoin(names(codes == tr.bg_code), ', '));
end
[u, ~, ic] = unique(codes);
dup = u(accumarray(ic(:), 1) > 1);
if ~isempty(dup)
    error('triggers:code', 'Trigger code used twice: %s', ...
        strjoin(names(ismember(codes, dup)), ', '));
end

% reference file, sorted by code
[codes, order] = sort(codes);
names = names(order);
fid = fopen(tr.codes_file, 'w');
if fid < 0
    warning('Could not write %s.', tr.codes_file);
    return;
end
fprintf(fid, '# EEG trigger codes (ViewPixx pixel mode -> BioSemi)\n');
fprintf(fid, '# Written by get_cfg.m - do not edit here, change the codes in get_cfg.m.\n');
fprintf(fid, '# 0 = no trigger. %d = gray background (only if a frame was flipped without the pixel).\n', tr.bg_code);
fprintf(fid, '# Every code lasts one frame and is followed by 0.\n#\n');
fprintf(fid, '# code  bits      name                                pixel RGB (0-255)\n');
for k = 1:numel(codes)
    rgb = trigger_rgb(codes(k));
    fprintf(fid, '%6d  %s  %-34s  %3d %3d %3d\n', codes(k), dec2bin(codes(k), 8), names{k}, rgb);
end
fclose(fid);
end
