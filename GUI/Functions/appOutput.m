function [out] = appOutput(func,varargin)
    app = func(varargin{:});
    app.close = false;
    waitfor(app, 'active', false);
    try
        if app.allowed
            out = app.getValues();
        else
            out = [];
        end
    catch
        out = [];
    end
    try
        close(app.UIFigure);
    catch
    end
end

