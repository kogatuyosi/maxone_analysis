function y=plot_2D_map_clean(x, y, Zcalc, clims,varargin)

border=40;
xmin=min(x)-border;
xmax=max(x)+border;
ymin=min(y)-border;
ymax=max(y)+border;
gridspace_um=5;

xlin=linspace(xmin,xmax,(xmax-xmin)/gridspace_um);
ylin=linspace(ymin,ymax,(ymax-ymin)/gridspace_um);
[XI,YI] = meshgrid(xlin,ylin);

%[idx dist]=get_closest_electrode(neurons{n_list(1)}.x,neurons{n_list(1)}.y);
%avg_elspacing=median(dist);

%interplo_m='nearest';
% interplo_m='cubic';

interplo_m = 'cubic';
i=1;
while i<=length(varargin)
    if not(isempty(varargin{i}))
        if strcmp(varargin{i}, 'nearest')
            interplo_m = 'nearest';
        elseif strcmp(varargin{i}, 'cubic')
            interplo_m = 'cubic';
        else
            fprintf('unknown argument at pos %d\n', 2+i);
        end
    end
    i=i+1;
end


ZI = griddata(x,y,Zcalc,XI,YI,interplo_m);

imagesc([xmin xmax],[ymin ymax],ZI,clims);
%axis tight
axis image
axis ij
xlim([min(x) max(x)]);
ylim([min(y) max(y)]);
box on