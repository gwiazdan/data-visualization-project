%% Wczytanie i przygotowanie danych
data = readtable('przestepstwa_long.csv', ReadVariableNames=true, TreatAsEmpty={'NA', ''});
close all;

% Upewnij sie, ze typy sa poprawne po imporcie.
if ~isstring(data.Nazwa)
	data.Nazwa = string(data.Nazwa);
end
if ~isstring(data.Kategoria)
	data.Kategoria = string(data.Kategoria);
end
if ~isstring(data.Jednostka)
	data.Jednostka = string(data.Jednostka);
end
if ~isnumeric(data.Rok)
	data.Rok = str2double(string(data.Rok));
end
if ~isnumeric(data.Value)
	data.Value = str2double(string(data.Value));
end

% Pracujemy na wartosciach liczbowych (Jednostka = "-").
isCount = data.Jednostka == "-";
dataCount = data(isCount & ~isnan(data.Value) & ~isnan(data.Rok), :);

selectedCats = [
	"ogółem"
	"o charakterze kryminalnym"
	"o charakterze gospodarczym"
	"przeciwko mieniu"
	"przeciwko życiu i zdrowiu"
	"przeciwko rodzinie i opiece"
	"przeciwko wolności, " + ...
	"wolności sumienia, " + ...
	"wolności seksualnej i obyczajności razem"
	"przeciwko bezpieczeństwu powszechnemu i bezpieczeństwu w komunikacji razem"
	"przeciwko bezpieczeństwu powszechnemu i bezpieczeństwu w komunikacji - drogowe"
];

catsInData = unique(dataCount.Kategoria);
selectedCats = selectedCats(ismember(selectedCats, catsInData));

%% 1) Barplot horyzontalny 2024: srednia jednostek vs POLSKA
yearA = 2024;
maskA = dataCount.Rok == yearA & ismember(dataCount.Kategoria, selectedCats);
plotA = dataCount(maskA, :);

valuePL = NaN(numel(selectedCats), 1);

for cIdx = 1:numel(selectedCats)
	catName = selectedCats(cIdx);
	rowsCat = plotA.Kategoria == catName;
	rowsPL = rowsCat & plotA.Nazwa == "POLSKA";
	if any(rowsPL)
		valuePL(cIdx) = plotA.Value(find(rowsPL, 1, 'first'));
	end
end

validA = ~isnan(valuePL);
catsA = selectedCats(validA);
valsA = valuePL(validA);

catsA = flipud(catsA);
valsA = flipud(valsA);
catsATicks = makeTickLabels(shortCategoryLabels(catsA), 22);

f1 = figure(1);
f1.Position = [0 500 1450 760];
f1.Visible = "off";
f1.Theme = 'light';

yA = (1:numel(valsA)) * 1.45;
b1 = barh(yA, valsA, ...
	'FaceColor', [0.85 0.25 0.20], 'EdgeColor', [0.20 0.20 0.20]);
b1.BarWidth = 0.55;
ax1 = gca;
set(ax1, 'XScale', 'log');
ax1.Position = [0.40 0.12 0.56 0.81];
ax1.YTick = yA;
ax1.YTickLabel = catsATicks;
ax1.YDir = 'reverse';
ax1.TickLabelInterpreter = 'tex';
ax1.YLim = [min(yA) - 0.9, max(yA) + 0.9];

grid on;
xlabel('Liczba przestępstw (skala log)', FontWeight='bold');
ylabel('Kategoria', FontWeight='bold', Rotation=0);
set(ax1, 'YTickLabelRotation', 0);
setFigureTitle(f1, 'Liczba przestępstw wg kategorii - 2024r.', 14);

exportgraphics(f1, 'przestepstwa_1_barh_2024.png', BackgroundColor='#f0efe9');
close(f1);

%% 2) Barplot horyzontalny: POLSKA 2002 vs 2024
yearB = 2002;
yearC = 2024;

vals2002 = NaN(numel(selectedCats), 1);
vals2024 = NaN(numel(selectedCats), 1);

for cIdx = 1:numel(selectedCats)
	catName = selectedCats(cIdx);

	rowsY1 = dataCount.Nazwa == "POLSKA" & dataCount.Rok == yearB & dataCount.Kategoria == catName;
	rowsY2 = dataCount.Nazwa == "POLSKA" & dataCount.Rok == yearC & dataCount.Kategoria == catName;

	if any(rowsY1)
		vals2002(cIdx) = dataCount.Value(find(rowsY1, 1, 'first'));
	end
	if any(rowsY2)
		vals2024(cIdx) = dataCount.Value(find(rowsY2, 1, 'first'));
	end
