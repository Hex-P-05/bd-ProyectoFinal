-- ============================================================
-- 00_ejecutar_todo.sql
-- Script maestro del sistema de restaurante - Oracle 23ai Free
-- Proyecto Final BD - Grupo 01
-- Ejecutar: sqlplus /nolog @/unam/bd/proyecto/00_ejecutar_todo.sql
-- ============================================================
WHENEVER SQLERROR CONTINUE
SET ECHO OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET LINESIZE 200
SET PAGESIZE 50


-- ============================================================
-- PARTE 1: USUARIO EN CPBBD_S1
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT PARTE 1: USUARIO cpb_restaurante
PROMPT ============================================================

CONNECT sys/system1@cpbbd_s1 AS SYSDBA

BEGIN
    EXECUTE IMMEDIATE 'DROP USER cpb_restaurante CASCADE';
    DBMS_OUTPUT.PUT_LINE('Usuario cpb_restaurante eliminado.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Usuario no existia, continuando...');
END;
/

CREATE USER cpb_restaurante IDENTIFIED BY restaurante QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER
TO cpb_restaurante;

CONNECT cpb_restaurante/restaurante@cpbbd_s1
PROMPT Conectado como cpb_restaurante en CPBBD_S1.


-- ============================================================
-- PARTE 2: SECUENCIAS
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT PARTE 2: SECUENCIAS
PROMPT ============================================================

DROP SEQUENCE IF EXISTS folio_seq;
DROP SEQUENCE IF EXISTS dependiente_id_seq;
DROP SEQUENCE IF EXISTS categoria_id_seq;
DROP SEQUENCE IF EXISTS producto_id_seq;

CREATE SEQUENCE folio_seq          START WITH 1 INCREMENT BY 1 MINVALUE 1 NOCYCLE NOCACHE;
CREATE SEQUENCE dependiente_id_seq  START WITH 1 INCREMENT BY 1 MINVALUE 1 NOCYCLE NOCACHE;
CREATE SEQUENCE categoria_id_seq   START WITH 1 INCREMENT BY 1 MINVALUE 1 NOCYCLE NOCACHE;
CREATE SEQUENCE producto_id_seq    START WITH 1 INCREMENT BY 1 MINVALUE 1 NOCYCLE NOCACHE;

PROMPT Secuencias creadas.


-- ============================================================
-- PARTE 3: TABLAS
-- Estrategia tabla-por-subclase para EMPLEADO y PRODUCTO.
-- Oracle no tiene ON UPDATE CASCADE: se omite (comportamiento
-- por defecto de Oracle ya impide borrar padres con hijos).
-- hora: Oracle DATE almacena fecha+hora; DEFAULT SYSDATE captura
-- la hora del momento del INSERT.
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT PARTE 3: TABLAS
PROMPT ============================================================

DROP TABLE IF EXISTS detalle_orden  CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS orden          CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS bebida         CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS platillo       CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS producto       CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS categoria      CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS cliente_fact   CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS administrativo CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS cocinero       CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS mesero         CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS dependiente    CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS telefono_empleado CASCADE CONSTRAINTS;
DROP TABLE IF EXISTS empleado       CASCADE CONSTRAINTS;

CREATE TABLE empleado (
    num_empleado     VARCHAR2(10)   NOT NULL,
    nombre_pila      VARCHAR2(40)   NOT NULL,
    apellido_paterno VARCHAR2(40)   NOT NULL,
    apellido_materno VARCHAR2(40)   NOT NULL,
    rfc              VARCHAR2(13)   NOT NULL,
    fecha_nacimiento DATE           NOT NULL,
    edad             NUMBER         NOT NULL,
    sueldo           NUMBER(10,2)   NOT NULL,
    foto             BLOB,
    estado           VARCHAR2(40)   NOT NULL,
    codigo_postal    VARCHAR2(5)    NOT NULL,
    colonia          VARCHAR2(100)  NOT NULL,
    calle            VARCHAR2(100)  NOT NULL,
    numero           VARCHAR2(10)   NOT NULL,
    CONSTRAINT pk_empleado     PRIMARY KEY (num_empleado),
    CONSTRAINT uq_empleado_rfc UNIQUE (rfc),
    CONSTRAINT ck_sueldo       CHECK (sueldo > 0)
);

