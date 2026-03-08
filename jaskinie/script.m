%% Wczytanie danych z pliku Shapefile
filename = 'jaskinie/data/cbdg_srodowisko_jaskinie_2026_03_06.shp';
jaskinie = shaperead(filename);

% Wyciągnięcie odpowiednich danych do tablic
dlugosc = [jaskinie.DLUGOSC];
glebokosc = [jaskinie.GLEBOKOSC];
przewyzsze = [jaskinie.PRZEWYZSZE];
deniwelacja = [jaskinie.DENIWELACJ];
osuwiskowa = [jaskinie.OSUWISKOWA];
nazwy = {jaskinie.NAZWA};
regiony = {jaskinie.REGION};
wlasciciel = {jaskinie.WLASCICIEL};

liczba_jaskin = length(jaskinie);

%% WIZUALIZACJA 1: Rozkład długości jaskiń (histogram dla jaskiń do 100m)
figure(1);
dlugosc_filtr = dlugosc(dlugosc > 0 & dlugosc <= 100); 
histogram(dlugosc_filtr, 'BinWidth', 5);
title('1. Częstotliwość występowania jaskiń o danej długości (do 100 m)');
xlabel('Długość jaskini (m)');
ylabel('Ilość jaskiń');
grid on;

%% WIZUALIZACJA 2: Wykres słupkowy dla 10 najdłuższych jaskiń
figure(2);
[posortowane_dlugosci, indeksy_dl] = sort(dlugosc, 'descend');
top10_dlugosci = posortowane_dlugosci(1:10) ./ 1000;
top10_nazwy_dl = nazwy(indeksy_dl(1:10));

bar(top10_dlugosci);
set(gca, 'XTickLabel', top10_nazwy_dl);
title('2. 10 najdłuższych jaskiń w Polsce');
xlabel('Nazwa jaskini');
ylabel('Długość (km)');
grid on;

%% WIZUALIZACJA 3: Rozkład głębokości jaskiń
figure(3);
glebokosc_filtr = glebokosc(glebokosc > 0 & glebokosc <= 50);
histogram(glebokosc_filtr, 'BinWidth', 2, 'FaceColor', [0.4660 0.6740 0.1880]);
title('3. Rozkład głębokości jaskiń (do 50 m)');
xticks(0:2:50);
xlabel('Głębokość jaskini (m)');
ylabel('Liczba jaskiń');
grid on;

%% WIZUALIZACJA 4: Wykres słupkowy dla 10 najgłębszych jaskiń
figure(4);
[posortowane_glebokosci, indeksy_gl] = sort(glebokosc, 'descend');
top10_glebokosci = posortowane_glebokosci(1:10);
top10_nazwy_gl = nazwy(indeksy_gl(1:10));

bar(top10_glebokosci, 'FaceColor', [0.9290 0.6940 0.1250]);
set(gca, 'XTickLabel', top10_nazwy_gl);
title('4. 10 najgłębszych jaskiń w Polsce');
xlabel('Nazwa jaskini');
ylabel('Głębokość (m)');
grid on;

%% WIZUALIZACJA 5: Rozkład przewyższa jaskiń
figure(5);
przewyzsze_filtr = przewyzsze(przewyzsze > 0 & przewyzsze <= 100);
histogram(przewyzsze_filtr, 'BinWidth', 4, 'FaceColor', [0.4660 0.5540 0.1880]);
title('5. Rozkład przewyższa jaskiń (do 100 m)');
xticks(0:4:100);
xlabel('Przewyższe jaskini (m)');
ylabel('Liczba jaskiń');
grid on;

%% WIZUALIZACJA 6: Wykres słupkowy dla 10 jaskiń z największym przewyższem
figure(6);
[posortowane_przewyzsze, indeksy_prz] = sort(przewyzsze, 'descend');
top10_przewyzsze = posortowane_przewyzsze(1:10);
top10_nazwy_prz = nazwy(indeksy_prz(1:10));

bar(top10_przewyzsze, 'FaceColor', [0.9290 0.6940 0.1250]);
set(gca, 'XTickLabel', top10_nazwy_prz);
title('6. 10 jaskiń z największym przewyższem');
xlabel('Nazwa jaskini');
ylabel('Przewyższe (m)');
grid on;

%% WIZUALIZACJA 7: Zależność głębokości od długości (Wykres punktowy / Scatter)
figure(7);
idx_valid = (dlugosc <= 100 & glebokosc <= 50);
scatter(dlugosc(idx_valid), glebokosc(idx_valid), 15, 'filled', 'MarkerFaceColor', [0.4940 0.1840 0.5560]);
title('7. Zależność między długością a głębokością jaskini');
xlabel('Długość (m)');
ylabel('Głębokość (m)');
grid on;

%% WIZUALIZACJA 8: Udział rejonów w liczbie jaskiń
figure(8);
kategorie_regionow = categorical(regiony);
colororder('glow12')
piechart(kategorie_regionow);
title('8. Udział rejonów w Polsce');

%% WIZUALIZACJA 9: Proporcja jaskiń osuwiskowych do krasowych
figure(9);
liczba_osuwiskowych = sum(osuwiskowa == 1);
liczba_innych = sum(osuwiskowa == 0);

piechart([liczba_osuwiskowych, liczba_innych], {'Osuwiskowe', 'Pozostałe (Krasowe itp.)'});
title('9. Udział jaskiń osuwiskowych w Polsce');

%% WIZUALIZACJA 10: Udział właścicieli
figure(10);
kategorie_wlasciciel = categorical(wlasciciel);
wlasciciel_count = countcats(kategorie_wlasciciel);

kategorie = categories(kategorie_wlasciciel);
kategorie_sort = sort(kategorie);

piechart(wlasciciel_count, kategorie_sort);

%% WIZUALIZACJA 11: Mapa rozmieszczenia jaskiń w Polsce
figure(11);

x = [jaskinie.X];
y = [jaskinie.Y];

x(isnan(x)) = [];
y(isnan(y)) = [];

proj = projcrs(2180);
[lat, lon] = projinv(proj, x, y);

geoscatter(lat, lon, 15, 'MarkerEdgeColor', 'black', 'MarkerFaceColor', [0.8500 0.3250 0.0980]);

geobasemap('streets-light'); 

title('8. Rozmieszczenie jaskiń w Polsce');