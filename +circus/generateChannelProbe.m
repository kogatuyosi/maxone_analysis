function [geometry]=generateChannelProbe( fname , mapping , group , radius )
% GENERATEPROBE    generates a .prb file, compatible with 'phy' and 'spyking-circus'
% 
%     generateprobe( fname , mapping , group , radius )
% 
%     fname   : name of the generated probe file
%     mapping : mapping structure, as read from an h5 file
%     group   : list of channels
%     radius  : parameter for spyking-circus, what to consider activity from the same cell
%
%     See also MXW.UTIL.ELECTRODEGROUPS

geometry = [];

for ch_idx = 1:length(group)
    idx = find( mapping.channel==group(ch_idx));
    geometry = [geometry ; ch_idx-1 , mapping.x(idx) , mapping.y(idx) ];
end


% writeProbeFile
fid = fopen(fname,'w');
fprintf(fid, 'total_nb_channels = %d\n', length(group) );
fprintf(fid, 'radius = %f\n', radius );

fprintf(fid, 'channel_groups = {\n 1: {\n    ''channels'': [');
for ch_idx = 1:length(group)
    fprintf(fid, '%d,' , ch_idx-1);
end
fprintf(fid, '],\n');
fprintf(fid, '''graph'' : [],\n');
fprintf(fid, '''geometry'': {\n');

for ch_idx = 1:size(geometry,1)
    fprintf(fid, '      %d: [%f,%f],\n' , geometry(ch_idx,1), geometry(ch_idx,2), geometry(ch_idx,3) );
end

fprintf(fid, '}  }  }\n');
fclose(fid)

