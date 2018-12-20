function varargout = multicohere(x, y, varargin)
% [Cxy f] = multicohere(x, y, varargin)
%   Runs mschoere on two matrices, where each column is a channel, and 
%   returns a matrix of coherence all pairwise combinations of these 
%   channels. The type of coherence run is dependent on the inputs of 
%   varargin and are the same as MSCOHERE so refere to the MSCOHERE 
%   documentation for a list of posible inputs and outputs.{y,x,f}
%   Inputs
%   :x:             matrix      The input signal that will be on the X dim
%   :y:             matrix		The input singal that will be on the Y dim
%   :varargin:      args        The arguments for mscohere
%   Outputs
%   :Cxy:           matrix      The coherence all pairwise combinations of 
%                               the channels. X dim being the x channels,
%                               the Y dim being the y channels, and Z dim
%                               being the sample or the frequency.
%   :f:             vector      An optional output that is either the 
%                               frequencies or the normalized frequencies
%                               depending on what arguments were put in for
%                               mscohere.
    
    narginchk(2,8)
    
    for i = 1:size(x, 2)
        [out{1:nargout}] = mscohere(x(:,i), y, varargin{:});
        varargout{1}(:,i,:) = out{1};
    end
    if length(out) > 1
        varargout{2} = out{2};
    end
end

