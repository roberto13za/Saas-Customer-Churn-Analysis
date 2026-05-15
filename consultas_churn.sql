-- Crear la tabla con tipos de datos
CREATE TABLE clientes_churn (
    customerID VARCHAR(50) PRIMARY KEY,
    gender VARCHAR(20),
    SeniorCitizen INT,
    Partner VARCHAR(10),
    Dependents VARCHAR(10),
    tenure INT,
    PhoneService VARCHAR(10),
    MultipleLines VARCHAR(30),
    InternetService VARCHAR(30),
    OnlineSecurity VARCHAR(30),
    OnlineBackup VARCHAR(30),
    DeviceProtection VARCHAR(30),
    TechSupport VARCHAR(30),
    StreamingTV VARCHAR(30),
    StreamingMovies VARCHAR(30),
    Contract VARCHAR(30),
    PaperlessBilling VARCHAR(10),
    PaymentMethod VARCHAR(50),
    MonthlyCharges FLOAT,
    TotalCharges FLOAT,
    Churn INT,
    ARPU FLOAT,
    High_Risk INT
);

-- Ingesta de datos
COPY clientes_churn 
FROM 'C:\Users\Public\Churn_Cleaned.csv' 
WITH (FORMAT CSV, HEADER, DELIMITER ',');

--Consulta 1. CTE para analisis de ingreso
WITH ResumenContrato AS (
    SELECT 
        Contract, 
        COUNT(*) as TotalClientes, 
        ROUND(SUM(MonthlyCharges)::numeric, 2) as IngresoMensual
    FROM clientes_churn
    GROUP BY Contract
)
SELECT 
    *, 
    ROUND((IngresoMensual / TotalClientes)::numeric, 2) as PromedioPorContrato
FROM ResumenContrato;

--Consulta 2. Raking de quen paga mas (window functions)
SELECT 
    customerID, 
    Contract, 
    MonthlyCharges,
    RANK() OVER(PARTITION BY Contract ORDER BY MonthlyCharges DESC) as RangoCosto
FROM clientes_churn
LIMIT 10;

-- Consulta 3. Calculo de % de churn por soporte tecnico

SELECT 
    TechSupport,
    COUNT(*) as Total,
    SUM(Churn) as Abandonos,
    ROUND((SUM(Churn)::float / COUNT(*)::float * 100)::numeric, 2) as PorcentajeChurn
FROM clientes_churn
GROUP BY TechSupport;

-- Consulta 4. crear un creat view para visualizar tabla

CREATE VIEW v_reporte_churn_bi AS
SELECT 
    customerID,
    gender,
    tenure,
    Contract,
    InternetService,
    TechSupport,
    MonthlyCharges,
    TotalCharges,
    ARPU,
    High_Risk,
    CASE WHEN Churn = 1 THEN 'Abandona' ELSE 'Fiel' END as EstadoCliente,
    CASE WHEN MonthlyCharges > 70 THEN 'Ticket Alto' ELSE 'Ticket Bajo' END as SegmentoPrecio
FROM clientes_churn;


-- Consulta 5. vista limitada a 10 registro de la tabla virtual creada
SELECT *
FROM v_reporte_churn_bi
LIMIT 10;
