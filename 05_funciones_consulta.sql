-- ============================================================
-- 05_funciones_consulta.sql
-- Función Órdenes del mesero en el día actual
-- Función Ventas por rango de fechas
-- Proyecto Final BD - Grupo 01
-- PostgreSQL
-- ============================================================


-- Función que recibe el número de empleado, verifica si es mesero y si sí lo es, 
-- cuenta las órdenes de su día y suma el dinero
CREATE OR REPLACE FUNCTION ordenes_mesero_hoy(p_num_empleado VARCHAR(10))
RETURNS TABLE (cantidad_ordenes BIGINT, total_cobrado NUMERIC) AS $$
DECLARE
    -- Declaramos una variable para guardar si el empleado es mesero o no
    v_es_mesero BOOLEAN;
BEGIN
    -- Validamos si existe en la tabla de meseros
    -- Nota: Asumo que Carlos creó una tabla hija llamada 'mesero' por la herencia. 
    -- Si le puso otro nombre en su DDL (como 'meseros' o lo manejó con un atributo 'rol' en la tabla empleado), 
    -- solo cambia el nombre de la tabla aquí en el FROM.
    SELECT EXISTS(SELECT 1 FROM mesero WHERE num_empleado = p_num_empleado) INTO v_es_mesero;

    -- Si no es mesero, lanzamos el error tal como pide el requerimiento
    IF NOT v_es_mesero THEN
        RAISE EXCEPTION 'Error: El empleado con número % no es un mesero válido.', p_num_empleado;
    END IF;

    -- Si pasa la validación, hacemos la consulta.
    -- RETURN QUERY hace que la función devuelva directamente el resultado de este SELECT.
    RETURN QUERY
    SELECT 
        COUNT(folio)::BIGINT, 
        -- Usamos COALESCE por si el mesero no ha vendido nada hoy, para que devuelva 0 en vez de NULL, así se evita resultados en blanco
        COALESCE(SUM(total), 0)::NUMERIC 
    FROM orden
    WHERE num_empleado = p_num_empleado 
      AND fecha = CURRENT_DATE; -- Filtramos para que solo cuente lo del día de hoy
END;
$$ LANGUAGE plpgsql;



-- Función que recibe la fecha de inicio y la fecha de fin. Si la fecha no se envía,
-- se asume que solo queremos consultar las ventas de un día.

-- Se espera obtener el total de ventas y monto en un periodo de tiempo
CREATE OR REPLACE FUNCTION ventas_por_fechas(p_fecha_inicio DATE, p_fecha_fin DATE DEFAULT NULL)
RETURNS TABLE (total_ventas BIGINT, monto_total NUMERIC) AS $$
BEGIN
    -- Si no dan fecha_fin, se usa la misma que fecha_inicio para buscar en un solo día
    IF p_fecha_fin IS NULL THEN
        p_fecha_fin := p_fecha_inicio;
    END IF;

    -- Devolvemos el conteo de ventas y la suma total del dinero
    RETURN QUERY
    SELECT 
        COUNT(folio)::BIGINT,
        COALESCE(SUM(total), 0.00)::NUMERIC
    FROM orden
    WHERE fecha >= p_fecha_inicio 
      AND fecha <= p_fecha_fin;
END;
$$ LANGUAGE plpgsql;