end

validB = ~(isnan(vals2002) & isnan(vals2024));
catsB = selectedCats(validB);
valsB = [vals2002(validB), vals2024(validB)];

catsB = flipud(catsB);
valsB = flipud(valsB);
catsBTicks = makeTickLabels(shortCategoryLabels(catsB), 22);

f2 = figure(2);
f2.Position = [0 500 1450 760];
f2.Visible = "off";
f2.Theme = 'light';

yB = (1:size(valsB, 1)) * 1.45;
h2 = barh(yB, valsB, 'grouped');
for hIdx = 1:numel(h2)
	h2(hIdx).BarWidth = 0.55;
end
ax2 = gca;
set(ax2, 'XScale', 'log');
ax2.Position = [0.40 0.12 0.56 0.81];
ax2.YTick = yB;
ax2.YTickLabel = catsBTicks;
ax2.YDir = 'reverse';
ax2.TickLabelInterpreter = 'tex';
ax2.YLim = [min(yB) - 0.9, max(yB) + 0.9];
grid on;
xlabel('Liczba przestępstw (skala log)', FontWeight='bold');
ylabel('Kategoria', FontWeight='bold', Rotation=0);
set(ax2, 'YTickLabelRotation', 0);
setFigureTitle(f2, 'Porównanie liczby przestępstw wg kategorii w latach 2002 i 2024', 14);
legend({sprintf('%d', yearB), sprintf('%d', yearC)}, Location='southeast');

exportgraphics(f2, 'przestepstwa_2_barh_2002_vs_2024.png', BackgroundColor='#f0efe9');
close(f2);

%% 3) Trend ogolem (POLSKA) rok do roku - line plot
maskPL = dataCount.Nazwa == "POLSKA" & dataCount.Kategoria == "ogółem";
trendAll = sortrows(dataCount(maskPL, {'Rok', 'Value'}), 'Rok');

f3 = figure(3);
f3.Position = [0 500 1400 600];
f3.Visible = "off";
f3.Theme = 'light';

plot(trendAll.Rok, trendAll.Value, '-o', 'LineWidth', 1.8, ...
	'MarkerSize', 5, 'Color', [0.12 0.45 0.72]);
ax3 = gca;
grid on;
xlabel('Rok', FontWeight='bold');
ylabel('Liczba przestępstw ogółem', FontWeight='bold', Rotation=0);
setFigureTitle(f3, 'Zmiana liczby przestępstw ogółem rok do roku', 15);

exportgraphics(f3, 'przestepstwa_3_trend_ogolem_polska.png', BackgroundColor='#f0efe9');
close(f3);

%% 4) Stacked horyzontalny: kategorie rok do roku (POLSKA)
catsStack = selectedCats(selectedCats ~= "ogółem");
maskStack = dataCount.Nazwa == "POLSKA" & ismember(dataCount.Kategoria, catsStack);
stackData = dataCount(maskStack, {'Rok', 'Kategoria', 'Value'});

yearsStack = unique(stackData.Rok);
yearsStack = sort(yearsStack);
orderedCats = catsStack;

stackVals = zeros(numel(yearsStack), numel(orderedCats));
for yIdx = 1:numel(yearsStack)
	for cIdx = 1:numel(orderedCats)
		rowsYC = stackData.Rok == yearsStack(yIdx) & stackData.Kategoria == orderedCats(cIdx);
		stackVals(yIdx, cIdx) = sum(stackData.Value(rowsYC), 'omitnan');
	end
end

f4 = figure(4);
f4.Position = [0 500 1450 700];
f4.Visible = "off";
f4.Theme = 'light';

yearCat = categorical(string(yearsStack));
yearCat = reordercats(yearCat, string(yearsStack));

barh(yearCat, stackVals, 'stacked');
ax4 = gca;
ax4.Position = [0.10 0.12 0.58 0.80];
grid on;
xlabel('Liczba przestępstw (suma kategorii)', FontWeight='bold');
ylabel('Rok', FontWeight='bold', Rotation=0);
set(ax4, 'YTickLabelRotation', 0);
setFigureTitle(f4, 'Kategorie przestępstw rok do roku', 14);
legendLabels = padLegendLabels(wrapLabels(shortCategoryLabels(orderedCats), 24));
lgd = legend(cellstr(legendLabels), Location='eastoutside');
lgd.ItemTokenSize = [20, 20];

