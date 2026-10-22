-- =====================================================================
-- POC FSCC-12901 v2 (multipais, FACO) - 03 Dia PRD 3 (DESARROLLO)
-- 1) Carga las 486 filas REALES del archivo PRD 3.xlsx (28-08-2026, 27 locales,
--    357 cajas, cierre Y 1) en VTA_FACOPOC_PRD3. Los sobres se insertan en 04.
-- 2) Crea, para cada caja del archivo, el cierre Y abierto y su libro de ventas
--    (VTA_FACOLIBVTA + VTA_FACOZZZ) copiando una fila real de TEST como molde
--    (por eso va DESPUES de 02_datos_test.sql). El efectivo declarado se
--    calcula para que, con los sobres reales, la DR quede en el valor del
--    escenario. Cheques, tarjetas y Sodimac en 0.
-- 3) Agrega cajas SIN sobres en cada local (P6 / P7) y conceptos pendientes (P5).
-- Escenarios y resultados esperados: ver 00_LEEME.
-- GRABA (todo con fecha 28-08-2026; techkey 990000000+). Lo revierte 99.
-- =====================================================================

-- ---------------------------------------------------------------
-- 1. Archivo PRD 3.xlsx: local; terminal; sobre; monto; dif; recuento; fecha; Y
-- ---------------------------------------------------------------
insert into VTA_FACOPOC_PRD3 values (6, 4, 6571295616, 2450000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 9, 2504295617, 300000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 17, 2449295618, 1000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 20, 9833295619, 2344000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 24, 6608295620, 2342000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 26, 4472295621, 986000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 27, 3404295622, 846000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 27, 3476295623, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 27, 3482295624, 2737000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 29, 3007295625, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 29, 3110295626, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 29, 3111295627, 344000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 31, 5998295628, 2670000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 40, 1354295629, 1934000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 40, 1421295630, 3922000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (6, 44, 6925295631, 875000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 5, 4598295531, 1059000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 6, 8074295532, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 6, 8079295533, 2455000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 6, 8116295534, 934000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 11, 8388295535, 2029000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 19, 3959295536, 3135000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 21, 1528295537, 1670000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 28, 8195295538, 2356000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 33, 5003295539, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 33, 5004295540, 1400000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 41, 740295541, 1035000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 43, 4161295542, 85000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (13, 45, 3235295543, 350000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 5, 5054295299, 2957000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 5, 5119295300, 1960000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 6, 8727295301, 1979000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 7, 898295302, 1467000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 8, 2412295303, 940000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 8, 2466295304, 1074000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 10, 2259295305, 377000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 10, 2314295306, 250000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 11, 5600295307, 1080000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 11, 5649295308, 3480000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 15, 3861295309, 200000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 15, 3896295310, 489000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 16, 7719295311, 1625000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 17, 5123295312, 2070000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 17, 5140295313, 570000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 18, 34295314, 300000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 20, 2276295315, 2340000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 21, 3802295316, 3129000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 21, 3913295317, 3901000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 27, 6084295318, 4025000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 29, 482295319, 1154000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 30, 9018295320, 647000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 30, 9047295321, 622000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 37, 538295322, 79000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 37, 586295323, 454000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (19, 38, 6314295324, 2000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 1, 2481295510, 3354000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 2, 2096295511, 3809000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 3, 2241295512, 1894000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 7, 6538295515, 3258000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 9, 9528295516, 1127000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 10, 8095295517, 2870000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 11, 5684295518, 665000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 15, 2487295519, 240000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 16, 1865295520, 4640000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 17, 9575295521, 220000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 18, 8497295522, 360000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 19, 8211295523, 1694000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 22, 88295524, 2710000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 24, 6509295525, 1074000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 26, 6878295526, 1432000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 29, 1249295527, 1030000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 29, 1312295528, 984000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 34, 6493295529, 3407000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (25, 35, 4160295530, 2848000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 1, 5584295780, 4130000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 1, 5627295781, 1530000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 2, 4415295782, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 2, 4431295783, 1005000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 3, 7508295784, 1750000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 3, 7603295785, 7000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 3, 7661295786, 2114000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 21, 7178295787, 106000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 21, 7206295788, 5454000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 22, 3636295789, 707000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 22, 3706295790, 1012000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (30, 96, 3259295791, 275000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 1, 4633295704, 2290000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 2, 6296295705, 435000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 3, 7579295706, 100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 10, 3244295707, 996000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 10, 3354295708, 5770000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 11, 7306295709, 2309000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 11, 7398295710, 2079000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 12, 2584295711, 6079000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 14, 618295712, 760000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 25, 2121295713, 755000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 25, 2230295714, 1732000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 26, 5161295715, 240000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 30, 4836295716, 4520000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 37, 1994295717, 6000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 37, 2047295718, 2027000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 38, 1016295719, 5842000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 39, 9224295720, 7230000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 39, 9252295721, 6500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 39, 9266295722, 250000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 41, 1695295723, 50000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 42, 9727295724, 435000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 47, 9256295725, 190000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (35, 96, 2144295726, 158000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 4, 5999295559, 6000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 4, 6074295560, 3259000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 5, 9360295561, 1617000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 6, 1260295562, 5560000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 13, 709295563, 3576000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 14, 5987295564, 2720000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 16, 297295565, 1567000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 23, 1302295566, 1810000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 25, 8524295567, 5000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 25, 8558295568, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 25, 8658295569, 3662000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 26, 2588295570, 1634000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 27, 8832295571, 400000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 27, 8833295572, 564000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 29, 233295573, 840000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 36, 4203295574, 3000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 38, 4029295575, 3225000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 39, 8009295576, 494000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 42, 6847295577, 1870000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 45, 8193295578, 725000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 45, 8283295579, 975000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (36, 95, 461295580, 112000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 1, 6166295481, 1225000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 2, 6256295482, 4170000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 3, 5425295483, 2447000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 4, 2851295484, 100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 8, 6628295485, 1562000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 9, 9714295486, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 9, 9743295487, 2887000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 9, 9793295488, 400000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 9, 9794295489, 1820000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 10, 7063295490, 50000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 10, 7063295491, 3950000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 10, 7064295492, 1207000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 12, 7923295493, 595000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 12, 7989295494, 2010000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 20, 899295495, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 20, 900295496, 3000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 20, 912295497, 600000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 22, 707295498, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 22, 709295499, 325000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 22, 807295500, 1659000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 24, 7511295501, 2370000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 35, 5547295502, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 35, 5548295503, 1027000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 36, 4082295504, 350000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 40, 9322295505, 3117000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 41, 950295506, 1799000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 42, 4793295507, 3334000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (38, 44, 4307295508, 1750000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 3, 4587295648, 70000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 5, 5974295649, 147000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 6, 9653295650, 40000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 7, 2115295651, 865000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 10, 4256295652, 2272000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 11, 2026295653, 5186000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 12, 1544295654, 4060000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 16, 4625295655, 3156000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 17, 1340295656, 224000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 18, 3004295657, 1952000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 23, 9494295658, 162000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 24, 315295659, 4095000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 26, 316295660, 346000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 36, 4784295661, 3950000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 36, 4785295662, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 36, 4812295663, 440000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 37, 2834295664, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 37, 2925295665, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 37, 2941295666, 2877000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 38, 3605295667, 1797000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 39, 5508295668, 1975000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 43, 6076295669, 1775000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 44, 7513295670, 136000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 48, 1518295671, 167000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 50, 3782295672, 2732000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 51, 3420295673, 17000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (43, 56, 2166295674, 542000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 1, 421295601, 2139000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 2, 402295602, 2762000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 3, 5667295603, 2460000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 11, 8167295604, 540000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 19, 6739295605, 1925000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 20, 2300295606, 640000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 20, 2300295607, 100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 27, 7473295608, 2935000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 29, 9677295609, 927000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 31, 3890295610, 1380000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 34, 8204295611, 2059000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 35, 9175295612, 100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 36, 1621295613, 230000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (45, 95, 5850295614, 309000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 9, 1066295582, 2500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 9, 1096295583, 1655000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 9, 1195295584, 2922000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 10, 9751295585, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 10, 9826295586, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 10, 9861295587, 2910000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 11, 939295588, 1500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 11, 987295589, 600000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 11, 1019295590, 2009000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 17, 205295591, 7000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 20, 5233295592, 1850000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 23, 8938295593, 966000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 26, 4552295594, 350000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 26, 6075295595, 2908000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 41, 6625295596, 3007000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 44, 9667295597, 645000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 45, 9126295598, 879000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 93, 4897295599, 779000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (50, 96, 9101295600, 25000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 3, 1138295390, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 3, 1172295391, 3227000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 10, 6560295392, 1402000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 10, 6561295393, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 12, 5006295394, 2158000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 15, 2770295395, 164000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 16, 5153295396, 196000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 19, 8687295397, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 19, 8719295398, 2144000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 20, 3629295399, 810000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 21, 4730295400, 3366000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 22, 4562295401, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 22, 4597295402, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 22, 4653295403, 2500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 22, 4660295404, 747000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 31, 67295405, 856000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 34, 8078295406, 3950000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 34, 8079295407, 474000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 37, 1229295408, 502000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 43, 9324295409, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 43, 9429295410, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (53, 43, 9430295411, 2008000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 5, 2755295765, 1477000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 5, 2900295766, 2502000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 8, 5523295767, 1194000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 9, 1233295768, 767000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 10, 8411295769, 4535000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 14, 7306295770, 1924000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 15, 150295771, 2105000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 16, 2860295772, 607000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 16, 2951295773, 499000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 17, 6536295774, 1797000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 19, 740295775, 870000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 19, 823295776, 1305000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 22, 5792295777, 2369000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 25, 3954295778, 2730000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (56, 95, 1632295779, 38000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 6, 4474295435, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 6, 4475295436, 892000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 12, 6747295437, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 12, 6823295438, 2832000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 15, 3545295439, 1715000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 18, 7722295440, 1000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 20, 6356295441, 3787000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 21, 145295442, 495000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 23, 872295443, 400000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 28, 1620295444, 2842000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 29, 4142295445, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 29, 4143295446, 2242000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 36, 5487295447, 2016000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 37, 869295448, 3830000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 37, 963295449, 2985000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 42, 7598295450, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 42, 7614295451, 936000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 47, 9918295452, 1972000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 48, 4201295453, 2850000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 48, 4202295454, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (60, 48, 4209295455, 350000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 4, 4725295367, 1305000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 5, 5314295368, 825000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 7, 9086295369, 2100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 7, 9175295370, 5289000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 8, 4452295371, 1377000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 14, 3172295372, 2040000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 17, 23295373, 1844000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 19, 3107295374, 280000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 25, 2962295375, 1509000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 29, 2380295376, 3660000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 30, 3390295377, 1960000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 41, 6546295378, 1515000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 45, 8644295379, 802000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (72, 95, 1846295380, 39000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 1, 5716295752, 1516000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 2, 190295753, 410000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 4, 7407295754, 1197000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 7, 2333295755, 2352000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 9, 5672295756, 1904000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 11, 5068295757, 1624000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 11, 5170295758, 5315000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 12, 6578295759, 2830000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 13, 6810295760, 5675000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 14, 6996295761, 1930000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 22, 8443295762, 1605000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 37, 692295763, 25000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (82, 59, 6846295764, 1615000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 3, 7176295632, 262000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 6, 8801295633, 2825000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 11, 6738295634, 1220000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 12, 6362295635, 3675000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 12, 6362295636, 2000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 13, 5155295637, 3679000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 14, 6682295638, 3650000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 17, 4176295639, 437000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 24, 2822295640, 3007000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 27, 8837295641, 2610000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 30, 9047295642, 2616000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 31, 1881295643, 330000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 33, 6944295644, 2416000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 33, 7051295645, 3694000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 41, 7042295646, 2050000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (85, 45, 8350295647, 2666000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 1, 660295382, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 1, 661295383, 1516000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 2, 502295384, 3129000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 3, 6468295385, 5570000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 28, 9135295386, 1135000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 34, 7636295387, 860000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 34, 7677295388, 2746000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (96, 35, 8811295389, 210000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 5, 1705295728, 210000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 5, 1708295729, 712000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 5, 1766295730, 980000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 10, 223295731, 5712000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 11, 6132295732, 3897000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 11, 6279295733, 4324000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 12, 2825295734, 90000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 18, 7828295735, 2282000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 20, 4368295736, 425000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 22, 5432295737, 4100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 22, 5437295738, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 22, 5438295739, 1100000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 22, 5460295740, 67000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 32, 2122295741, 982000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 36, 5811295742, 50000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 36, 5811295743, 4950000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 36, 5845295744, 4790000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 36, 5943295745, 2247000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 37, 1966295746, 4250000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 38, 7711295747, 1160000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 39, 1504295748, 3590000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 41, 1241295749, 1856000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 41, 1334295750, 4170000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (98, 42, 8605295751, 3079000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 1, 1688295412, 1002000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 10, 8710295413, 2807000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 13, 5916295414, 3840000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 14, 563295415, 2795000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 19, 6338295416, 728000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 23, 5414295417, 3835000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 23, 5515295418, 2056000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 28, 1892295419, 3842000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 28, 1982295420, 1480000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 29, 8525295421, 3770000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 30, 3610295422, 1088000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 30, 3688295423, 1835000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 31, 3300295424, 1965000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 33, 8573295425, 2297000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 37, 3087295426, 1977000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 43, 9886295427, 1930000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 43, 9886295428, 50000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 45, 6300295429, 2168000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 47, 5989295430, 232000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 48, 6308295431, 915000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 54, 7404295432, 4007000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (101, 95, 9276295433, 500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 1, 9931295325, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 1, 9963295326, 1036000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 2, 7050295327, 4950000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 2, 7093295328, 2244000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 8, 2045295329, 960000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 9, 7071295330, 120000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 19, 9415295331, 5000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 19, 9440295332, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 19, 9486295333, 3255000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 20, 8987295334, 2650000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 26, 695295335, 5776000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 28, 2492295336, 5742000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 31, 7243295337, 3500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 31, 7265295338, 850000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 36, 8147295339, 2200000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (108, 97, 862295340, 170000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 2, 678295341, 569000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 6, 7438295342, 4730000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 7, 7917295343, 5827000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 7, 7944295344, 6700000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 7, 8008295345, 2340000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 7, 8030295346, 340000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 9, 5888295347, 7000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 9, 5924295348, 939000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 11, 4166295349, 1945000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 12, 105295350, 354000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 19, 1467295351, 7500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 19, 1541295352, 2465000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 19, 1627295353, 1207000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 22, 2976295354, 704000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 27, 7599295355, 800000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 33, 113295356, 10000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 37, 9768295357, 6450000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 37, 9831295358, 627000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 37, 9874295359, 40000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 38, 7162295360, 2848000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 39, 5502295361, 6300000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 39, 5556295362, 1240000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 42, 922295363, 1150000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 42, 922295364, 10000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (123, 44, 1003295365, 1832000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 2, 6851295456, 605000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 2, 6913295457, 1674000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 6, 3896295458, 2450000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 7, 5713295459, 3102000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 7, 5713295460, 50000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 7, 5773295461, 1894000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 8, 1810295462, 3270000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 10, 2888295463, 820000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 10, 2968295464, 937000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 12, 180295465, 870000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 12, 269295466, 1716000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 14, 2282295467, 2050000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 14, 2315295468, 127000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 15, 7638295469, 136000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 15, 7664295470, 1050000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 16, 8875295471, 1120000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 17, 3008295472, 1492000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 18, 9074295473, 4215000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 19, 7928295474, 952000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 19, 7939295475, 16000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 20, 8651295476, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 20, 8659295477, 2490000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 20, 8738295478, 1177000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 22, 5329295479, 479000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (131, 22, 5338295480, 555000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 1, 5111295675, 1096000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 2, 4190295676, 90000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 3, 4951295677, 117000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 6, 7610295678, 2632000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 7, 8213295679, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 7, 8304295680, 2567000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 9, 1522295682, 60000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 18, 68295683, 540000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 22, 6575295684, 888000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 23, 8368295685, 792000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 26, 744295686, 2587000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 26, 841295687, 1315000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 29, 2903295688, 972000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 31, 3917295689, 2075000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 32, 7142295690, 517000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 34, 9396295691, 459000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 35, 8243295692, 1966000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 42, 4303295693, 1572000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 43, 9485295694, 1852000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 45, 3936295695, 822000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 46, 2564295696, 2500000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 47, 5388295697, 200000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 48, 1765295698, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 48, 1793295699, 2422000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 48, 1854295700, 578000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 51, 9620295701, 1775000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 57, 5989295702, 739000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (138, 59, 7129295703, 960000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (141, 8, 5575295681, 499000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (142, 4, 30295513, 1365000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (142, 5, 1936295514, 1082000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 2, 7405295544, 4000000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 2, 7414295545, 745000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 3, 5508295546, 1085000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 5, 6368295547, 3027000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 7, 4946295548, 1334000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 8, 6518295549, 3839000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 18, 5010295550, 282000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 22, 7579295551, 1694000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 24, 478295552, 1570000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 30, 1711295553, 1140000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 35, 183295554, 1764000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 45, 4008295555, 3460000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 57, 8567295556, 882000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 57, 8681295557, 2974000, 0, 123, to_date('20260828','yyyymmdd'), 1);
insert into VTA_FACOPOC_PRD3 values (183, 58, 6722295558, 1510000, 0, 123, to_date('20260828','yyyymmdd'), 1);
commit;

-- Control (esperado: 486 filas, 357 cajas, 27 locales, total 992569000)
select count(*) filas, count(distinct p_local || '-' || p_terminal || '-' || p_cierrey) cajas,
       count(distinct p_local) locales, sum(p_monto) total from VTA_FACOPOC_PRD3;

-- ---------------------------------------------------------------
-- 2. Cajas del dia PRD 3: cierre Y + libro de ventas + escenario
-- ---------------------------------------------------------------
declare
  c_fecha  constant date   := to_date('20260828', 'yyyymmdd');
  c_off    constant number := 990000000;     -- techkey del dia PRD 3
  c_fec_tx constant varchar2(40) := 'to_date(''20260828'',''yyyymmdd'')';

  v_tpl     number;                 -- techkey de la fila molde (libvta Y de TEST)
  v_k       number := 0;            -- correlativo de techkey
  v_n       number := 0;            -- correlativo de caja
  v_nloc    number := 0;            -- correlativo de local
  v_sel_lib varchar2(8000);
  v_col_lib varchar2(8000);
  v_sel_zzz varchar2(16000);
  v_col_zzz varchar2(16000);
  v_esc     varchar2(3);
  v_dr      number;
  v_t1      varchar2(30);
  v_t2      varchar2(30);
  v_r       number;

  procedure crear_caja (p_local number, p_terminal number, p_y number, p_declarado number) is
    v_sql varchar2(32767);
  begin
    v_k := v_k + 1;
    insert into VTA_FACOTERMSTATY (ter_local, ter_terminal, ter_fecha, ter_cierrey, ter_estado, ter_notas, ter_cerradopor)
    values (p_local, p_terminal, c_fecha, p_y, -1, null, null);

    v_sql := replace(replace(replace(replace(replace(v_sel_lib,
               '#FECHA#', c_fec_tx), '#LOCAL#', to_char(p_local)), '#TERM#', to_char(p_terminal)),
               '#Y#', to_char(p_y)), '#KEY#', to_char(c_off + v_k));
    execute immediate 'insert into VTA_FACOLIBVTA (' || v_col_lib || ') select ' || v_sql
                   || ' from VTA_FACOLIBVTA where vta_techkey = ' || v_tpl
                   || ' and vta_tiporeg = ''Y''';

    v_sql := replace(replace(v_sel_zzz, '#KEY#', to_char(c_off + v_k)), '#EFE#', to_char(p_declarado));
    execute immediate 'insert into VTA_FACOZZZ (' || v_col_zzz || ') select ' || v_sql
                   || ' from VTA_FACOZZZ where rec_techkey = ' || v_tpl;
  end crear_caja;

  procedure caso (p_esc varchar2, p_local number, p_terminal number, p_y number,
                  p_dr number, p_t1 varchar2, p_t2 varchar2) is
  begin
    insert into VTA_FACOPOC_CASOS (c_origen, escenario, c_fecha, c_local, c_terminal, c_cierrey,
                                   dr_objetivo, esperado_t1, esperado_t2)
    values ('PRD3', p_esc, c_fecha, p_local, p_terminal, p_y, p_dr, p_t1, p_t2);
  end caso;
begin
  -- Molde: una fila real de libro de ventas Y copiada de TEST (02_datos_test.sql)
  select min(l.vta_techkey) into v_tpl
    from VTA_FACOLIBVTA l
   where l.vta_techkey between 900000000 and 989999999 and l.vta_tiporeg = 'Y'
     and exists (select 1 from VTA_FACOZZZ r where r.rec_techkey = l.vta_techkey);
  if v_tpl is null then
    raise_application_error(-20001, 'No hay filas molde: ejecutar antes 02_datos_test.sql');
  end if;

  -- Listas de columnas: se copian todas del molde salvo las que identifican la caja
  for c in (select column_name from user_tab_columns where table_name = 'VTA_FACOLIBVTA' order by column_id) loop
    v_col_lib := v_col_lib || case when v_col_lib is not null then ', ' end || c.column_name;
    v_sel_lib := v_sel_lib || case when v_sel_lib is not null then ', ' end ||
      case c.column_name
        when 'VTA_FECHA'       then '#FECHA#'
        when 'VTA_FECHA_VENTA' then '#FECHA#'
        when 'VTA_LOCAL'       then '#LOCAL#'
        when 'VTA_TERMINAL'    then '#TERM#'
        when 'VTA_SECUENCIA'   then '#Y#'
        when 'VTA_TECHKEY'     then '#KEY#'
        when 'VTA_TIPOREG'     then '''Y'''
        when 'VTA_ESTADO'      then '''A'''
        else c.column_name
      end;
  end loop;
  for c in (select column_name from user_tab_columns where table_name = 'VTA_FACOZZZ' order by column_id) loop
    v_col_zzz := v_col_zzz || case when v_col_zzz is not null then ', ' end || c.column_name;
    v_sel_zzz := v_sel_zzz || case when v_sel_zzz is not null then ', ' end ||
      case c.column_name
        when 'REC_TECHKEY'   then '#KEY#'
        when 'REC_MEFECTIVO' then '#EFE#'      -- efectivo declarado del escenario
        when 'REC_MCHKDIA'   then '0'
        when 'REC_MCHKFECHA' then '0'
        when 'REC_MTARJ'     then '0'
        when 'REC_MSODIMAC'  then '0'
        else c.column_name
      end;
  end loop;

  -- Cajas del archivo (Y 1), en orden local / terminal
  for c in (select p_local l, p_terminal t, p_cierrey y, sum(p_monto) + sum(p_dif) sobres
              from VTA_FACOPOC_PRD3
             group by p_local, p_terminal, p_cierrey
             order by p_local, p_terminal, p_cierrey) loop
    v_n := v_n + 1;
    v_r := mod(v_n, 20);
    if v_n = 1 then
      v_esc := 'P3'; v_dr := -1000;  v_t1 := 'DI_REGISTRADA'; v_t2 := 'CERRADA_Y';
    elsif v_n = 2 then
      v_esc := 'P3'; v_dr := 20000;  v_t1 := 'DI_REGISTRADA'; v_t2 := 'CERRADA_Y';
    elsif v_r between 1 and 10 then
      v_esc := 'P0'; v_dr := 0;      v_t1 := 'DR_CERO';       v_t2 := 'CERRADA_Y';
    elsif v_r in (11, 12, 19) then
      v_esc := 'P1'; v_dr := -800;   v_t1 := 'DI_REGISTRADA'; v_t2 := 'CERRADA_Y';
    elsif v_r in (13, 14, 0) then
      v_esc := 'P2'; v_dr := 3000;   v_t1 := 'DI_REGISTRADA'; v_t2 := 'CERRADA_Y';
    elsif v_r = 15 then
      v_esc := 'P4'; v_dr := -30000; v_t1 := 'FUERA_RANGO';   v_t2 := 'CON_DIFERENCIA';
    elsif v_r = 16 then
      v_esc := 'P4'; v_dr := 25000;  v_t1 := 'FUERA_RANGO';   v_t2 := 'CON_DIFERENCIA';
    else  -- 17, 18
      v_esc := 'P5'; v_dr := 0;      v_t1 := 'DR_CERO';       v_t2 := 'BLOQUEADA';
    end if;

    -- DR = sobres - efectivo declarado  =>  declarado = sobres - DR
    crear_caja(c.l, c.t, c.y, c.sobres - v_dr);
    caso(v_esc, c.l, c.t, c.y, v_dr, v_t1, v_t2);

    if v_esc = 'P5' then
      -- Sobre no enviado (SN) declarado y SIN regularizar: bloquea el cierre (RY-03)
      insert into VTA_FACOMOVDET (mov_fecha, mov_local, mov_terminal, mov_tipomov, mov_rol, mov_nombre,
                                  mov_secuencia, mov_numero, mov_monto, mov_hechopor, mov_regul,
                                  mov_techkey, mov_cierrey)
      values (c_fecha, c.l, c.t, 'SN', 0, ' ', 0, 0, 1000, 'POC_FSCC12901', 'N',
              c_off + 900000 + v_n, c.y);
    end if;
  end loop;

  -- Cajas SIN sobres en cada local (entran al universo como SIN_SOBRE)
  for l in (select p_local l, min(p_terminal) t from VTA_FACOPOC_PRD3 group by p_local order by p_local) loop
    v_nloc := v_nloc + 1;
    insert into VTA_FACOPOC_DIAS (d_origen, d_fecha, d_local) values ('PRD3', c_fecha, l.l);

    -- P6: caja sin movimiento (declarado 0) -> DR 0 -> se cierra (DF-SCC fila 12)
    crear_caja(l.l, l.t, 2, 0);
    caso('P6', l.l, l.t, 2, 0, 'DR_CERO', 'CERRADA_Y');

    -- P7: caja sin sobre pero con venta en efectivo (cada 3 locales) -> fuera de rango
    if mod(v_nloc, 3) = 0 then
      crear_caja(l.l, l.t, 3, 5000);
      caso('P7', l.l, l.t, 3, -5000, 'FUERA_RANGO', 'CON_DIFERENCIA');
    end if;
  end loop;

  commit;
  dbms_output.put_line('Dia PRD 3: ' || v_n || ' cajas del archivo + ' || (v_k - v_n) || ' cajas sin sobre. Molde: techkey ' || v_tpl);
end;
/

-- ---------------------------------------------------------------
-- 3. Control: cajas por escenario (P0 ~50%, P1/P2 ~15% c/u, P4 ~10%, P5 ~10%,
--    P3 = 2, P6 = 27, P7 = 9)
-- ---------------------------------------------------------------
select escenario, count(*) cajas, min(dr_objetivo) dr_min, max(dr_objetivo) dr_max,
       max(esperado_t1) esperado_t1, max(esperado_t2) esperado_t2
  from VTA_FACOPOC_CASOS where c_origen = 'PRD3'
 group by escenario order by escenario;
