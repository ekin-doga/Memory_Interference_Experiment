function seq = run_encoding_high(E, seq)
% RUN_ENCODING_HIGH - All high-interference blocks
%
% Shows every block of the high-interference condition (cfg.repeat blocks),
% with a break screen between blocks. Called from run_encoding.m. Blocks
% that were already completed (when resuming) are skipped.
%
% INPUTS:
%   E - struct from run_encoding (win, scr, cfg, tex, img_rect, ...)
%   seq - trial sequence (from create_sequence)
%
% OUTPUT:
%   seq - the same sequence with measured onsets/offsets filled in

blocks = unique(seq.block(strcmp(seq.condition, 'high')))';
blocks = blocks(arrayfun(@(b) any(isnan(seq.offset(seq.block == b))), blocks)); % not done yet

for k = 1:numel(blocks)
    seq = present_block(E, seq, blocks(k));

    if k < numel(blocks)
        DrawFormattedText(E.win, sprintf(['Break\n\n' ...
            'Block %d of %d done.\n\n' ...
            'Press any key to continue.'], blocks(k), max(seq.block)), ...
            'center', 'center', 0);
        Screen('Flip', E.win);
        wait_key(E.cfg);
    end
end
end