exportgraphics(f4, 'przestepstwa_4_stacked_horizontal_polska.png', BackgroundColor='#f0efe9');
close(f4);

%% 5) Porownanie przestrzenne 2024: wojewodztwa vs powiaty (ogolem)
targetYear = 2024;
targetCategory = "ogółem";

mapRows = dataCount(dataCount.Rok == targetYear & ...
	dataCount.Kategoria == targetCategory & ...
	dataCount.Nazwa ~= "POLSKA", {'Kod', 'Nazwa', 'Value'});

if ~isnumeric(mapRows.Kod)
	mapRows.Kod = str2double(string(mapRows.Kod));
end
mapRows = mapRows(~isnan(mapRows.Kod) & ~isnan(mapRows.Value), :);

% Normalizacja kodow z tabeli przestepstw do postaci zgodnej z JPT/TERYT.
% Przyklad: 216000 -> "0216000" -> powiat "0216", wojewodztwo "02".
mapRows.Kod7 = compose("%07.0f", mapRows.Kod);
mapRows.KodWoj2 = extractBetween(string(mapRows.Kod7), 1, 2);
mapRows.KodPow4 = extractBetween(string(mapRows.Kod7), 1, 4);
mapRows.KodPow2 = extractBetween(string(mapRows.Kod7), 3, 4);

% TERYT: woj = xx00000 (powiatowa para = "00"), pow = xxpp000 (pp != "00").
isWojRow = mapRows.KodPow2 == "00" & mapRows.Kod ~= 0;
isPowRow = mapRows.KodPow2 ~= "00" & mapRows.Kod ~= 0;

wojRows = mapRows(isWojRow, :);
powRows = mapRows(isPowRow, :);


scriptDir = fileparts(mfilename('fullpath'));
repoDir = fileparts(scriptDir);
powiatyDir = fullfile(repoDir, 'powiaty');

wojShpPath = fullfile(powiatyDir, 'A01_Granice_wojewodztw.shp');
powShpPath = fullfile(powiatyDir, 'A02_Granice_powiatow.shp');

if ~isfile(wojShpPath)
	error('Nie znaleziono pliku shapefile wojewodztw: %s', wojShpPath);
end
if ~isfile(powShpPath)
	error('Nie znaleziono pliku shapefile powiatow: %s', powShpPath);
end

wojShapes = shaperead(wojShpPath);
powShapes = shaperead(powShpPath);

% Join bezposrednio po JPT_KOD_JE (woj: 2 cyfry, pow: 4 cyfry)
wojCodes = string({wojShapes.JPT_KOD_JE})';
powCodes = string({powShapes.JPT_KOD_JE})';

[isWojMatched, idxWoj] = ismember(wojCodes, string(wojRows.KodWoj2));
[isPowMatched, idxPow] = ismember(powCodes, string(powRows.KodPow4));

wojVals = NaN(numel(wojShapes), 1);
powVals = NaN(numel(powShapes), 1);
wojVals(isWojMatched) = wojRows.Value(idxWoj(isWojMatched));
powVals(isPowMatched) = powRows.Value(idxPow(isPowMatched));

fprintf('Mapowanie wojewodztw: %d/%d\n', sum(isWojMatched), numel(wojShapes));
fprintf('Mapowanie powiatow: %d/%d\n', sum(isPowMatched), numel(powShapes));

% Logarytmiczna skala koloru poprawia czytelnosc dla szerokiego zakresu.
wojValsLog = log10(wojVals + 1);
powValsLog = log10(powVals + 1);

f5 = figure(5);
f5.Position = [0 450 1100 760];
f5.Visible = "off";
f5.Theme = 'light';

plotGeoCentroidMap(wojShapes, wojValsLog, ...
	'Województwa - przestępczość ogółem (2024)', [120 520]);
setFigureTitle(f5, 'Województwa - Przestępczość ogółem (2024)', 14);
exportgraphics(f5, 'przestepstwa_5_mapa_woj_2024.png', BackgroundColor='#f0efe9');
close(f5);

%% 6) Mapa powiatow 2024 (ogolem)
f6 = figure(6);
f6.Position = [0 450 1100 760];
f6.Visible = "off";
f6.Theme = 'light';

plotGeoPolygonMap(powShapes, powValsLog, ...
	'Powiaty - przestępczość ogółem (2024)');
setFigureTitle(f6, 'Powiaty - Przestępczość ogółem (2024)', 14);
exportgraphics(f6, 'przestepstwa_6_mapa_pow_2024.png', BackgroundColor='#f0efe9');
close(f6);

