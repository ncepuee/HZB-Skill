function report = compare_ieee_pf_sim(cfg)
%COMPARE_IEEE_PF_SIM Compare an IEEE power-flow result with Simulink output.
%
% See references/data-contract.md for the cfg and solver result contracts.

required = {'projectRoot', 'model', 'caseFunction', 'referenceBus'};
for k = 1:numel(required)
    if ~isfield(cfg, required{k}) || isempty(cfg.(required{k}))
        error('compare_ieee_pf_sim:MissingConfig', ...
            'Missing cfg.%s.', required{k});
    end
end

projectRoot = char(string(cfg.projectRoot));
model = char(string(cfg.model));
assert(isfolder(projectRoot), 'Project root not found: %s', projectRoot);
addpath(projectRoot);
for path = reshape(get_cfg(cfg, 'addPaths', {}), 1, [])
    addpath(char(string(path{1})));
end

caseFcn = to_function(get_cfg(cfg, 'caseFunction', []));
solverFcn = to_function(get_cfg(cfg, 'solverFunction', 'pf_run_case'));
pfcase = caseFcn();
caseAudit = audit_ieee_case(pfcase);
if ~caseAudit.ok
    disp(caseAudit.issues);
    error('compare_ieee_pf_sim:CaseAudit', ...
        'Case audit failed. Fix structural errors before simulation.');
end

pf = run_solver(solverFcn, pfcase);
validate_solver_result(pf);
if ~logical(pf.success)
    error('compare_ieee_pf_sim:PowerFlow', 'Power flow did not converge.');
end

busId = double(pf.bus.ID(:));
nBus = numel(busId);
referenceBus = double(cfg.referenceBus);
refIndex = find(busId == referenceBus, 1);
if isempty(refIndex)
    error('compare_ieee_pf_sim:ReferenceBus', ...
        'Reference bus %g is not present in the solver result.', referenceBus);
end

simBusIds = double(get_cfg(cfg, 'simBusIds', busId));
simBusIds = simBusIds(:);
if numel(simBusIds) ~= nBus || numel(unique(simBusIds)) ~= nBus || ...
        ~isempty(setxor(simBusIds, busId))
    error('compare_ieee_pf_sim:BusMap', ...
        'cfg.simBusIds must be a one-to-one permutation of solver bus IDs.');
end

if isfield(cfg, 'simOut') && ~isempty(cfg.simOut)
    simOut = cfg.simOut;
    elapsed = NaN;
else
    modelFile = fullfile(projectRoot, [model '.slx']);
    if ~bdIsLoaded(model)
        if isfile(modelFile)
            load_system(modelFile);
        else
            load_system(model);
        end
    end
    run_pre_simulation(cfg, model);
    simArgs = {'ReturnWorkspaceOutputs', 'on'};
    stopTime = get_cfg(cfg, 'stopTime', '');
    if ~isempty(stopTime)
        simArgs = [simArgs, {'StopTime', char(string(stopTime))}];
    end
    timer = tic;
    simOut = sim(model, simArgs{:});
    elapsed = toc(timer);
end

vmName = char(string(get_cfg(cfg, 'vmVariable', 'Umag_all')));
vaName = char(string(get_cfg(cfg, 'vaVariable', 'Uangle_all')));
vmRaw = get_sim_output(simOut, vmName);
vaRaw = get_sim_output(simOut, vaName);
vmBySimOrder = extract_vector(vmRaw, nBus, cfg, 'vm');
vaBySimOrder = extract_vector(vaRaw, nBus, cfg, 'va');

[present, location] = ismember(busId, simBusIds);
assert(all(present), 'Could not map every solver bus to simulation output.');
simVm = vmBySimOrder(location);
simVa = vaBySimOrder(location);

pfVm = double(pf.bus.Vm(:));
pfVa = wrap_angle(double(pf.bus.Va_rad(:)) - double(pf.bus.Va_rad(refIndex)));
simVa = wrap_angle(simVa - simVa(refIndex));
dVm = simVm - pfVm;
dVa = wrap_angle(simVa - pfVa);

vSim = simVm .* exp(1i * simVa);
sReconstructed = vSim .* conj(pf.Ybus * vSim);
pfP = double(pf.bus.P_calc(:));
pfQ = double(pf.bus.Q_calc(:));
dP = real(sReconstructed) - pfP;
dQ = imag(sReconstructed) - pfQ;

comparison = table(busId, pfVm, simVm, dVm, pfVa, simVa, dVa, ...
    pfP, real(sReconstructed), dP, pfQ, imag(sReconstructed), dQ, ...
    'VariableNames', {'Bus', 'PF_Vm_pu', 'Sim_Vm_pu', 'dVm_pu', ...
    'PF_Va_ref_rad', 'Sim_Va_ref_rad', 'dVa_rad', ...
    'PF_P_pu', 'Reconstructed_P_pu', 'dP_pu', ...
    'PF_Q_pu', 'Reconstructed_Q_pu', 'dQ_pu'});

