function show_attn_check_demo(window, screen_cfg, cfg, trigger, header_text, footer_text)
% SHOW_ATTN_CHECK_DEMO - Display instructions and all attention-check images
% together on a single screen, then wait for a key press to continue.
%
% Used before the experiment begins and at every block break.
%
% INPUTS:
%   window      - PTB window pointer
%   screen_cfg  - Screen configuration struct (from set_screen)
%   cfg         - Experiment configuration struct (from get_cfg)
%   trigger     - ViewPixxTrigger object
%   header_text - Instruction / reminder string shown above the images
%   footer_text - (optional) Prompt shown below the images.
%                 Defaults to 'Drücke die LEERTASTE, um zu beginnen.'

if nargin < 6 || isempty(footer_text)
    footer_text = 'Drücke die LEERTASTE, um zu beginnen.';
end

n_imgs   = length(cfg.attn_check_images);
img_size = cfg.h_img;   % images are square; use configured px size
gap      = 40;          % horizontal gap between images (px)

% Load all textures first
textures = zeros(1, n_imgs);
for i = 1:n_imgs
    textures(i) = one_image( ...
        cfg.attn_check_images{i}, ...
        cfg.stimuli_dir, ...
        window, ...
        cfg.attn_check_subfolder, ...
        cfg.attn_check_category);
end

% --- Layout (top to bottom) ---
%   header_text  (wrapped, centred)
%   [gap]
%   images row   (centred)
%   [gap]
%   footer prompt

wrap_cols    = 70;   % character wrap width
text_height  = 320;  % fixed px reserved for header text block
img_gap      = 30;   % px between text block and images
footer_gap   = 30;   % px between images and footer
footer_height = 30;  % px reserved for footer line

% Total content height: text + gap + images + gap + footer
content_height = text_height + img_gap + img_size + footer_gap + footer_height;

% Top of content block, centred vertically on screen
content_top = screen_cfg.center_Y - content_height / 2;

text_margin = content_top;
img_top     = content_top + text_height + img_gap;
img_bottom  = img_top + img_size;
footer_y    = img_bottom + footer_gap;

% Horizontal image row
total_w   = n_imgs * img_size + (n_imgs - 1) * gap;
img_row_x = screen_cfg.center_X - total_w / 2;   % left edge of first image

% Header text
Screen('TextSize', window, 24);
DrawFormattedText(window, header_text, 'center', text_margin, [0 0 0], wrap_cols);

% Attention-check images
for i = 1:n_imgs
    x_left    = img_row_x + (i - 1) * (img_size + gap);
    dest_rect = [x_left, img_top, x_left + img_size, img_bottom];
    Screen('DrawTexture', window, textures(i), [], dest_rect);
end

% Footer prompt below images
Screen('TextSize', window, 24);
DrawFormattedText(window, footer_text, 'center', footer_y, [0 0 0]);

trigger.drawTriggerPixel(cfg.triggers.block_text);
fprintf('Attn-check demo up — trigger %d\n', cfg.triggers.block_text);
Screen('Flip', window);

% Release textures now they are on screen
for i = 1:n_imgs
    Screen('Close', textures(i));
end

% Wait for key press (ESC quits safely)
KbReleaseWait(cfg.deviceIndex);
while true
    [keyIsDown, ~, keyCode] = KbCheck(cfg.deviceIndex);
    if keyIsDown
        pressedKeys = find(keyCode);
        key = pressedKeys(1);
        if key == KbName('ESCAPE')
            trigger.sendTrigger(cfg.triggers.ESC);
            sca;
            ShowCursor;
            error('Experiment terminated by user');
        else
            break;
        end
    end
    WaitSecs(0.001);
end

end
