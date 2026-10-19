function show_text_with_catch(E, txt)
% SHOW_TEXT_WITH_CATCH - Text screen with the catch flowers underneath
%
% Draws txt (DrawFormattedText) in the upper part of the window and the
% catch images (E.catch_tex, from cfg.catch.files) in a row below it, then
% flips. Used for the Day 1 start screen and the break screens, so
% participants always know which pictures need a space press. The caller
% waits for the key press (wait_key).
%
% Flower size: cfg.catch.example_size_deg (4 deg, smaller than in the
% blocks, so the text has room). If the row does not fit the window (e.g. the
% 900x700 test window), the flowers are made smaller and a warning is
% printed once.

win  = E.win;
rect = E.scr.windowRect;
W = rect(3) - rect(1);
H = rect(4) - rect(2);

% text: centred in the upper 62% of the window
text_rect = [rect(1), rect(2), rect(3), rect(2) + 0.62 * H];
DrawFormattedText(win, txt, 'center', 'center', 0, [], [], [], [], [], text_rect);

% flowers: one row, centred in the lower part
n   = numel(E.catch_tex);
gap = 0.5 * E.scr.pixperdeg;
sz  = min([E.cfg.catch.example_size_deg * E.scr.pixperdeg, ...
           0.30 * H, ...
           (0.9 * W - (n - 1) * gap) / n]);
persistent warned
if sz < E.cfg.catch.example_size_deg * E.scr.pixperdeg - 0.5 && isempty(warned)
    warning('Catch flowers on the text screens shrunk to %.1f deg to fit the window (cfg.catch.example_size_deg = %g).', ...
        sz / E.scr.pixperdeg, E.cfg.catch.example_size_deg);
    warned = true;
end
row_w = n * sz + (n - 1) * gap;
x0 = rect(1) + (W - row_w) / 2;
y_mid = rect(2) + 0.81 * H;
for k = 1:n
    r = [x0 + (k - 1) * (sz + gap), y_mid - sz / 2, x0 + (k - 1) * (sz + gap) + sz, y_mid + sz / 2];
    Screen('DrawTexture', win, E.catch_tex(k), [], r);
end
Screen('Flip', win);
end
