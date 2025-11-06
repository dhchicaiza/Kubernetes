-- Script de inicialización de la base de datos
-- Este script crea la tabla 'registros' si no existe

CREATE TABLE IF NOT EXISTS registros (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    mensaje VARCHAR(255) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índice para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_registros_fecha ON registros(fecha DESC);

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE 'Tabla "registros" creada exitosamente';
END $$;