CREATE TABLE telefono_empleado (
    num_empleado VARCHAR2(10) NOT NULL,
    telefono     VARCHAR2(15) NOT NULL,
    CONSTRAINT pk_telefono          PRIMARY KEY (num_empleado, telefono),
    CONSTRAINT fk_telefono_empleado FOREIGN KEY (num_empleado)
        REFERENCES empleado (num_empleado) ON DELETE CASCADE
);

CREATE TABLE dependiente (
    dependiente_id NUMBER        DEFAULT dependiente_id_seq.NEXTVAL NOT NULL,
    num_empleado   VARCHAR2(10)  NOT NULL,
    nombre         VARCHAR2(40)  NOT NULL,
    ap_paterno     VARCHAR2(40)  NOT NULL,
    ap_materno     VARCHAR2(40)  NOT NULL,
    curp           VARCHAR2(18)  NOT NULL,
    parentesco     VARCHAR2(30)  NOT NULL,
    CONSTRAINT pk_dependiente          PRIMARY KEY (dependiente_id),
    CONSTRAINT uq_dependiente_curp     UNIQUE (curp),
    CONSTRAINT fk_dependiente_empleado FOREIGN KEY (num_empleado)
        REFERENCES empleado (num_empleado) ON DELETE CASCADE
);

CREATE TABLE cocinero (
    num_empleado VARCHAR2(10)  NOT NULL,
    especialidad VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_cocinero          PRIMARY KEY (num_empleado),
    CONSTRAINT fk_cocinero_empleado FOREIGN KEY (num_empleado)
        REFERENCES empleado (num_empleado) ON DELETE CASCADE
);

CREATE TABLE mesero (
    num_empleado VARCHAR2(10) NOT NULL,
    horario      VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_mesero          PRIMARY KEY (num_empleado),
    CONSTRAINT fk_mesero_empleado FOREIGN KEY (num_empleado)
        REFERENCES empleado (num_empleado) ON DELETE CASCADE
);

CREATE TABLE administrativo (
    num_empleado VARCHAR2(10) NOT NULL,
    rol          VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_administrativo          PRIMARY KEY (num_empleado),
    CONSTRAINT fk_administrativo_empleado FOREIGN KEY (num_empleado)
        REFERENCES empleado (num_empleado) ON DELETE CASCADE
);

CREATE TABLE categoria (
    categoria_id NUMBER         DEFAULT categoria_id_seq.NEXTVAL NOT NULL,
    nombre       VARCHAR2(40)   NOT NULL,
    descripcion  VARCHAR2(4000) NOT NULL,
    CONSTRAINT pk_categoria PRIMARY KEY (categoria_id)
);

CREATE TABLE producto (
    producto_id    NUMBER         DEFAULT producto_id_seq.NEXTVAL NOT NULL,
    nombre         VARCHAR2(40)   NOT NULL,
    descripcion    VARCHAR2(4000) NOT NULL,
    precio         NUMBER(8,2)    NOT NULL,
    disponibilidad BOOLEAN        DEFAULT TRUE NOT NULL,
    receta         VARCHAR2(4000) NOT NULL,
    categoria_id   NUMBER         NOT NULL,
    tipo           VARCHAR2(10)   NOT NULL,
    CONSTRAINT pk_producto           PRIMARY KEY (producto_id),
    CONSTRAINT ck_producto_precio    CHECK (precio > 0),
    CONSTRAINT ck_producto_tipo      CHECK (tipo IN ('platillo', 'bebida')),
    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id)
        REFERENCES categoria (categoria_id)
);

