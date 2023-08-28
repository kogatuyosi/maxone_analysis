function saveChannelGroupsToFile( groups , file_name ) 

fid = fopen( file_name , 'w' );

assert( fid ~= -1, ['Cannot open file: ' file_name] ) 

for group_idx = 1:length( groups )

    for item = 1:length(groups{group_idx})
        fwrite( fid, [num2str(groups{group_idx}(item)), ' ']);
    end

    fprintf( fid, '\n');

end

fclose(fid)


