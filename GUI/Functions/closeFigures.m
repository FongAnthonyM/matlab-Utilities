function closeFigures( figs )
%UNTITLED5 Summary of this function goes here
% 
    valid = ishghandle(figs);
    for i = 1:length(figs)
        if valid(i)
            close(figs(i));
        end
    end
end

