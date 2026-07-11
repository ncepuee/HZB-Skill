function report = audit_ieee_case(pfcase)
%AUDIT_IEEE_CASE Validate a normalized MATPOWER-style IEEE bus case.

issues = cell(0, 3);
required = {'baseMVA', 'bus', 'branch'};
for k = 1:numel(required)
    if ~isfield(pfcase, required{k})
        issues(end + 1, :) = {'error', 'missing-field', ...
            sprintf('Missing pfcase.%s.', required{k})}; %#ok<AGROW>
    end
end

if ~isempty(issues)
    report = finish_report(issues, struct());
    return;
end

bus = pfcase.bus;
branch = pfcase.branch;
if ~isnumeric(bus) || size(bus, 2) < 10
    issues(end + 1, :) = {'error', 'bus-shape', ...
        'pfcase.bus must be numeric with at least 10 columns.'};
end
if ~isnumeric(branch) || size(branch, 2) < 6
    issues(end + 1, :) = {'error', 'branch-shape', ...
        'pfcase.branch must be numeric with at least 6 columns.'};
end
if ~isscalar(pfcase.baseMVA) || ~isfinite(pfcase.baseMVA) || pfcase.baseMVA <= 0
    issues(end + 1, :) = {'error', 'base-mva', ...
        'pfcase.baseMVA must be a positive finite scalar.'};
end
if any(strcmp(issues(:, 1), 'error'))
    report = finish_report(issues, struct());
    return;
end

busId = bus(:, 1);
busType = bus(:, 2);
if numel(unique(busId)) ~= numel(busId)
    issues(end + 1, :) = {'error', 'duplicate-bus', ...
        'Bus IDs must be unique.'};
end
if any(~ismember(busType, [1 2 3]))
    issues(end + 1, :) = {'error', 'bus-type', ...
        'Bus types must use PQ=1, PV=2, REF=3.'};
end
if nnz(busType == 3) ~= 1
    issues(end + 1, :) = {'error', 'reference-count', ...
        sprintf('Expected exactly one REF bus; found %d.', nnz(busType == 3))};
end
if any(~isfinite(bus), 'all')
    issues(end + 1, :) = {'error', 'bus-nonfinite', ...
        'Bus matrix contains nonfinite values.'};
end
if any(bus(:, 3) <= 0)
    issues(end + 1, :) = {'error', 'voltage-positive', ...
        'All bus voltage magnitudes must be positive.'};
end

from = branch(:, 1);
to = branch(:, 2);
if any(~ismember(from, busId)) || any(~ismember(to, busId))
    issues(end + 1, :) = {'error', 'branch-endpoint', ...
        'Every branch endpoint must reference an existing bus ID.'};
end
if any(from == to)
    issues(end + 1, :) = {'error', 'self-branch', ...
        'Self-connected branches are not allowed.'};
end
if any(abs(branch(:, 3) + 1i * branch(:, 4)) < eps)
    issues(end + 1, :) = {'error', 'zero-impedance', ...
        'Every branch must have nonzero series impedance.'};
end
if any(~isfinite(branch), 'all')
    issues(end + 1, :) = {'error', 'branch-nonfinite', ...
        'Branch matrix contains nonfinite values.'};
end
if any(branch(:, 6) < 0)
    issues(end + 1, :) = {'warning', 'negative-tap', ...
        'Negative taps require an explicit phase/orientation convention.'};
end

stats = struct();
stats.baseMVA = pfcase.baseMVA;
stats.nBus = size(bus, 1);
stats.nBranch = size(branch, 1);
stats.nPQ = nnz(busType == 1);
stats.nPV = nnz(busType == 2);
stats.nREF = nnz(busType == 3);
stats.referenceBus = busId(busType == 3).';
report = finish_report(issues, stats);
end

function report = finish_report(rows, stats)
if isempty(rows)
    issues = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        'VariableNames', {'Severity', 'Code', 'Message'});
else
    issues = cell2table(rows, ...
        'VariableNames', {'Severity', 'Code', 'Message'});
    issues.Severity = string(issues.Severity);
    issues.Code = string(issues.Code);
    issues.Message = string(issues.Message);
end
report = struct();
report.ok = ~any(issues.Severity == "error");
report.issues = issues;
report.stats = stats;
end
