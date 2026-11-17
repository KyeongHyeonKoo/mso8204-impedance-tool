function updatePlot = mso8204_sweep_charts(axesHandles)
%MSO8204_SWEEP_CHARTS Set up four sweep charts on regular or UI axes.
% Updates take frequency (Hz) and columns [abs(Z), Rs, X, L, Rp].

lines = gobjects(1, 5);
lines(1) = plot(axesHandles(1), NaN, NaN, "-o", "MarkerSize", 3);
lines(2:3) = plot(axesHandles(2), NaN, NaN, "-o", NaN, NaN, "--o", "MarkerSize", 3);
lines(4) = plot(axesHandles(3), NaN, NaN, "-o", "MarkerSize", 3);
lines(5) = plot(axesHandles(4), NaN, NaN, "-o", "MarkerSize", 3);
legend(axesHandles(2), lines(2:3), ["Rs", "X"], "Location", "northeast");

titles = ["Impedance Magnitude", "Resistance and Reactance", ...
    "Inductance", "Parallel Resistance"];
units = ["|Z| (ohm)", "Rs, X (ohm)", "L (H)", "Rp (ohm)"];
for idx = 1:numel(axesHandles)
    ax = axesHandles(idx);
    title(ax, titles(idx));
    xlabel(ax, "Frequency (Hz)");
    ylabel(ax, units(idx));
    grid(ax, "on");
end
updatePlot = @setData;

    function setData(frequency, values)
        for column = 1:numel(lines)
            if isgraphics(lines(column))
                set(lines(column), "XData", frequency, "YData", values(:, column));
            end
        end
    end
end