%% 7) Top 10: wojewodztwa i powiaty (ogolem, 2024)
wojTop = sortrows(wojRows(:, {'Kod', 'Nazwa', 'Value'}), 'Value', 'descend');
powTop = sortrows(powRows(:, {'Kod', 'Nazwa', 'Value'}), 'Value', 'descend');

topN = 10;
wojTop = wojTop(1:min(topN, height(wojTop)), :);
powTop = powTop(1:min(topN, height(powTop)), :);

f7 = figure(7);
f7.Position = [0 450 1700 760];
f7.Visible = "off";
f7.Theme = 'light';

tl6 = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
setFigureTitle(f7, 'Top 10 jednostek wg przestępczości ogółem (2024)', 15);

nexttile;
barh(categorical(flipud(string(wojTop.Nazwa))), flipud(wojTop.Value), ...
	'FaceColor', [0.20 0.55 0.80], 'EdgeColor', [0.20 0.20 0.20]);
grid on;
xlabel('Liczba przestępstw');
ylabel('Województwo', Rotation=0, FontWeight='bold');
title('Województwa');

nexttile;
barh(categorical(flipud(string(powTop.Nazwa))), flipud(powTop.Value), ...
	'FaceColor', [0.88 0.42 0.18], 'EdgeColor', [0.20 0.20 0.20]);
grid on;
xlabel('Liczba przestępstw');
ylabel('Powiat', Rotation=0, FontWeight='bold');
title('Powiaty');

exportgraphics(f7, 'przestepstwa_7_top10_woj_pow_2024.png', BackgroundColor='#f0efe9');
close(f7);

%% 8) Kartogramy wachniec wzgledem 2002: wojewodztwa i powiaty (ogolem)
baseYear = 2002;
compareYear = 2024;

cmpRows = dataCount(ismember(dataCount.Rok, [baseYear, compareYear]) & ...
	dataCount.Kategoria == targetCategory & ...
	dataCount.Nazwa ~= "POLSKA", {'Kod', 'Nazwa', 'Rok', 'Value'});

if ~isnumeric(cmpRows.Kod)
	cmpRows.Kod = str2double(string(cmpRows.Kod));
end
cmpRows = cmpRows(~isnan(cmpRows.Kod) & ~isnan(cmpRows.Value), :);

cmpRows.Kod7 = compose("%07.0f", cmpRows.Kod);
cmpRows.KodWoj2 = extractBetween(string(cmpRows.Kod7), 1, 2);
cmpRows.KodPow4 = extractBetween(string(cmpRows.Kod7), 1, 4);
cmpRows.KodPow2 = extractBetween(string(cmpRows.Kod7), 3, 4);

isWojCmp = cmpRows.KodPow2 == "00" & cmpRows.Kod ~= 0;
isPowCmp = cmpRows.KodPow2 ~= "00" & cmpRows.Kod ~= 0;

wojCmpRows = cmpRows(isWojCmp, :);
powCmpRows = cmpRows(isPowCmp, :);

% Powiaty: fallback bazowego roku, bo w danych brak 2002.
powAllRows = dataCount(dataCount.Kategoria == targetCategory & ...
	dataCount.Nazwa ~= "POLSKA", {'Kod', 'Nazwa', 'Rok', 'Value'});
if ~isnumeric(powAllRows.Kod)
	powAllRows.Kod = str2double(string(powAllRows.Kod));
end
powAllRows = powAllRows(~isnan(powAllRows.Kod) & ~isnan(powAllRows.Value), :);
powAllRows.Kod7 = compose("%07.0f", powAllRows.Kod);
powAllRows.KodPow4 = extractBetween(string(powAllRows.Kod7), 1, 4);
powAllRows.KodPow2 = extractBetween(string(powAllRows.Kod7), 3, 4);
powAllRows = powAllRows(powAllRows.KodPow2 ~= "00" & powAllRows.Kod ~= 0, :);

if any(powAllRows.Rok == baseYear)
	powBaseYear = baseYear;
else
	powBaseYear = min(powAllRows.Rok);
	fprintf('Brak danych powiatow dla %d. Uzywam roku bazowego %d.\n', baseYear, powBaseYear);
end

wojCmpCodes = unique(string(wojCmpRows.KodWoj2));
powCmpCodes = unique(string(powCmpRows.KodPow4));

wojNamesCmp = strings(numel(wojCmpCodes), 1);
woj2002 = NaN(numel(wojCmpCodes), 1);
woj2024 = NaN(numel(wojCmpCodes), 1);

