function window = mso8204_launcher()
%MSO8204_LAUNCHER Open a control panel for the existing impedance sweep.

cfg = mso8204_config();
verifiedHost = "";
verifiedIdn = "";
busy = false;

window = uifigure("Name", "MSO8204 Impedance Tool", ...
    "Position", [65, 65, 1010, 760]);
grid = uigridlayout(window, [9, 2]);
grid.ColumnWidth = {185, "1x"};
grid.RowHeight = {28, 28, 28, 28, 28, 44, 34, 44, "1x"};
grid.Padding = [18, 14, 18, 14];
grid.RowSpacing = 6;

addLabel("Scope IP / hostname (TCP 5555)", 1, 1);
host = uieditfield(grid, "text", "Value", "", ...
    "ValueChangedFcn", @resetConnection);
place(host, 1, 2);
startKHz = addNumber("Start frequency (kHz)", cfg.fStart / 1e3, 2, realmin);
stopKHz = addNumber("Stop frequency (kHz)", cfg.fStop / 1e3, 3, realmin);
points = addNumber("Sweep points", cfg.nPoints, 4, 2);
points.RoundFractionalValues = "on";
shunt = addNumber("Sense resistance (ohm)", cfg.rShunt, 5, realmin);
addLabel("Instrument identity", 6, 1);
identity = addLabel("Not checked", 6, 2);
identity.WordWrap = "on";

testButton = uibutton(grid, "Text", "Test Connection", "ButtonPushedFcn", @testConnection);
place(testButton, 7, 1);
runButton = uibutton(grid, "Text", "Run Sweep", "ButtonPushedFcn", @runSweep, ...
    "Enable", "off");
place(runButton, 7, 2);
status = addLabel("Disconnected", 8, [1, 2]);
status.WordWrap = "on";

results = uipanel(grid, "Title", "Sweep Results");
place(results, 9, [1, 2]);
charts = uigridlayout(results, [2, 2]);
charts.RowHeight = {"1x", "1x"};
charts.ColumnWidth = {"1x", "1x"};
axesHandles = [uiaxes(charts), uiaxes(charts), uiaxes(charts), uiaxes(charts)];
for chartIndex = 1:numel(axesHandles)
    place(axesHandles(chartIndex), ceil(chartIndex / 2), mod(chartIndex - 1, 2) + 1);
end
updateCharts = mso8204_sweep_charts(axesHandles);
window.CloseRequestFcn = @closeWindow;

    function label = addLabel(value, row, column)
        label = uilabel(grid, "Text", value);
        place(label, row, column);
    end

    function field = addNumber(title, value, row, lower)
        addLabel(title, row, 1);
        field = uieditfield(grid, "numeric", "Value", value, "Limits", [lower, Inf]);
        place(field, row, 2);
    end

    function resetConnection(~, ~)
        verifiedHost = "";
        verifiedIdn = "";
        identity.Text = "Not checked";
        status.Text = "Disconnected";
        runButton.Enable = "off";
    end

    function testConnection(~, ~)
        resetConnection();
        enteredHost = strtrim(string(host.Value));
        if strlength(enteredHost) == 0
            status.Text = "Enter the scope IP address or hostname.";
            return;
        end
        connection = cfg;
        connection.ip = enteredHost;
        setBusy(true);
        restoreUI = onCleanup(@() setBusy(false));
        status.Text = "Checking instrument identity...";
        drawnow;
        try
            idn = string(mso8204_easy_tcp_test(connection));
            identity.Text = idn;
            fields = strtrim(split(idn, ","));
            if numel(fields) < 2 || ~strcmpi(fields(2), "MSO8204A")
                status.Text = "Instrument responded, but it is not an MSO8204A.";
                return;
            end
            verifiedHost = enteredHost;
            verifiedIdn = idn;
            status.Text = "MSO8204A verified.";
        catch err
            showError(err);
        end
    end

    function runSweep(~, ~)
        if strlength(verifiedIdn) == 0 || strtrim(string(host.Value)) ~= verifiedHost
            resetConnection();
            return;
        end
        if any(~isfinite([startKHz.Value, stopKHz.Value, points.Value, shunt.Value])) ...
                || stopKHz.Value <= startKHz.Value
            status.Text = "Enter finite sweep settings with stop frequency above start.";
            return;
        end
        answer = uiconfirm(window, sprintf( ...
            "This sweep enables generator G%d at %.3g Vpp. Confirm the wiring and sense resistance.", ...
            cfg.sourceChannel, cfg.sourceVpp), "Confirm Sweep", ...
            "Options", ["Run Sweep", "Cancel"], "DefaultOption", 2, "CancelOption", 2);
        if ~strcmp(answer, "Run Sweep")
            return;
        end
        folder = uigetdir(pwd, "Choose a folder for sweep results");
        if isequal(folder, 0)
            return;
        end

        sweep = cfg;
        sweep.ip = verifiedHost;
        sweep.expectedIdn = verifiedIdn;
        sweep.turnOffGeneratorOnExit = true;
        sweep.fStart = startKHz.Value * 1e3;
        sweep.fStop = stopKHz.Value * 1e3;
        sweep.nPoints = points.Value;
        sweep.rShunt = shunt.Value;
        base = "mso8204_sweep_" + string(datetime("now", "Format", "yyyyMMdd_HHmmss_SSS"));
        sweep.outputXlsx = fullfile(folder, base + ".xlsx");
        sweep.outputMat = fullfile(folder, base + "_raw.mat");

        setBusy(true);
        restoreUI = onCleanup(@() setBusy(false));
        status.Text = "Sweep in progress...";
        drawnow;
        try
            mso8204_easy_impedance_sweep(sweep, @showSweepData);
            status.Text = "Sweep complete. Saved " + base + ".xlsx and _raw.mat.";
        catch err
            if strcmp(err.identifier, "MSO8204:UnexpectedInstrument")
                resetConnection();
            end
            showError(err);
        end
    end

    function showSweepData(frequency, values)
        updateCharts(frequency, values);
        status.Text = sprintf("Sweep in progress: %d / %d points", ...
            numel(frequency), points.Value);
    end

    function setBusy(value)
        busy = value;
        state = "on";
        if busy
            state = "off";
        end
        controls = {host, startKHz, stopKHz, points, shunt, testButton};
        for idx = 1:numel(controls)
            control = controls{idx};
            control.Enable = state;
        end
        runButton.Enable = "off";
        if ~busy && strlength(verifiedIdn) > 0
            runButton.Enable = "on";
        end
    end

    function showError(err)
        status.Text = err.message;
        uialert(window, err.message, "MSO8204 Error");
    end

    function closeWindow(~, ~)
        if ~busy
            delete(window);
        end
    end
end

function place(component, row, column)
component.Layout.Row = row;
component.Layout.Column = column;
end
