function [ notches ] = harmonicNotch(harm, band, order, fs, cascades)
%harmonicNotch
%   Creates Notch filters for a frequency's harmonics.
%   Input
%   :harm:      double      The frequency harmonic to remove.
%   :band:      double      The width of the band for Notching.
%   :order:     double      The order of the Notch filters.
%   :fs:        double      The sample frequency the filters will be applied to.
%   :cascades:  double      The number of harmonics to notch.
%   Output
%   :notches:   cell        An array of all the notches filters
    if nargin < 5
        total = floor(fs/(harm*2));
    else
        total = cascades;
    end
    notches = cell(total,1);
    for i = 1:total
        notches{i} = designfilt('bandstopiir', 'FilterOrder', order, ...
                                'HalfPowerFrequency1', harm*i-band/2, ...
                                'HalfPowerFrequency2', harm*i+band/2, ...
                                'SampleRate', fs);
    end
end

