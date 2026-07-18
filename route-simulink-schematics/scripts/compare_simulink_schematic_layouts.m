function result = compare_simulink_schematic_layouts(referenceFile,candidateFile,outputDir)
%COMPARE_SIMULINK_SCHEMATIC_LAYOUTS Compare two root-level Simulink layouts.
%   RESULT = COMPARE_SIMULINK_SCHEMATIC_LAYOUTS(REFERENCE,CANDIDATE,OUTDIR)
%   treats REFERENCE as the preferred human layout. The function is
%   read-only with respect to both models and writes CSV/JSON evidence to
%   OUTDIR. It compares block placement/orientation and orthogonal wiring
%   geometry; it does not judge model behavior or electrical correctness.

arguments
    referenceFile (1,1) string
    candidateFile (1,1) string
    outputDir (1,1) string = string(pwd)
end

assert(isfile(referenceFile),'Routing:MissingReference', ...
    'Reference model does not exist: %s',referenceFile);
assert(isfile(candidateFile),'Routing:MissingCandidate', ...
    'Candidate model does not exist: %s',candidateFile);
if ~isfolder(outputDir), mkdir(outputDir); end

reference = read_layout(referenceFile);
candidate = read_layout(candidateFile);
[blockDiff,categorySummary,sharedBlockCount] = ...
    compare_blocks(reference.blocks,candidate.blocks);

result = struct;
result.referenceFile = char(referenceFile);
result.candidateFile = char(candidateFile);
result.referenceMetrics = reference.metrics;
result.candidateMetrics = candidate.metrics;
result.sharedBlockCount = sharedBlockCount;
result.blockDifferenceCount = height(blockDiff);
result.movedBlockCount = nnz(blockDiff.Moved);
result.rotatedBlockCount = nnz(blockDiff.Rotated);
result.resizedBlockCount = nnz(blockDiff.Resized);
result.namePlacementChangeCount = nnz(blockDiff.NamePlacementChanged);
result.improvementPercent = improvement_percent( ...
    reference.metrics,candidate.metrics);

writetable(blockDiff,fullfile(outputDir,'block_layout_differences.csv'));
writetable(categorySummary,fullfile(outputDir,'block_category_summary.csv'));
writetable(reference.bundleMetrics, ...
    fullfile(outputDir,'reference_bundle_metrics.csv'));
writetable(candidate.bundleMetrics, ...
    fullfile(outputDir,'candidate_bundle_metrics.csv'));
writetable(reference.lineBlockConflicts, ...
    fullfile(outputDir,'reference_line_block_conflicts.csv'));
writetable(candidate.lineBlockConflicts, ...
    fullfile(outputDir,'candidate_line_block_conflicts.csv'));
write_json(fullfile(outputDir,'layout_comparison_summary.json'),result);

fprintf('\nREFERENCE (preferred human layout)\n');
print_metrics(reference.metrics);
fprintf('\nCANDIDATE\n');
print_metrics(candidate.metrics);
fprintf('\nBLOCK DIFFERENCES\n');
fprintf('Shared=%d differing=%d moved=%d rotated=%d resized=%d namePlacement=%d\n', ...
    sharedBlockCount,height(blockDiff),result.movedBlockCount,result.rotatedBlockCount, ...
    result.resizedBlockCount,result.namePlacementChangeCount);
disp(categorySummary);
fprintf('\nLOWER-IS-BETTER IMPROVEMENT (reference versus candidate)\n');
print_metrics(result.improvementPercent);
end

function layout = read_layout(modelFile)
[~,modelName] = fileparts(modelFile);
wasLoaded = bdIsLoaded(modelName);
if wasLoaded
    loadedFile = string(get_param(modelName,'FileName'));
    assert(same_file(loadedFile,modelFile),'Routing:ModelNameCollision', ...
        'A different model named %s is already loaded.',modelName);
else
    load_system(modelFile);
end
cleanup = onCleanup(@() close_if_owned(modelName,wasLoaded));

