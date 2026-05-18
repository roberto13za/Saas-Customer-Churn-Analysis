-- ==============================================================================
-- PROYECTO: OPTIMIZACIÓN DE BASE DE DATOS Y REPORTING DE CHURN
-- SERVICIO: Telecomunicaciones (PostgreSQL)
-- PROTOCOLO: Refactorización y Buenas Prácticas
-- ==============================================================================

-- --- 1. DEFINICIÓN DE LA ESTRUCTURA DE DATOS (DDL) ---
-- Se aplica snake_case a todas las columnas para estandarizar el repositorio.
CREATE TABLE clientes_churn (
    customer_id VARCHAR(50) PRIMARY KEY,
    gender VARCHAR(20),
    senior_citizen INT,
    partner VARCHAR(10),
    dependents VARCHAR(10),
    tenure INT,
    phone_service VARCHAR(10),
    multiple_lines VARCHAR(30),
    internet_service VARCHAR(30),
    online_security VARCHAR(30),
    online_backup VARCHAR(30),
    device_protection VARCHAR(30),
    tech_support VARCHAR(30),
    streaming_tv VARCHAR(30),
    streaming_movies VARCHAR(30),
    contract_type VARCHAR(30), -- Renombrado para evitar conflicto con palabra reservada 'Contract'
    paperless_billing VARCHAR(10),
    payment_method VARCHAR(50),
    monthly_charges FLOAT,
    total_charges FLOAT,
    churn INT,
    arpu FLOAT,
    high_risk INT
);

-- --- 2. INGESTA DE DATOS DESDE EL DATASET PROCESADO ---
COPY clientes_churn  
FROM 'C:\Users\Public\Churn_Cleaned.csv'  
WITH (FORMAT CSV, HEADER, DELIMITER ',');


-- --- 3. QUERIES DE INTELIGENCIA DE NEGOCIO (DML) ---

-- ------------------------------------------------------------------------------
-- CONSULTA 1: ANÁLISIS DE DISTRIBUCIÓN DE INGRESOS POR TIPO DE CONTRATO
-- Problema de negocio: Evaluar qué contratos generan el mayor flujo de caja mensual
-- y calcular el valor promedio por usuario (ARPU) en cada modalidad contractual.
-- ------------------------------------------------------------------------------
WITH resumen_contrato_cte AS (
    SELECT  
        c.contract_type AS tipo_contrato, 
        COUNT(*) AS total_clientes, 
        ROUND(SUM(c.monthly_charges)::numeric, 2) AS ingreso_mensual_total
    FROM clientes_churn AS c
    GROUP BY c.contract_type
)
SELECT 
    rc.tipo_contrato,
    rc.total_clientes,
    rc.ingreso_mensual_total,
    ROUND((rc.ingreso_mensual_total / rc.total_clientes)::numeric, 2) AS promedio_por_contrato
FROM resumen_contrato_cte AS rc;


-- ------------------------------------------------------------------------------
-- CONSULTA 2: RANKING DE FACTURACIÓN MÁS ALTA POR SEGMENTO CONTRACTUAL
-- Problema de negocio: Identificar y rankear a los clientes que pagan las tarifas
-- más altas en cada tipo de contrato para priorizar campañas de fidelización VIP.
-- ------------------------------------------------------------------------------
SELECT 
    c.customer_id AS cliente_id, 
    c.contract_type AS tipo_contrato, 
    c.monthly_charges AS cargos_mensuales,
    RANK() OVER (
        PARTITION BY c.contract_type 
        ORDER BY c.monthly_charges DESC
    ) AS rango_costo
FROM clientes_churn AS c
LIMIT 10;


-- ------------------------------------------------------------------------------
-- CONSULTA 3: IMPACTO DEL SOPORTE TÉCNICO EN LA TASA DE DESERCIÓN
-- Problema de negocio: Medir el impacto directo que tiene el servicio de soporte 
-- técnico en la retención del cliente para justificar inversiones en el área de soporte.
-- ------------------------------------------------------------------------------
SELECT 
    c.tech_support AS servicio_soporte,
    COUNT(*) AS total_clientes,
    SUM(c.churn) AS total_abandonos,
    ROUND(
        (SUM(c.churn)::float / COUNT(*)::float * 100)::numeric, 2
    ) AS porcentaje_churn
FROM clientes_churn AS c
GROUP BY c.tech_support
ORDER BY porcentaje_churn DESC;


-- ------------------------------------------------------------------------------
-- CONSULTA 4: CAPA DE SEMÁNTICA / VISTA PARA POWER BI
-- Problema de negocio: Crear una capa de abstracción limpia y estandarizada que 
-- categorice el estado del cliente y su nivel de ticket monetario para consumo del dashboard.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_reporte_churn_bi AS
SELECT 
    c.customer_id AS cliente_id,
    c.gender AS genero,
    c.tenure AS meses_antiguedad,
    c.contract_type AS tipo_contrato,
    c.internet_service AS servicio_internet,
    c.tech_support AS soporte_tecnico,
    c.monthly_charges AS cargos_mensuales,
    c.total_charges AS cargos_totales,
    c.arpu,
    c.high_risk AS indicador_alto_riesgo,
    CASE 
        WHEN c.churn = 1 THEN 'Abandona' 
        ELSE 'Fiel' 
    END AS estado_cliente,
    CASE 
        WHEN c.monthly_charges > 70 THEN 'Ticket Alto' 
        ELSE 'Ticket Bajo' 
    END AS segmento_precio
FROM clientes_churn AS c;


-- ------------------------------------------------------------------------------
-- CONSULTA 5: AUDITORÍA DE LA VISTA
-- Ejecución de control para asegurar la integridad de los datos mapeados en la vista.
-- ------------------------------------------------------------------------------
SELECT *
FROM v_reporte_churn_bi
LIMIT 10;