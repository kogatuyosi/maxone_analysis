classdef file < handle
    %properties (Hidden)
    properties
        rawFname;

        x;
        y;
        channel;
        electrode;
        bpf;

        gain;
        lsb;
        info;
        maxTime;
        maxSamples;
        h5Sig;

        maxSessions;
        stimTimes;
        nChannels;
        
        start_time;
        stop_time;
        map; 
    end
    
    methods
        
        function this = file( rawFname, varargin )
            % Reads the meta data from the file
            p = inputParser;
            
            p.addParameter('nChannels', 1024);
            p.addParameter('bpf', [300 3000 4]); %[lowCutoff, highCutoff, order]
            
            p.parse(varargin{:});
            args = p.Results;
            this.nChannels = args.nChannels;
            this.rawFname = rawFname;
            this.lsb = 1;
            version = h5read(rawFname,'/version');
            this.bpf.lowCutoff = args.bpf(1);
            this.bpf.highCutoff = args.bpf(2);
            this.bpf.order = args.bpf(3);
            
            this.bpf.embeddedFilter = mxw.util.bandpass(this.bpf.lowCutoff, this.bpf.highCutoff, this.bpf.order);
            
            if strcmp( version, '20160704' )
                this.h5Sig = '/sig';
                %this.gain = h5read(rawFname,'/settings/gain');
                m = h5read(rawFname,'/mapping');
                this.x = m.x;
                this.y = m.y;
                this.channel = m.channel;
                this.electrode = m.electrode;
                %if (this.gain == 512)
                %    this.lsb = 6.2;
                %end
                %if (this.gain == 1024)
                %    this.lsb = 3.1;
                %end
                time = this.getTime();
                this.start_time = time{1};
                this.stop_time = time{2};
                
            elseif strcmp( version, '20161003' )
                this.h5Sig = '/ephys/signal';
                this.info = h5info( rawFname, this.h5Sig );
                %h5map = h5read(rawFname, '/ephys/mapping');
                this.map = mea1k.map(rawFname);
                
            elseif strcmp( version, '0' )%% I HAVE TO CHECK THIS
                this.h5Sig = '/sig';
            end            
        end

        function time = getTime(this)
            h5_time_str = h5read( this.rawFname , '/time');
            time_str = strrep(h5_time_str{1} , '\n' , '');
            time_str = strsplit(time_str, ';\n');
            % remove 'start: '
            time{1} = strrep(time_str{1} , 'start: ' , '');
            % remove 'stop: '
            time{2} = strrep(time_str{2} , 'stop: ' , '');
        end
        
        function spikes = getSpikeTimes(this)
            % Get matrix with spike times and spike amplitudes from the file
            spikes = h5read( this.rawFname , '/proc0/spikeTimes');
        end

        function getH5Info(this)
            % Gets information about the size of the data matrix from the file.
            % 
            % This operation can take some time. Only run it if needed.
            this.info = h5info( this.rawFname, this.h5Sig );
            this.maxSamples = this.info.Dataspace.Size(1);
            this.maxTime = this.maxSamples/20000.0;
        end

        function X = getRawData(this, start, len)
            % Loads a matrix of data from disk.
            % 
            % start             start frame
            % len               length in frames of the chunk to load
            %
            if (start == 1 && strcmp(len, 'end'))
                X = double(h5read(this.rawFname , this.h5Sig));
            else
                X = double(h5read(this.rawFname , this.h5Sig, [start 1], [len, this.nChannels]));
            end
        end
        
        function X = getBPFData(this, start, len, varargin)
            % Loads a matrix of data from disk.
            %
            % start             start frame
            % len               length in frames of the chunk to load
            %
            p = inputParser;
            p.addParameter('bpf', this.bpf.embeddedFilter);
            
            p.parse(varargin{:});
            args = p.Results;
            
            bpf = args.bpf;            
            X = getRawData(this, start, len);    
            X = bpf.filter(X);
        end
        
        function X = getRawChannels(this, channels, start, size, chunkSize)
            % Extracts a vector of channels from the file.
            % 
            % channels          vector of channels to load
            % start             start frame
            % size              length in frames of the chunk to load
            %
            if isscalar(channels)
                X = double(h5read(this.rawFname , this.h5Sig, [start channels], [size, 1]));
            elseif isvector(channels)
                X = zeros(size, length(channels));
                for chunk = mxw.util.chunker(start, start+size-1, chunkSize)
                    for i = 1:length(channels)
                        X(chunk.start0:chunk.stop0,i) = double(h5read(this.rawFname , this.h5Sig, [chunk.start channels(i)], [chunk.length, 1]));
                    end
                end
            else
                error('"channels" must be a scalar or a vector');
            end
        end
        
        function X = getBPFChannels(this, channels, start, len, varargin)
            % Extracts one single channel from the file.
            % 
            % channel           channel to load
            % start             start frame
            % len               length in frames of the chunk to load
            %
            p = inputParser;
            p.addParameter('bpf', this.bpf.embeddedFilter);
            
            p.parse(varargin{:});
            args = p.Results;
            
            bpf = args.bpf;    
            X = getRawChannels(this, channels, start, len);
            X = bpf.filter(X);
        end

        function M = getCutoutAverage(this, timePoints, preSamples, postSamples , average_function)
            avg_fnc = @median
            if nargin > 4
                avg_fnc = average_function;
            end
            M1 = this.getCutouts( timePoints , preSamples , postSamples );
            nSamples = preSamples + postSamples;
            M2 = reshape ( M1 , nSamples , this.nChannels , length(timePoints) );
            M3 = ( squeeze ( avg_fnc( M2 , 3 ) ) );

            % this last step removes the mean from the traces
            %M4 = M3 - repmat( mean( M3 )  , size(M3,1) , 1);
        end

        function X = getCutouts(this, timePoints, preTime, postTime)
            % Get cutouts from all channels at the given time points
            % 
            % timePoints        vector of time points where to extract data
            % preTime           frames to load before a time point
            % postTime          frames to load after a time point
            % X                 matrix with dimensions: (preTime+postTime)*1024 x length(spikeTimes)
            dim1 = (preTime+postTime)*this.nChannels;
            X = zeros( dim1, length(timePoints) );
            for i = 1:length(timePoints)
                mat = double(h5read( this.rawFname , this.h5Sig, [timePoints(i)-preTime 1], [preTime+postTime, this.nChannels]) );
                X(:, i ) = reshape( mat, dim1, 1 );
            end
        end %

        function X=getCutoutsOneChannel(this, channel, timePoints, preTime, postTime )
            % Get cutouts from one channel at the given time points
            % 
            % timePoints        vector of time points where to extract data
            % preTime           frames to load before a time point
            % postTime          frames to load after a time point
            % X                 matrix with dimensions: (preTime+postTime)*1024 x length(spikeTimes)
            dim1 = (preTime+postTime);
            X = zeros( dim1, length(timePoints) );
            for i = 1:length(timePoints)
                X(:, i ) = (this.lsb*h5read( this.rawFname , this.h5Sig, [timePoints(i)-preTime channel], [preTime+postTime, 1]) );
            end
        end %

        function frameNo=getFrameNoAt(this, index)
            % Deprecated
            X = h5read( this.rawFname , this.h5Sig, [index 1027], [1, 2]);
            frameNo = bitor( bitshift( double(X(:,2)) , 16 ) , double(X(:,1)) );
        end

        function frameNo=getFrameNo(this)
            % Deprecated
            frameNo = zeros(this.maxSamples,1);
            fsize = 20000;
            for idx=1:floor(this.maxSamples/fsize)
                startF = (idx-1)*fsize+1;
                X = h5read( this.rawFname , this.h5Sig, [startF 1027], [fsize, 2]);
                frameNo(startF:startF+fsize-1,1) = bitor( bitshift( double(X(:,2)) , 16 ) , double(X(:,1)) );
            end
            startF = (idx)*fsize+1;
            fsize  = this.maxSamples-startF+1;
            X = h5read( this.rawFname , this.h5Sig, [startF 1027], [fsize, 2]);
            frameNo(startF:startF+ fsize - 1 , 1) = bitor( bitshift( double(X(:,2)) , 16 ) , double(X(:,1)) );
        end % getFrameNo

        function dacTrace = getDAC(this, start, len)
            % Get DAC trace of whole file. Can be slow, if file is large
            % 
            % start     start frame
            % len       length in frames of the DAC trace to load
            if (nargin<3)
                start = 1
                len = this.maxSamples
            end
            dacTrace = h5read( this.rawFname, this.h5Sig, [1 1026], [this.maxSamples 1]);
            %this.stimTimes = find ( diff( dacTrace ) > 1 );
        end %
        
        function channelsInUse = getChannelsInUse(this)
            channelsInUse = this.channel(this.electrode>0);
            channelsInUse = channelsInUse + int32(ones(size(channelsInUse))); %To avoid zero indexing
        end

    end
end