CREATE TABLE platillo (
    producto_id NUMBER NOT NULL,
    CONSTRAINT pk_platillo          PRIMARY KEY (producto_id),
    CONSTRAINT fk_platillo_producto FOREIGN KEY (producto_id)
        REFERENCES producto (producto_id) ON DELETE CASCADE
);

CREATE TABLE bebida (
    producto_id NUMBER NOT NULL,
    CONSTRAINT pk_bebida          PRIMARY KEY (producto_id),
    CONSTRAINT fk_bebida_producto FOREIGN KEY (producto_id)
        REFERENCES producto (producto_id) ON DELETE CASCADE
);

CREATE TABLE cliente_fact (
    rfc              VARCHAR2(13)  NOT NULL,
    nombre_cliente   VARCHAR2(40)  NOT NULL,
    apellido_paterno VARCHAR2(40)  NOT NULL,
    apellido_materno VARCHAR2(40)  NOT NULL,
    fecha_nacimiento DATE          NOT NULL,
    email            VARCHAR2(60)  NOT NULL,
    estado           VARCHAR2(40)  NOT NULL,
    codigo_postal    VARCHAR2(5)   NOT NULL,
    colonia          VARCHAR2(40)  NOT NULL,
    numero           VARCHAR2(10)  NOT NULL,
    calle            VARCHAR2(100) NOT NULL,
    razon_social     VARCHAR2(150) NOT NULL,
    CONSTRAINT pk_cliente_fact PRIMARY KEY (rfc)
);

CREATE TABLE orden (
    folio        VARCHAR2(10)  NOT NULL,
    fecha        DATE          DEFAULT TRUNC(SYSDATE) NOT NULL,
    hora         DATE          DEFAULT SYSDATE NOT NULL,
    total        NUMBER(10,2)  DEFAULT 0 NOT NULL,
    num_empleado VARCHAR2(10)  NOT NULL,
    rfc          VARCHAR2(13),
    CONSTRAINT pk_orden         PRIMARY KEY (folio),
    CONSTRAINT fk_orden_mesero  FOREIGN KEY (num_empleado) REFERENCES mesero (num_empleado),
    CONSTRAINT fk_orden_cliente FOREIGN KEY (rfc) REFERENCES cliente_fact (rfc) ON DELETE SET NULL
);

CREATE TABLE detalle_orden (
    folio           VARCHAR2(10)  NOT NULL,
    producto_id     NUMBER        NOT NULL,
    cantidad        NUMBER        NOT NULL,
    precio_platillo NUMBER(8,2)   NOT NULL,
    CONSTRAINT pk_detalle_orden    PRIMARY KEY (folio, producto_id),
    CONSTRAINT ck_det_cantidad     CHECK (cantidad > 0),
    CONSTRAINT ck_det_precio       CHECK (precio_platillo > 0),
    CONSTRAINT fk_detalle_orden    FOREIGN KEY (folio)
        REFERENCES orden (folio) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id)
        REFERENCES producto (producto_id)
);

PROMPT Tablas creadas.


-- ============================================================
-- PARTE 4: FUNCION generar_folio
-- Debe crearse ANTES que los triggers que la invocan.
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT PARTE 4: FUNCION generar_folio
PROMPT ============================================================

DROP FUNCTION IF EXISTS generar_folio;

CREATE OR REPLACE FUNCTION generar_folio
RETURN VARCHAR2
AS
    v_numero NUMBER;
BEGIN
    v_numero := folio_seq.NEXTVAL;
    RETURN 'ORD-' || LPAD(TO_CHAR(v_numero), 3, '0');
END;
/

SHOW ERRORS FUNCTION generar_folio;


-- ============================================================
-- PARTE 5: TRIGGERS
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT PARTE 5: TRIGGERS
PROMPT ============================================================

-- TRIGGER 1: folio automatico al insertar ORDEN
-- El usuario no proporciona el folio; el trigger lo genera.
CREATE OR REPLACE TRIGGER trg_generar_folio
BEFORE INSERT ON orden
FOR EACH ROW
BEGIN
    :NEW.folio := generar_folio();
END;
/
SHOW ERRORS TRIGGER trg_generar_folio;

