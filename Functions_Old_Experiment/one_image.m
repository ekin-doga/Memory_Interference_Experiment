function [ImgTex] = one_image(filename, base_path, window, subfolder, category, typicality)
% ONE_IMAGE - Load and prepare an image texture for display
%
% USAGE:
%   ImgTex = one_image(filename, base_path, window, subfolder, category, typicality)
%   ImgTex = one_image(filename, base_path, window, subfolder, category)  % Practice (no typicality)
%   ImgTex = one_image(filename, base_path, window)  % Legacy flat structure
%
% INPUTS:
%   filename    - Image filename (e.g., 'img_28eqs.png')
%   base_path   - Base stimuli directory (e.g., '/path/to/Stimuli')
%   window      - Psychtoolbox window handle
%   subfolder   - Stimuli subfolder (e.g., 'stimuli_140', 'stimuli_practise')
%   category    - Category name (e.g., 'bedrooms', 'Bathroom')
%   typicality  - Typicality bin (1-10) - optional for practice trials
%
% Path structure:
%   With typicality: base_path/subfolder/category/typicality/filename
%   Without typicality (practice): base_path/subfolder/category/filename
%   Legacy (no subfolder): base_path/filename

% Build full path based on provided arguments
if nargin >= 5 && ~isempty(subfolder) && ~isempty(category)
    if nargin >= 6 && ~isempty(typicality)
        % Full hierarchical structure: subfolder/category/typicality/filename
        img_fullpath = fullfile(base_path, subfolder, category, num2str(typicality), filename);
    else
        % Practice structure: subfolder/category/filename (no typicality)
        img_fullpath = fullfile(base_path, subfolder, category, filename);
    end
else
    % Legacy flat structure: base_path/filename
    img_fullpath = fullfile(base_path, filename);
end

if ~isfile(img_fullpath)
    error('Image file not found: %s', img_fullpath);
end

% Load image
Img = imread(img_fullpath);

% Prepare texture (but don't show yet)
ImgTex = Screen('MakeTexture', window, Img);

end