for i = 1:numel(wojCmpCodes)
	codeNow = wojCmpCodes(i);
	rowsCode = string(wojCmpRows.KodWoj2) == codeNow;
	rows2002 = rowsCode & wojCmpRows.Rok == baseYear;
	rows2024 = rowsCode & wojCmpRows.Rok == compareYear;

	if any(rows2024)
		wojNamesCmp(i) = string(wojCmpRows.Nazwa(find(rows2024, 1, 'first')));
	elseif any(rows2002)
		wojNamesCmp(i) = string(wojCmpRows.Nazwa(find(rows2002, 1, 'first')));
	else
		wojNamesCmp(i) = codeNow;
	end

	if any(rows2002)
		woj2002(i) = sum(wojCmpRows.Value(rows2002), 'omitnan');
	end
	if any(rows2024)
		woj2024(i) = sum(wojCmpRows.Value(rows2024), 'omitnan');
	end
end

powNamesCmp = strings(numel(powCmpCodes), 1);
powBaseVals = NaN(numel(powCmpCodes), 1);
pow2024 = NaN(numel(powCmpCodes), 1);

for i = 1:numel(powCmpCodes)
	codeNow = powCmpCodes(i);
	rowsCode = string(powAllRows.KodPow4) == codeNow;
	rowsBase = rowsCode & powAllRows.Rok == powBaseYear;
	rows2024 = rowsCode & powAllRows.Rok == compareYear;

	if any(rows2024)
		powNamesCmp(i) = string(powAllRows.Nazwa(find(rows2024, 1, 'first')));
	elseif any(rowsBase)
		powNamesCmp(i) = string(powAllRows.Nazwa(find(rowsBase, 1, 'first')));
	else
		powNamesCmp(i) = codeNow;
	end

	if any(rowsBase)
		powBaseVals(i) = sum(powAllRows.Value(rowsBase), 'omitnan');
	end
	if any(rows2024)
		pow2024(i) = sum(powAllRows.Value(rows2024), 'omitnan');
	end
end

validWojCmp = ~isnan(woj2002) & ~isnan(woj2024);
validPowCmp = ~isnan(powBaseVals) & ~isnan(pow2024);

wojChange = table(wojCmpCodes(validWojCmp), wojNamesCmp(validWojCmp), ...
	woj2002(validWojCmp), woj2024(validWojCmp), ...
	'VariableNames', {'Kod', 'Nazwa', 'Value2002', 'Value2024'});
wojChange.Delta = wojChange.Value2024 - wojChange.Value2002;
wojChange.AbsDelta = abs(wojChange.Delta);

powChange = table(powCmpCodes(validPowCmp), powNamesCmp(validPowCmp), ...
	powBaseVals(validPowCmp), pow2024(validPowCmp), ...
	'VariableNames', {'Kod', 'Nazwa', 'ValueBase', 'Value2024'});
powChange.Delta = powChange.Value2024 - powChange.ValueBase;
powChange.AbsDelta = abs(powChange.Delta);

[isWojSwingMatched, idxWojSwing] = ismember(wojCodes, wojChange.Kod);
[isPowSwingMatched, idxPowSwing] = ismember(powCodes, powChange.Kod);

wojSwingVals = NaN(numel(wojShapes), 1);
powSwingVals = NaN(numel(powShapes), 1);
wojSwingVals(isWojSwingMatched) = wojChange.Delta(idxWojSwing(isWojSwingMatched));
powSwingVals(isPowSwingMatched) = powChange.Delta(idxPowSwing(isPowSwingMatched));

wojSwingSignedLog = sign(wojSwingVals) .* log10(abs(wojSwingVals) + 1);
powSwingSignedLog = sign(powSwingVals) .* log10(abs(powSwingVals) + 1);

f8 = figure(8);
f8.Position = [0 450 1100 760];
f8.Visible = "off";
f8.Theme = 'light';

plotGeoPolygonMapSigned(wojShapes, wojSwingSignedLog, 'Województwa');
setFigureTitle(f8, 'Zmiana względem 2002 (województwa): wzrost/spadek', 14);
exportgraphics(f8, 'przestepstwa_8_mapa_woj_wachniecie_vs_2002.png', BackgroundColor='#f0efe9');
close(f8);

f9 = figure(9);
f9.Position = [0 450 1100 760];
f9.Visible = "off";
f9.Theme = 'light';

