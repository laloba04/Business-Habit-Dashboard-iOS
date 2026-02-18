-- Migración: Añadir campos de recordatorio a la tabla habits
-- Fecha: 2026-02-18
-- Descripción: Añade soporte para notificaciones locales de recordatorios de hábitos

-- Añadir columnas para recordatorios
ALTER TABLE habits
ADD COLUMN IF NOT EXISTS reminder_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS reminder_time TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS reminder_days INTEGER[];

-- Añadir comentarios para documentación
COMMENT ON COLUMN habits.reminder_enabled IS 'Indica si el recordatorio está activo';
COMMENT ON COLUMN habits.reminder_time IS 'Hora del día para enviar el recordatorio (la fecha se ignora, solo se usa hora y minuto)';
COMMENT ON COLUMN habits.reminder_days IS 'Días de la semana para el recordatorio: 0=Domingo, 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado';

-- Añadir índice para consultas eficientes de hábitos con recordatorios activos
CREATE INDEX IF NOT EXISTS idx_habits_reminder_enabled ON habits(reminder_enabled) WHERE reminder_enabled = true;

-- Verificación: Mostrar la estructura actualizada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'habits'
  AND column_name IN ('reminder_enabled', 'reminder_time', 'reminder_days')
ORDER BY ordinal_position;
