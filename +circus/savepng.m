function savepng( varargin )

%  This function saves plots as png files.
%
%  Inputs:
%
%  "Directory": Path and name of image to be saved, e.g:
%  '/home/Desktop/test.png'
%
%  "Resolution": Sets resolution of image to be saved
%
%  Improvements to be done:
%  -Add a default "fileName"
%
%  Maxwell Biosystems. Last update: October 17th, 2017
%  Miguel Veloso. miguel.veloso@mxwbio.com

p = inputParser;

p.addParamValue('Directory', '.');
p.addParamValue('Resolution', 200);

p.parse(varargin{:});
args = p.Results;

[path fileName ext] = fileparts(args.Directory)

[SUCCESS,MESSAGE,MESSAGEID] = mkdir(path);

if ~strcmp(ext, '.png')
    ext = '.png';
end

fullPath = fullfile(path, [fileName, ext]);
set(gcf, 'PaperPositionMode', 'auto');
print('-dpng', ['-r' num2str(args.Resolution)], fullPath);
end