paths = find_system(modelName,'SearchDepth',1,'Type','Block');
paths(strcmp(paths,modelName)) = [];
n = numel(paths);
name = strings(n,1); category = strings(n,1); orientation = strings(n,1);
namePlacement = strings(n,1); position = zeros(n,4); physical = false(n,1);
for k = 1:n
    name(k) = string(get_param(paths{k},'Name'));
    category(k) = block_category(name(k));
    orientation(k) = string(get_param(paths{k},'Orientation'));
    namePlacement(k) = string(get_param(paths{k},'NamePlacement'));
    position(k,:) = get_param(paths{k},'Position');
    ports = get_param(paths{k},'PortHandles');
    physical(k) = (~isempty(ports.LConn) || ~isempty(ports.RConn));
end
blocks = table(name,category,position(:,1),position(:,2),position(:,3), ...
    position(:,4),position(:,3)-position(:,1),position(:,4)-position(:,2), ...
    orientation,namePlacement,physical, ...
    'VariableNames',{'Name','Category','Left','Top','Right','Bottom', ...
    'Width','Height','Orientation','NamePlacement','Physical'});

lineHandles = find_system(modelName,'FindAll','on','SearchDepth',1,'Type','line');
[segments,lineMetrics] = collect_segments(lineHandles);
[blockOverlapCount,blockOverlapArea] = block_overlaps(blocks);
[lineBlockCrossings,lineBlockConflicts] = line_block_crossings(segments,blocks);
[orthogonalCrossings,collinearOverlaps] = line_line_conflicts(segments);
bundleMetrics = collect_bundle_metrics(paths);

if isempty(position)
    canvasWidth = 0; canvasHeight = 0; canvasArea = 0;
else
    canvasWidth = max(position(:,3))-min(position(:,1));
    canvasHeight = max(position(:,4))-min(position(:,2));
    canvasArea = canvasWidth*canvasHeight;
end
metrics = struct( ...
    'blockCount',n, ...
    'physicalBlockCount',nnz(physical), ...
    'lineObjectCount',numel(lineHandles), ...
    'segmentCount',height(segments), ...
    'totalManhattanLength',lineMetrics.totalManhattanLength, ...
    'totalEuclideanLength',lineMetrics.totalEuclideanLength, ...
    'bendCount',lineMetrics.bendCount, ...
    'diagonalSegmentCount',lineMetrics.diagonalSegmentCount, ...
    'zeroLengthSegmentCount',lineMetrics.zeroLengthSegmentCount, ...
    'blockOverlapCount',blockOverlapCount, ...
    'blockOverlapArea',blockOverlapArea, ...
    'lineBlockCrossingCount',lineBlockCrossings, ...
    'lineBlockCrossedBlockCount',height(lineBlockConflicts), ...
    'orthogonalLineCrossingCount',orthogonalCrossings, ...
    'collinearLineOverlapCount',collinearOverlaps, ...
    'completeThreePhaseBundleCount',height(bundleMetrics), ...
    'bundleSignatureMismatchCount',nnz(~bundleMetrics.CommonTurnSignature), ...
    'bundleBendMismatchCount',nnz(~bundleMetrics.EqualBendCount), ...
    'canvasWidth',canvasWidth, ...
    'canvasHeight',canvasHeight, ...
    'canvasArea',canvasArea);

layout = struct('blocks',blocks,'segments',segments, ...
    'bundleMetrics',bundleMetrics,'lineBlockConflicts',lineBlockConflicts, ...
    'metrics',metrics);
clear cleanup
close_if_owned(modelName,wasLoaded);
end

