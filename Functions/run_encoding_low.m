function seq = run_encoding_low(E, seq)
% RUN_ENCODING_LOW - All low-interference blocks
%
% Shows every block of the low-interference condition (cfg.repeat blocks),
% with a break screen between blocks. Called from run_encoding.m. Blocks
% that were already completed (when resuming) are skipped.
%
% INPUTS:
%   E - struct from run_encoding (win, scr, cfg, tex, img_rect, ...)
%   seq - trial sequence (from create_sequence)
%
% OUTPUT:
%   seq - the same sequence with measured onsets/offsets filled in

blocks = unique(seq.block(strcmp(seq.condition, 'low')))';
blocks = blocks(arrayfun(@(b) any(isnan(seq.offset(seq.block == b))), blocks)); % not done yet

for k = 1:numel(blocks)
    seq = present_block(E, seq, blocks(k));

    if k < numel(blocks)
        show_text_with_catch(E, [sprintf('Break\n\nBlock %d of %d done.\n\n', blocks(k), max(seq.block)) ...
            E.cfg.catch.text '\n\n' ...
            'Press any key to continue.']);
        wait_key(E.cfg);
    end
end
end