-- TRIGGER 2: INSERT en detalle_orden
-- Valida disponibilidad, calcula precio_platillo = cantidad x precio,
-- acumula el subtotal en total de la orden.
-- Se usa total = total + nuevo_subtotal para evitar leer detalle_orden
-- desde su propio trigger (problema de tabla mutante en Oracle).
CREATE OR REPLACE TRIGGER trg_insertar_detalle
BEFORE INSERT ON detalle_orden
FOR EACH ROW
DECLARE
    v_disponible BOOLEAN;
    v_precio     NUMBER(8,2);
    v_nombre     VARCHAR2(40);
BEGIN
    BEGIN
        SELECT disponibilidad, precio, nombre
        INTO v_disponible, v_precio, v_nombre
        FROM producto
        WHERE producto_id = :NEW.producto_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,
                'El producto con ID ' || :NEW.producto_id || ' no existe.');
    END;

    IF NOT v_disponible THEN
        RAISE_APPLICATION_ERROR(-20002,
            'El producto "' || v_nombre || '" no esta disponible actualmente.');
    END IF;

    :NEW.precio_platillo := :NEW.cantidad * v_precio;

    UPDATE orden SET total = total + :NEW.precio_platillo
    WHERE folio = :NEW.folio;
END;
/
SHOW ERRORS TRIGGER trg_insertar_detalle;

-- TRIGGER 3: UPDATE en detalle_orden
-- Recalcula precio_platillo y ajusta total restando el viejo subtotal
-- y sumando el nuevo.
CREATE OR REPLACE TRIGGER trg_actualizar_detalle
BEFORE UPDATE ON detalle_orden
FOR EACH ROW
DECLARE
    v_precio NUMBER(8,2);
BEGIN
    SELECT precio INTO v_precio FROM producto WHERE producto_id = :NEW.producto_id;
    :NEW.precio_platillo := :NEW.cantidad * v_precio;
    UPDATE orden
    SET total = total - :OLD.precio_platillo + :NEW.precio_platillo
    WHERE folio = :NEW.folio;
END;
/
SHOW ERRORS TRIGGER trg_actualizar_detalle;

-- TRIGGER 4: DELETE en detalle_orden
-- Resta el subtotal eliminado del total de la orden.
CREATE OR REPLACE TRIGGER trg_eliminar_detalle
AFTER DELETE ON detalle_orden
FOR EACH ROW
BEGIN
    UPDATE orden SET total = total - :OLD.precio_platillo
    WHERE folio = :OLD.folio;
END;
/
SHOW ERRORS TRIGGER trg_eliminar_detalle;

PROMPT Triggers creados.


-- ============================================================
-- PARTE 6: PRUEBAS
-- Las secuencias parten de 1, por lo que producto_id 1,2,3
-- son los valores exactos que generara producto_id_seq.
-- ============================================================
PROMPT
PROMPT ============================================================
PROMPT PARTE 6: PRUEBAS
PROMPT ============================================================

-- Datos base
INSERT INTO categoria (nombre, descripcion)
VALUES ('Comida mexicana', 'Platillos tipicos mexicanos');

INSERT INTO empleado (num_empleado, nombre_pila, apellido_paterno, apellido_materno,
    rfc, fecha_nacimiento, edad, sueldo, estado, codigo_postal, colonia, calle, numero)
VALUES ('EMP-001', 'Juan', 'Garcia', 'Lopez', 'GALJ900101ABC',
    DATE '1990-01-01', 34, 8000, 'CDMX', '06600', 'Juarez', 'Reforma', '100');

INSERT INTO mesero (num_empleado, horario)
VALUES ('EMP-001', 'Lunes a Viernes 08:00-16:00');

INSERT INTO producto (nombre, descripcion, precio, disponibilidad, receta, categoria_id, tipo)
VALUES ('Tacos de pastor', 'Tacos con carne al pastor', 85, TRUE,
        'Carne de cerdo marinada...', 1, 'platillo');