summary = make_summary(comparison, pf, referenceBus, elapsed, cfg);
report = struct();
report.config = cfg;
report.caseAudit = caseAudit;
report.powerFlow = pf;
report.simOut = simOut;
report.comparison = comparison;
report.summary = summary;
report.pass = summary.pass;

outputDirectory = char(string(get_cfg(cfg, 'outputDirectory', '')));
if ~isempty(outputDirectory)
    if ~isfolder(outputDirectory), mkdir(outputDirectory); end
    prefix = char(string(get_cfg(cfg, 'reportPrefix', model)));
    prefix = regexprep(prefix, '[^A-Za-z0-9_.-]', '_');
    csvFile = fullfile(outputDirectory, [prefix '_bus_comparison.csv']);
    txtFile = fullfile(outputDirectory, [prefix '_summary.txt']);
    writetable(comparison, csvFile);
    write_summary(txtFile, summary, model, referenceBus);
    report.csvFile = csvFile;
    report.summaryFile = txtFile;
end

fprintf('PF success=%d, iterations=%g, mismatch=%.6g\n', ...
    logical(pf.success), get_result_field(pf, 'iterations', NaN), ...
    get_result_field(pf, 'max_mismatch', NaN));
fprintf('max |dVm|=%.6g pu at Bus %g\n', summary.maxAbsDVm, summary.busMaxDVm);
fprintf('max |dVa|=%.6g rad at Bus %g\n', summary.maxAbsDVa, summary.busMaxDVa);
fprintf('max |dP|=%.6g pu, max |dQ|=%.6g pu (reconstructed)\n', ...
    summary.maxAbsDP, summary.maxAbsDQ);
fprintf('alignment pass=%d\n', summary.pass);
end

function result = run_solver(solverFcn, pfcase)
try
    result = solverFcn(pfcase, []);
catch firstError
    try
        result = solverFcn(pfcase);
    catch
        rethrow(firstError);
    end
end
end

function validate_solver_result(result)
required = {'success', 'bus', 'Ybus'};
for k = 1:numel(required)
    if ~isfield(result, required{k})
        error('compare_ieee_pf_sim:SolverContract', ...
            'Solver result is missing field %s.', required{k});
    end
end
if ~istable(result.bus)
    error('compare_ieee_pf_sim:SolverContract', ...
        'Solver result.bus must be a table. Add a solver adapter.');
end
busFields = {'ID', 'Vm', 'Va_rad', 'P_calc', 'Q_calc'};
for k = 1:numel(busFields)
    if ~ismember(busFields{k}, result.bus.Properties.VariableNames)
        error('compare_ieee_pf_sim:SolverContract', ...
            'Solver result.bus is missing variable %s.', busFields{k});
    end
end
end

function run_pre_simulation(cfg, model)
callback = get_cfg(cfg, 'preSimulationFcn', []);
if isempty(callback), return; end
callback = to_function(callback);
n = nargin(callback);
if n == 0
    callback();
elseif n == 1
    callback(model);
else
    callback(model, cfg);
end
end

function output = get_sim_output(simOut, name)
output = [];
try
    output = simOut.get(name);
catch
end
if isempty(output)
    try
        output = simOut.(name);
    catch
    end
end
if isempty(output)
    error('compare_ieee_pf_sim:MissingOutput', ...
        'Simulation output %s was not found.', name);
end
end

function values = extract_vector(raw, nExpected, cfg, prefix)
if isa(raw, 'timeseries')
    values = final_sample(raw.Data);
elseif isnumeric(raw)
    values = final_sample(raw);
elseif isstruct(raw) && isfield(raw, 'signals') && isfield(raw.signals, 'values')
    values = final_sample(raw.signals.values);
elseif isstruct(raw)
    explicitName = [prefix 'Fields'];
    patternName = [prefix 'FieldPattern'];
    fields = get_cfg(cfg, explicitName, {});
    if isempty(fields)
        pattern = char(string(get_cfg(cfg, patternName, '')));
        if ~isempty(pattern)
            fields = arrayfun(@(k) sprintf(pattern, k), 1:nExpected, ...
                'UniformOutput', false);
        else
            fields = natural_timeseries_fields(raw);
        end
    end
    if numel(fields) ~= nExpected
        error('compare_ieee_pf_sim:OutputWidth', ...
            'Expected %d %s fields; found %d.', nExpected, prefix, numel(fields));
    end
    values = zeros(nExpected, 1);
    for k = 1:nExpected
        field = char(string(fields{k}));
        if ~isfield(raw, field)
            error('compare_ieee_pf_sim:MissingField', ...
                'Output struct is missing field %s.', field);
        end
        item = raw.(field);
        if isa(item, 'timeseries')
            sample = final_sample(item.Data);
        elseif isnumeric(item)
            sample = final_sample(item);
        else
            error('compare_ieee_pf_sim:OutputType', ...
                'Unsupported field type %s for %s.', class(item), field);
        end
        if numel(sample) ~= 1
            error('compare_ieee_pf_sim:OutputWidth', ...
                'Field %s must contain a scalar signal.', field);
        end
        values(k) = sample;
    end