function [segments,metrics] = collect_segments(lineHandles)
lineHandle = zeros(0,1); segmentIndex = zeros(0,1);
x1 = zeros(0,1); y1 = zeros(0,1); x2 = zeros(0,1); y2 = zeros(0,1);
isHorizontal = false(0,1); isVertical = false(0,1);
totalManhattanLength = 0; totalEuclideanLength = 0;
bendCount = 0; diagonalSegmentCount = 0; zeroLengthSegmentCount = 0;
for h = lineHandles(:).'
    try
        points = double(get_param(h,'Points'));
    catch
        continue
    end
    points = remove_consecutive_duplicates(points);
    if size(points,1) >= 3
        direction = diff(points,1,1);
        axisCode = zeros(size(direction,1),1);
        axisCode(direction(:,2)==0 & direction(:,1)~=0) = 1;
        axisCode(direction(:,1)==0 & direction(:,2)~=0) = 2;
        bendCount = bendCount + nnz(axisCode(1:end-1) ~= axisCode(2:end) & ...
            axisCode(1:end-1)~=0 & axisCode(2:end)~=0);
    end
    for j = 1:size(points,1)-1
        a = points(j,:); b = points(j+1,:); delta = b-a;
        if all(delta==0)
            zeroLengthSegmentCount = zeroLengthSegmentCount+1;
            continue
        end
        horizontal = delta(2)==0; vertical = delta(1)==0;
        diagonalSegmentCount = diagonalSegmentCount+double(~horizontal && ~vertical);
        distance1 = sum(abs(delta));
        totalManhattanLength = totalManhattanLength+distance1;
        totalEuclideanLength = totalEuclideanLength+hypot(delta(1),delta(2));
        lineHandle(end+1,1) = double(h); %#ok<AGROW>
        segmentIndex(end+1,1) = j; %#ok<AGROW>
        x1(end+1,1) = a(1); y1(end+1,1) = a(2); %#ok<AGROW>
        x2(end+1,1) = b(1); y2(end+1,1) = b(2); %#ok<AGROW>
        isHorizontal(end+1,1) = horizontal; %#ok<AGROW>
        isVertical(end+1,1) = vertical; %#ok<AGROW>
    end
end
segments = table(lineHandle,segmentIndex,x1,y1,x2,y2,isHorizontal,isVertical, ...
    'VariableNames',{'LineHandle','Segment','X1','Y1','X2','Y2', ...
    'Horizontal','Vertical'});
metrics = struct('totalManhattanLength',totalManhattanLength, ...
    'totalEuclideanLength',totalEuclideanLength,'bendCount',bendCount, ...
    'diagonalSegmentCount',diagonalSegmentCount, ...
    'zeroLengthSegmentCount',zeroLengthSegmentCount);
end

function [count,totalArea] = block_overlaps(blocks)
count = 0; totalArea = 0;
for i = 1:height(blocks)-1
    for j = i+1:height(blocks)
        width = min(blocks.Right(i),blocks.Right(j))-max(blocks.Left(i),blocks.Left(j));
        heightValue = min(blocks.Bottom(i),blocks.Bottom(j))-max(blocks.Top(i),blocks.Top(j));
        if width > 0 && heightValue > 0
            count = count+1;
            totalArea = totalArea+width*heightValue;
        end
    end
end
end

function [count,conflicts] = line_block_crossings(segments,blocks)
count = 0; perBlock = zeros(height(blocks),1);
physicalBlocks = find(blocks.Physical);
segmentArray = [segments.X1 segments.Y1 segments.X2 segments.Y2 ...
    segments.Horizontal segments.Vertical];
blockArray = [blocks.Left blocks.Top blocks.Right blocks.Bottom];
for s = 1:height(segments)
    if ~(segmentArray(s,5) || segmentArray(s,6)), continue; end
    a = segmentArray(s,1:2); b = segmentArray(s,3:4);
    for k = physicalBlocks(:).'
        if segment_crosses_interior(a,b,blockArray(k,:))
            count = count+1;
            perBlock(k) = perBlock(k)+1;
        end
    end
end
mask = perBlock>0;
conflicts = table(blocks.Name(mask),perBlock(mask), ...
    'VariableNames',{'Block','CrossingCount'});
conflicts = sortrows(conflicts,'CrossingCount','descend');
end

function [crossings,overlaps] = line_line_conflicts(segments)
crossings = 0; overlaps = 0;
line = segments.LineHandle;
x1 = min(segments.X1,segments.X2); x2 = max(segments.X1,segments.X2);
y1 = min(segments.Y1,segments.Y2); y2 = max(segments.Y1,segments.Y2);
horizontal = find(segments.Horizontal); vertical = find(segments.Vertical);