plotGeoPolygonMapSigned(powShapes, powSwingSignedLog, 'Powiaty');
setFigureTitle(f9, sprintf('Zmiana względem %d (powiaty): wzrost/spadek', powBaseYear), 14);
exportgraphics(f9, 'przestepstwa_9_mapa_pow_wachniecie_vs_2002.png', BackgroundColor='#f0efe9');
close(f9);

%% 9) Top 10 najwiekszych wachniec: porownanie 2002 vs 2024
wojTopSwing = sortrows(wojChange, 'AbsDelta', 'descend');
powTopSwing = sortrows(powChange, 'AbsDelta', 'descend');

topNChange = 10;
wojTopSwing = wojTopSwing(1:min(topNChange, height(wojTopSwing)), :);
powTopSwing = powTopSwing(1:min(topNChange, height(powTopSwing)), :);

f10 = figure(10);
f10.Position = [0 450 1750 780];
f10.Visible = "off";
f10.Theme = 'light';

t10 = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
setFigureTitle(f10, sprintf('Top 10 największych zmian: woj %d->2024, pow %d->2024', baseYear, powBaseYear), 14);

nexttile;
wojDeltaTop = flipud(wojTopSwing.Delta);
barW = barh(categorical(flipud(string(wojTopSwing.Nazwa))), wojDeltaTop, 'FaceColor', 'flat', 'EdgeColor', [0.20 0.20 0.20]);
barW.CData = repmat([0.88 0.42 0.18], numel(wojDeltaTop), 1);
barW.CData(wojDeltaTop < 0, :) = repmat([0.20 0.55 0.80], sum(wojDeltaTop < 0), 1);
xline(0, '-', 'Color', [0.30 0.30 0.30], 'LineWidth', 1.2);
grid on;
xlabel(sprintf('Zmiana liczby przestępstw (2024 - %d)', baseYear));
ylabel('Województwo', Rotation=0, FontWeight='bold');
title('Województwa (wzrost +, spadek -)');

nexttile;
powDeltaTop = flipud(powTopSwing.Delta);
barP = barh(categorical(flipud(string(powTopSwing.Nazwa))), powDeltaTop, 'FaceColor', 'flat', 'EdgeColor', [0.20 0.20 0.20]);
barP.CData = repmat([0.88 0.42 0.18], numel(powDeltaTop), 1);
barP.CData(powDeltaTop < 0, :) = repmat([0.20 0.55 0.80], sum(powDeltaTop < 0), 1);
xline(0, '-', 'Color', [0.30 0.30 0.30], 'LineWidth', 1.2);
grid on;
xlabel(sprintf('Zmiana liczby przestępstw (2024 - %d)', powBaseYear));
ylabel('Powiat', Rotation=0, FontWeight='bold');
title('Powiaty (wzrost +, spadek -)');

exportgraphics(f10, 'przestepstwa_10_top10_wachniecia_vs_2002.png', BackgroundColor='#f0efe9');
close(f10);

function wrapped = wrapLabels(labels, maxLen)
wrapped = strings(size(labels));
for i = 1:numel(labels)
	parts = split(string(labels(i)), " ");
	line = "";
	out = "";
	for p = 1:numel(parts)
		candidate = strtrim(line + " " + parts(p));
		if strlength(candidate) > maxLen && strlength(line) > 0
			if strlength(out) == 0
				out = line;
			else
				out = out + newline + line;
			end
			line = parts(p);
		else
			line = candidate;
		end
	end
	if strlength(out) == 0
		wrapped(i) = line;
	else
		wrapped(i) = out + newline + line;
	end
end
end

function padded = padLegendLabels(labels)
padded = labels;
for i = 1:numel(labels)
	padded(i) = labels(i) + newline;
end
end

function tickLabels = makeTickLabels(labels, maxLen)
wrapped = wrapLabels(labels, maxLen);
tickLabels = cell(size(wrapped));
for i = 1:numel(wrapped)
	tickLabels{i} = strrep(char(wrapped(i)), newline, '\newline');
end
end

function shortLabels = shortCategoryLabels(labels)
shortLabels = labels;
for i = 1:numel(labels)
	s = string(labels(i));
	s = replace(s, "przeciwko bezpieczeństwu powszechnemu i bezpieczeństwu w komunikacji - drogowe", ...
		"bezpieczenstwo i komunikacja - drogowe");
	s = replace(s, "przeciwko bezpieczeństwu powszechnemu i bezpieczeństwu w komunikacji razem", ...
		"bezpieczenstwo i komunikacja - razem");
	s = replace(s, "przeciwko wolności, wolności sumienia, wolności seksualnej i obyczajności razem", ...
		"przeciwko wolnosci i obyczajnosci");
	s = replace(s, "o charakterze kryminalnym", "charakter kryminalny");
	s = replace(s, "o charakterze gospodarczym", "charakter gospodarczy");
	shortLabels(i) = s;
