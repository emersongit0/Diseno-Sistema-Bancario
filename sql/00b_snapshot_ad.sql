-- Ejecutar como SCRIPT y guardar los resultados en docs/snapshot_ad_antes.txt.
-- En Fase 3 guardar la misma salida en docs/snapshot_ad_despues.txt.
-- Solo compara nombres y cantidad; no lee el contenido de las tablas.
SELECT COUNT(*) AS TOTAL_TABLAS_AD
FROM USER_TABLES
WHERE table_name LIKE 'AD!_%' ESCAPE '!';

SELECT table_name
FROM USER_TABLES
WHERE table_name LIKE 'AD!_%' ESCAPE '!'
ORDER BY table_name;