INSERT INTO producto (nombre, descripcion, precio, disponibilidad, receta, categoria_id, tipo)
VALUES ('Agua de jamaica', 'Bebida de flor de jamaica', 25, TRUE,
        'Flor de jamaica, agua, azucar...', 1, 'bebida');

INSERT INTO producto (nombre, descripcion, precio, disponibilidad, receta, categoria_id, tipo)
VALUES ('Enchiladas verdes', 'Enchiladas con salsa verde', 95, FALSE,
        'Tortillas, salsa verde...', 1, 'platillo');

INSERT INTO platillo (producto_id) VALUES (1);
INSERT INTO bebida   (producto_id) VALUES (2);
INSERT INTO platillo (producto_id) VALUES (3);

COMMIT;

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 1: Folio automatico al insertar orden
PROMPT Esperado: folio = ORD-001, total = 0
-- ------------------------------------------------------------

INSERT INTO orden (num_empleado) VALUES ('EMP-001');
COMMIT;

SELECT folio,
       TO_CHAR(fecha, 'YYYY-MM-DD')  AS fecha,
       TO_CHAR(hora,  'HH24:MI:SS')  AS hora,
       total
FROM orden;

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 2: Insertar 2 tacos de pastor (2 x 85 = 170)
PROMPT Esperado: precio_platillo = 170, total = 170
-- ------------------------------------------------------------

INSERT INTO detalle_orden (folio, producto_id, cantidad, precio_platillo)
VALUES ('ORD-001', 1, 2, 0);
COMMIT;

SELECT folio, producto_id, cantidad, precio_platillo
FROM detalle_orden WHERE folio = 'ORD-001';

SELECT folio, total FROM orden WHERE folio = 'ORD-001';

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 3: Agregar 1 agua de jamaica (1 x 25 = 25), total = 195
-- ------------------------------------------------------------

INSERT INTO detalle_orden (folio, producto_id, cantidad, precio_platillo)
VALUES ('ORD-001', 2, 1, 0);
COMMIT;

SELECT folio, total FROM orden WHERE folio = 'ORD-001';

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 4: Cambiar tacos de 2 a 3 unidades (3 x 85 = 255), total = 280
-- ------------------------------------------------------------

UPDATE detalle_orden SET cantidad = 3
WHERE folio = 'ORD-001' AND producto_id = 1;
COMMIT;

SELECT folio, producto_id, cantidad, precio_platillo
FROM detalle_orden WHERE folio = 'ORD-001';

SELECT folio, total FROM orden WHERE folio = 'ORD-001';

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 5: Eliminar agua de jamaica, total debe quedar en 255
-- ------------------------------------------------------------

DELETE FROM detalle_orden WHERE folio = 'ORD-001' AND producto_id = 2;
COMMIT;

SELECT folio, total FROM orden WHERE folio = 'ORD-001';

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 6: Enchiladas verdes tiene disponibilidad=FALSE
PROMPT Esperado: excepcion con mensaje descriptivo
-- ------------------------------------------------------------

BEGIN
    INSERT INTO detalle_orden (folio, producto_id, cantidad, precio_platillo)
    VALUES ('ORD-001', 3, 1, 0);
    DBMS_OUTPUT.PUT_LINE('PRUEBA 6: ERROR - el trigger no lanzo la excepcion esperada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PRUEBA 6: OK - excepcion capturada -> ' || SQLERRM);
END;
/

-- ------------------------------------------------------------
PROMPT
PROMPT PRUEBA 7: Segunda orden debe generar folio ORD-002
-- ------------------------------------------------------------

INSERT INTO orden (num_empleado) VALUES ('EMP-001');
COMMIT;

SELECT folio FROM orden ORDER BY folio;

-- ------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT RESUMEN FINAL
PROMPT ============================================================

SELECT table_name    AS "Tabla"
FROM user_tables
ORDER BY table_name;

SELECT sequence_name AS "Secuencia", last_number AS "Ultimo_valor"
FROM user_sequences
ORDER BY sequence_name;

EXIT;