end
end

function plotGeoCentroidMap(S, vals, ttl, ~)
% Zachowana dla kompatybilnosci wywolan historycznych.
plotGeoPolygonMap(S, vals, ttl);
end

function plotGeoPolygonMap(S, vals, ttl)
% Wyznacz limity bezposrednio z danych i dodaj minimalny margines.
allX = [];
allY = [];
for i = 1:numel(S)
	x = S(i).X;
	y = S(i).Y;
	mask = ~isnan(x) & ~isnan(y);
	allX = [allX, x(mask)]; %#ok<AGROW>
	allY = [allY, y(mask)]; %#ok<AGROW>
end

if isempty(allX) || isempty(allY)
	latLim = [47.5 56.5];
	lonLim = [13.0 26.5];
else
	latMin = min(allY);
	latMax = max(allY);
	lonMin = min(allX);
	lonMax = max(allX);
	latPad = max(0.10, 0.02 * (latMax - latMin));
	lonPad = max(0.10, 0.02 * (lonMax - lonMin));
	latLim = [latMin - latPad, latMax + latPad];
	lonLim = [lonMin - lonPad, lonMax + lonPad];
end

ax = axesm('mercator', ...
	'MapLatLimit', latLim, ...
	'MapLonLimit', lonLim, ...
	'Frame', 'on', 'Grid', 'off', ...
	'MLineLocation', 2, 'PLineLocation', 1, ...
	'MeridianLabel', 'off', 'ParallelLabel', 'off');
setm(ax, 'FontSize', 9);
xlabel(ax, '');
ylabel(ax, '');

% Tlo Europy dla kontekstu mapowego.
try
	set(ax, 'Color', [0.91 0.94 0.97]);
	land = shaperead('landareas', 'UseGeoCoords', true);
	geoshow(ax, land, 'FaceColor', [0.96 0.97 0.98], 'EdgeColor', [0.85 0.87 0.90], 'LineWidth', 0.4);
	try
		lakes = shaperead('worldlakes', 'UseGeoCoords', true);
		geoshow(ax, lakes, 'FaceColor', [0.88 0.92 0.96], 'EdgeColor', 'none');
	catch
	end
catch
	% Fallback: brak warstwy ladowej - zostaw czyste tlo.
end

hold on;
valid = ~isnan(vals);
if any(valid)
	vMin = min(vals(valid));
	vMax = max(vals(valid));
else
	vMin = 0;
	vMax = 1;
end

cmap = createSunset3Colormap(256);

for i = 1:numel(S)
	x = S(i).X;
	y = S(i).Y;
	if isempty(x) || isempty(y)
		continue;
	end

	if isnan(vals(i))
		faceColor = [0.86 0.86 0.86];
	else
		t = (vals(i) - vMin) / max(vMax - vMin, eps);
		idx = max(1, min(256, 1 + round(t * 255)));
		faceColor = cmap(idx, :);
	end

	geoshow(ax, y, x, ...
		'DisplayType', 'polygon', ...
		'FaceColor', faceColor, ...
		'EdgeColor', [230 230 230] / 255, ...
		'LineWidth', 0.30);
end

colormap(ax, cmap);
caxis(ax, [vMin vMax]);
cb = colorbar(ax);
cb.Label.String = 'log10(liczba + 1)';
hold off;
end

function plotGeoPolygonMapSigned(S, vals, ttl)
% Wyznacz limity bezposrednio z danych i dodaj minimalny margines.
allX = [];
allY = [];
for i = 1:numel(S)
	x = S(i).X;
	y = S(i).Y;
	mask = ~isnan(x) & ~isnan(y);
	allX = [allX, x(mask)]; %#ok<AGROW>
	allY = [allY, y(mask)]; %#ok<AGROW>
end

if isempty(allX) || isempty(allY)
	latLim = [47.5 56.5];
	lonLim = [13.0 26.5];
else
	latMin = min(allY);
	latMax = max(allY);
	lonMin = min(allX);
	lonMax = max(allX);
	latPad = max(0.10, 0.02 * (latMax - latMin));
	lonPad = max(0.10, 0.02 * (lonMax - lonMin));
	latLim = [latMin - latPad, latMax + latPad];
	lonLim = [lonMin - lonPad, lonMax + lonPad];
