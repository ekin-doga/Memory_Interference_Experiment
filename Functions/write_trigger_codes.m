function write_trigger_codes(cfg)
% WRITE_TRIGGER_CODES - Checks the trigger codes and writes trigger_codes.txt
%
% The codes are defined in get_cfg (cfg.triggers) only. get_cfg calls this
% every time it runs, so the reference file for the EEG analysis
% (cfg.triggers.codes_file) always matches the codes the experiment sends.
%
% Errors if a code is outside 1-255 or is used twice.

tr = cfg.triggers;
[names, codes] = trigger_list(cfg);   % same names as in the trigger log

bad = codes < 1 | codes > 255 | codes ~= round(codes);
if any(bad)
    error('triggers:code', 'Trigger codes must be integers 1-255: %s', strjoin(names(bad), ', '));
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
fprintf(fid, '# 0 = no trigger.\n');
fprintf(fid, '# Every code lasts one frame and is followed by 0.\n#\n');
fprintf(fid, '# code  bits      name                                pixel RGB (0-255)\n');
for k = 1:numel(codes)
    rgb = trigger_rgb(codes(k));
    fprintf(fid, '%6d  %s  %-34s  %3d %3d %3d\n', codes(k), dec2bin(codes(k), 8), names{k}, rgb);
end
fclose(fid);
end
