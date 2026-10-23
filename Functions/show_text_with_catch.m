function show_text_with_catch(E, txt, code)
% SHOW_TEXT_WITH_CATCH - Text screen with the catch flowers underneath
%
% Draws txt (DrawFormattedText) with the catch images (E.catch_tex, from
% cfg.catch.files) in a row directly below it, then flips. Text and flowers
% are centred on the screen as one group, with cfg.catch.example_gap_deg
% between the last text line and the flowers. Used for the Day 1 start
% screen and the break screens, so participants always know which pictures
% need a space press. The caller waits for the key press (wait_key).
%
% Flower size: cfg.catch.example_size_deg (smaller than in the blocks). If
% text and flowers do not fit the window (e.g. the 900x700 test window), the
% flowers are made smaller and a warning is printed once.
%
% code (optional, default 0) is the EEG trigger sent when the screen appears
% (e.g. cfg.triggers.experiment_start).

if nargin < 3
    code = 0;
end

win  = E.win;
rect = E.scr.windowRect;
W = rect(3) - rect(1);
H = rect(4) - rect(2);
ppd = E.scr.pixperdeg;
n   = numel(E.catch_tex);
gap_x = 0.5 * ppd;                               % between flowers
gap_y = E.cfg.catch.example_gap_deg * ppd;       % between text and flowers

% 1. measure the text: draw it once, read its bounds, clear the screen again
[~, ~, tb] = DrawFormattedText(win, txt, 'center', 'center', 0);
text_h = tb(4) - tb(2);
Screen('FillRect', win, E.scr.bg);

% 2. flower size: as set, unless the row is too wide or too tall for the window
sz_set = E.cfg.catch.example_size_deg * ppd;
sz = min([sz_set, ...
          (0.9 * W - (n - 1) * gap_x) / n, ...
          0.95 * H - text_h - gap_y]);
sz = max(sz, 0.5 * ppd);
persistent warned
if sz < sz_set - 0.5 && isempty(warned)
    warning('Catch flowers on the text screens shrunk to %.1f deg to fit the window (cfg.catch.example_size_deg = %g).', ...
        sz / ppd, E.cfg.catch.example_size_deg);
    warned = true;
end

% 3. text + gap + flowers as one block, centred vertically
total_h = text_h + gap_y + sz;
top = rect(2) + (H - total_h) / 2;
text_rect = [rect(1), top, rect(3), top + text_h];
DrawFormattedText(win, txt, 'center', 'center', 0, [], [], [], [], [], text_rect);

row_w = n * sz + (n - 1) * gap_x;
x0 = rect(1) + (W - row_w) / 2;
y0 = top + text_h + gap_y;
for k = 1:n
    x = x0 + (k - 1) * (sz + gap_x);
    Screen('DrawTexture', win, E.catch_tex(k), [], [x, y0, x + sz, y0 + sz]);
end
flip_trig(win, E.cfg, code);
end
