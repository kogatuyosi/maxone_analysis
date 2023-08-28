function savepng( varargin )

p = inputParser;    % Create an instance of the class.

p.addParamValue('Directory',    '.');
p.addParamValue('Resolution',   100);
p.addParamValue('FileName',     'test');

p.parse(varargin{:});
args = p.Results;

directory = [args.Directory '/'];

set(gcf, 'PaperPositionMode', 'auto');

[SUCCESS,MESSAGE,MESSAGEID] = mkdir(args.Directory); %#ok to suppress the warning, if dir already exists

fname = [ directory args.FileName '.png' ];

print('-dpng', ['-r' num2str(args.Resolution)], fname );

end % function