else
    error('compare_ieee_pf_sim:OutputType', ...
        'Unsupported simulation output type: %s.', class(raw));
end
values = double(values(:));
if numel(values) ~= nExpected
    error('compare_ieee_pf_sim:OutputWidth', ...
        'Expected %d bus values; extracted %d.', nExpected, numel(values));
end
end

function sample = final_sample(data)
data = double(data);
if isscalar(data)
    sample = data;
elseif isvector(data)
    sample = data(end);
else
    sample = squeeze(data(end, :, :, :, :, :));
    sample = sample(:);
end
end

function fields = natural_timeseries_fields(value)
allFields = fieldnames(value);
keep = false(size(allFields));
order = inf(size(allFields));
for k = 1:numel(allFields)
    item = value.(allFields{k});
    keep(k) = isa(item, 'timeseries') || isnumeric(item);
    numbers = regexp(allFields{k}, '\d+', 'match');
    if ~isempty(numbers), order(k) = str2double(numbers{end}); end
end
fields = allFields(keep);
order = order(keep);
[~, idx] = sortrows([isinf(order), order], [1 2]);
fields = fields(idx);
end

function summary = make_summary(tbl, pf, referenceBus, elapsed, cfg)
[summary.maxAbsDVm, iVm] = max(abs(tbl.dVm_pu));
[summary.maxAbsDVa, iVa] = max(abs(tbl.dVa_rad));
[summary.maxAbsDP, iP] = max(abs(tbl.dP_pu));
[summary.maxAbsDQ, iQ] = max(abs(tbl.dQ_pu));
summary.busMaxDVm = tbl.Bus(iVm);
summary.busMaxDVa = tbl.Bus(iVa);
summary.busMaxDP = tbl.Bus(iP);
summary.busMaxDQ = tbl.Bus(iQ);
summary.referenceBus = referenceBus;
summary.simulationElapsedSeconds = elapsed;
summary.pfIterations = get_result_field(pf, 'iterations', NaN);
summary.pfMaxMismatch = get_result_field(pf, 'max_mismatch', NaN);
tolerance = get_cfg(cfg, 'tolerances', struct());
summary.toleranceVm = get_cfg(tolerance, 'vm', 1e-4);
summary.toleranceVa = get_cfg(tolerance, 'va', 1e-4);
summary.toleranceP = get_cfg(tolerance, 'p', 1e-3);
summary.toleranceQ = get_cfg(tolerance, 'q', 1e-3);
summary.pass = summary.maxAbsDVm <= summary.toleranceVm && ...
    summary.maxAbsDVa <= summary.toleranceVa && ...
    summary.maxAbsDP <= summary.toleranceP && ...
    summary.maxAbsDQ <= summary.toleranceQ;
end

function write_summary(path, summary, model, referenceBus)
file = fopen(path, 'w');
if file < 0, error('Could not open summary file: %s', path); end
cleanup = onCleanup(@() fclose(file));
fprintf(file, 'Model: %s\n', model);
fprintf(file, 'Reference bus: %g\n', referenceBus);
fprintf(file, 'PF iterations: %.12g\n', summary.pfIterations);
fprintf(file, 'PF max mismatch: %.12g\n', summary.pfMaxMismatch);
fprintf(file, 'Max |dVm|: %.12g pu at Bus %g\n', summary.maxAbsDVm, summary.busMaxDVm);
fprintf(file, 'Max |dVa|: %.12g rad at Bus %g\n', summary.maxAbsDVa, summary.busMaxDVa);
fprintf(file, 'Max |dP| reconstructed: %.12g pu at Bus %g\n', summary.maxAbsDP, summary.busMaxDP);
fprintf(file, 'Max |dQ| reconstructed: %.12g pu at Bus %g\n', summary.maxAbsDQ, summary.busMaxDQ);
fprintf(file, 'Pass: %d\n', summary.pass);
end

function value = get_cfg(cfg, name, default)
if isstruct(cfg) && isfield(cfg, name) && ~isempty(cfg.(name))
    value = cfg.(name);
else
    value = default;
end
end

function fcn = to_function(value)
if isa(value, 'function_handle')
    fcn = value;
else
    fcn = str2func(char(string(value)));
end
end

function value = get_result_field(result, name, default)
if isfield(result, name), value = result.(name); else, value = default; end
end

function angle = wrap_angle(angle)
angle = atan2(sin(angle), cos(angle));
end
