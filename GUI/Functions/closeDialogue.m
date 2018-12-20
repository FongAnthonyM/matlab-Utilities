function closeDialogue(src, callbackdata)
% closeDiaglogue
%   A function that asks the user if they want to close the current figure.
%   Typically used to replace the default CloseRequestFcn.
    if isempty(src.Name) || strcmp(src.Name, '')
        name = sprintf('Figure %d', src.Number);
    else
        name = src.Name;
    end
    title = 'Close Request Function';
    str = sprintf('Do you wish to close %s?', name);
    selection = questdlg(str, title, 'Yes', 'No', 'No');
    switch selection 
    case 'Yes'
        delete(src)
    case 'No'
        return 
    end
end