% Use numeric arrays and coordinate rejection instead of table indexing in
% the hot loop. This remains exact but is fast enough for feeder-scale models.
for index = horizontal(:).'
    candidate = vertical(x1(vertical)>x1(index) & x1(vertical)<x2(index) & ...
        y1(vertical)<y1(index) & y2(vertical)>y1(index) & ...
        line(vertical)~=line(index));
    crossings = crossings+numel(candidate);
end
for indexSet = {horizontal,vertical}
    indices = indexSet{1};
    if isequal(indices,horizontal), fixed = y1; low = x1; high = x2;
    else, fixed = x1; low = y1; high = y2;
    end
    coordinate = unique(fixed(indices));
    for value = coordinate(:).'
        group = indices(fixed(indices)==value);
        [~,order] = sort(low(group)); group = group(order);
        for local = 1:numel(group)-1
            candidate = group(local+1:end);
            candidate = candidate(low(candidate)<high(group(local)) & ...
                line(candidate)~=line(group(local)));
            overlaps = overlaps+numel(candidate);
        end
    end
end
end

function bundles = collect_bundle_metrics(paths)
block = strings(0,1); side = strings(0,1); common = false(0,1);
equalBends = false(0,1); bendA = zeros(0,1); bendB = zeros(0,1); bendC = zeros(0,1);
for k = 1:numel(paths)
    portHandles = get_param(paths{k},'PortHandles');
    lineHandles = get_param(paths{k},'LineHandles');
    fields = ["LConn","RConn"];
    for field = fields
        if ~isfield(portHandles,field) || numel(portHandles.(field))~=3, continue; end
        handles = lineHandles.(field);
        if numel(handles)~=3 || any(handles==-1), continue; end
        signatures = strings(3,1); bends = zeros(3,1);
        readable = true;
        for p = 1:3
            try
                points = remove_consecutive_duplicates(double(get_param(handles(p),'Points')));
                [signatures(p),bends(p)] = turn_signature(points);
            catch
                readable = false;
            end
        end
        if ~readable, continue; end
        block(end+1,1) = string(get_param(paths{k},'Name')); %#ok<AGROW>
        side(end+1,1) = field; %#ok<AGROW>
        common(end+1,1) = isscalar(unique(signatures)); %#ok<AGROW>
        equalBends(end+1,1) = isscalar(unique(bends)); %#ok<AGROW>
        bendA(end+1,1)=bends(1); bendB(end+1,1)=bends(2); bendC(end+1,1)=bends(3); %#ok<AGROW>
    end
end
bundles = table(block,side,common,equalBends,bendA,bendB,bendC, ...
    'VariableNames',{'Block','Side','CommonTurnSignature','EqualBendCount', ...
    'BendA','BendB','BendC'});
end

function [signature,bends] = turn_signature(points)
delta = diff(points,1,1);
code = strings(size(delta,1),1);
for k = 1:size(delta,1)
    if delta(k,2)==0 && delta(k,1)>0, code(k)="R";
    elseif delta(k,2)==0 && delta(k,1)<0, code(k)="L";
    elseif delta(k,1)==0 && delta(k,2)>0, code(k)="D";
    elseif delta(k,1)==0 && delta(k,2)<0, code(k)="U";
    else, code(k)="X";
    end
end
signature = join(code,"");
bends = max(0,numel(code)-1);
end

function [difference,summary,sharedCount] = compare_blocks(reference,candidate)
[shared,referenceIndex,candidateIndex] = intersect(reference.Name,candidate.Name,'stable');
sharedCount = numel(shared);
r = reference(referenceIndex,:); c = candidate(candidateIndex,:);
moved = any([r.Left r.Top r.Right r.Bottom] ~= [c.Left c.Top c.Right c.Bottom],2);
rotated = r.Orientation ~= c.Orientation;
resized = r.Width ~= c.Width | r.Height ~= c.Height;
namePlacementChanged = r.NamePlacement ~= c.NamePlacement;
centerShift = hypot((r.Left+r.Right-c.Left-c.Right)/2, ...
    (r.Top+r.Bottom-c.Top-c.Bottom)/2);
