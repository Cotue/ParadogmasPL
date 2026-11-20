% ============================================================================
% POLÍTICA ACADÉMICA CONFIGURABLE — CEmestre Etapa 3
% ============================================================================
% NOTA: Estos valores son provisionales de arranque para las carreras presentes
% en el conjunto de combinaciones y serán ajustados por el equipo académico.
% Este archivo debe contener ÚNICAMENTE hechos (sin reglas ni directivas).
% ============================================================================

% --- Porcentaje máximo permitido por carrera (0..100) ---
max_porcentaje_carrera(computadores, 70).
max_porcentaje_carrera(matematica, 50).
max_porcentaje_carrera(fisica, 40).
max_porcentaje_carrera(quimica, 40).

% --- Cantidad máxima de cursos permitidos por área (exactamente un hecho) ---
max_cursos_area(3).

% --- Pares de cursos incompatibles (declarados en un único sentido) ---
% TODO equipo: pares incompatibles reales (mínimo 2) con justificación