end

ax = axesm('mercator', ...
	'MapLatLimit', latLim, ...
	'MapLonLimit', lonLim, ...
	'Frame', 'on', 'Grid', 'off', ...
	'MLineLocation', 2, 'PLineLocation', 1, ...
	'MeridianLabel', 'off', 'ParallelLabel', 'off');
setm(ax, 'FontSize', 9);
xlabel(ax, '');
ylabel(ax, '');

% Tlo Europy dla kontekstu mapowego.
try
	set(ax, 'Color', [0.91 0.94 0.97]);
	land = shaperead('landareas', 'UseGeoCoords', true);
	geoshow(ax, land, 'FaceColor', [0.96 0.97 0.98], 'EdgeColor', [0.85 0.87 0.90], 'LineWidth', 0.4);
	try
		lakes = shaperead('worldlakes', 'UseGeoCoords', true);
		geoshow(ax, lakes, 'FaceColor', [0.88 0.92 0.96], 'EdgeColor', 'none');
	catch
	end
catch
	% Fallback: brak warstwy ladowej - zostaw czyste tlo.
end

valid = ~isnan(vals);
if any(valid)
	vAbs = max(abs(vals(valid)));
else
	vAbs = 1;
end

cmap = createDivergingChangeColormap(256);
hold on;
for i = 1:numel(S)
	x = S(i).X;
	y = S(i).Y;
	if isempty(x) || isempty(y)
		continue;
	end

	if isnan(vals(i))
		faceColor = [0.86 0.86 0.86];
	else
		t = (vals(i) + vAbs) / max(2 * vAbs, eps);
		idx = max(1, min(256, 1 + round(t * 255)));
		faceColor = cmap(idx, :);
	end

	geoshow(ax, y, x, ...
		'DisplayType', 'polygon', ...
		'FaceColor', faceColor, ...
		'EdgeColor', [230 230 230] / 255, ...
		'LineWidth', 0.30);
end

colormap(ax, cmap);
caxis(ax, [-vAbs vAbs]);
cb = colorbar(ax);
cb.Label.String = 'znak(delta) * log10(|delta| + 1)';
hold off;
end

function setFigureTitle(figH, ttl, fontSize)
if nargin < 3
	fontSize = 14;
end

oldTitles = findall(figH, 'Type', 'textboxshape', 'Tag', 'FigureTitleBox');
if ~isempty(oldTitles)
	delete(oldTitles);
end

annotation(figH, 'textbox', [0.02 0.952 0.96 0.045], ...
	'String', char(ttl), ...
	'HorizontalAlignment', 'center', ...
	'VerticalAlignment', 'middle', ...
	'LineStyle', 'none', ...
	'FontWeight', 'bold', ...
	'FontSize', fontSize, ...
	'Interpreter', 'none', ...
	'Tag', 'FigureTitleBox');
end

function cmap = createSunset3Colormap(n)
if nargin < 1
	n = 256;
end

hexColors = [
	"#FCFCBD"
	"#FED69A"
	"#FDC48C"
	"#FB9A70"
	"#C74370"
	"#9D2D7A"
	"#86277A"
	"#661d5c"
	"#5A1A74"
];

base = zeros(numel(hexColors), 3);
for i = 1:numel(hexColors)
	base(i, :) = hexToRgb(hexColors(i));
end

xBase = linspace(0, 1, size(base, 1));
x = linspace(0, 1, n);
cmap = interp1(xBase, base, x, 'linear');
end

function cmap = createDivergingChangeColormap(n)
if nargin < 1
	n = 256;
end

left = [
	[0.20 0.55 0.80]
	[0.74 0.86 0.95]
];
right = [
	[0.98 0.83 0.70]
	[0.88 0.42 0.18]
];
mid = [0.97 0.97 0.97];

halfN = floor(n / 2);
xL = linspace(0, 1, size(left, 1));
xR = linspace(0, 1, size(right, 1));

leftPart = interp1(xL, left, linspace(0, 1, halfN), 'linear');
rightPart = interp1(xR, right, linspace(0, 1, n - halfN), 'linear');

if n >= 3
	leftPart(end, :) = mid;
	rightPart(1, :) = mid;
end

cmap = [leftPart; rightPart];
end

function rgb = hexToRgb(hex)
h = char(hex);
if startsWith(h, '#')
	h = h(2:end);
end
rgb = [hex2dec(h(1:2)), hex2dec(h(3:4)), hex2dec(h(5:6))] / 255;
end