keep = moved | rotated | resized | namePlacementChanged;
difference = table(shared,r.Category,[r.Left r.Top r.Right r.Bottom], ...
    [c.Left c.Top c.Right c.Bottom],r.Orientation,c.Orientation,moved,rotated, ...
    resized,namePlacementChanged,centerShift, ...
    'VariableNames',{'Name','Category','ReferencePosition','CandidatePosition', ...
    'ReferenceOrientation','CandidateOrientation','Moved','Rotated','Resized', ...
    'NamePlacementChanged','CenterShift'});
difference = difference(keep,:);

categories = unique([r.Category;c.Category],'stable');
category = strings(0,1); compared = zeros(0,1); movedCount = zeros(0,1);
rotatedCount = zeros(0,1); resizedCount = zeros(0,1); medianShift = zeros(0,1);
for value = categories(:).'
    mask = r.Category==value;
    category(end+1,1)=value; %#ok<AGROW>
    compared(end+1,1)=nnz(mask); %#ok<AGROW>
    movedCount(end+1,1)=nnz(moved(mask)); %#ok<AGROW>
    rotatedCount(end+1,1)=nnz(rotated(mask)); %#ok<AGROW>
    resizedCount(end+1,1)=nnz(resized(mask)); %#ok<AGROW>
    if any(mask), medianShift(end+1,1)=median(centerShift(mask)); %#ok<AGROW>
    else, medianShift(end+1,1)=NaN; %#ok<AGROW>
    end
end
summary = table(category,compared,movedCount,rotatedCount,resizedCount,medianShift, ...
    'VariableNames',{'Category','Compared','Moved','Rotated','Resized','MedianCenterShift'});
end

function value = block_category(name)
if startsWith(name,"Bus"), value="Bus";
elseif startsWith(name,"TL_"), value="Line";
elseif startsWith(name,"Load_"), value="Load";
elseif startsWith(name,"CapBank_"), value="Capacitor";
elseif startsWith(name,"Regulator_"), value="Regulator";
elseif contains(name,"Source"), value="Source";
elseif startsWith(name,"Internal_"), value="InternalBus";
else, value="Other";
end
end

function points = remove_consecutive_duplicates(points)
if size(points,1)<2, return; end
points = points([true;any(diff(points,1,1)~=0,2)],:);
end

function tf = segment_crosses_interior(a,b,position)
left=position(1)+1; top=position(2)+1; right=position(3)-1; bottom=position(4)-1;
if a(2)==b(2)
    tf = a(2)>top && a(2)<bottom && ...
        max(min(a(1),b(1)),left)<min(max(a(1),b(1)),right);
elseif a(1)==b(1)
    tf = a(1)>left && a(1)<right && ...
        max(min(a(2),b(2)),top)<min(max(a(2),b(2)),bottom);
else
    tf = false;
end
end

function improvement = improvement_percent(reference,candidate)
fields = ["totalManhattanLength","bendCount","lineBlockCrossingCount", ...
    "orthogonalLineCrossingCount","collinearLineOverlapCount", ...
    "bundleSignatureMismatchCount","canvasArea"];
improvement = struct;
for field = fields
    baseline = candidate.(field);
    if baseline==0, value = NaN;
    else, value = 100*(baseline-reference.(field))/baseline;
    end
    improvement.(field+"Percent") = value;
end
end

function tf = same_file(a,b)
tf = strcmpi(char(java.io.File(char(a)).getCanonicalPath), ...
    char(java.io.File(char(b)).getCanonicalPath));
end

function close_if_owned(modelName,wasLoaded)
if ~wasLoaded && bdIsLoaded(modelName), close_system(modelName,0); end
end

function write_json(fileName,value)
fileId = fopen(fileName,'w');
assert(fileId~=-1,'Routing:WriteFailed','Cannot write %s.',fileName);
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId,'%s',jsonencode(value,'PrettyPrint',true));
end

function print_metrics(metrics)
fields = fieldnames(metrics);
for k = 1:numel(fields)
    fprintf('%-34s %g\n',fields{k},metrics.(fields{k}));
end
end
