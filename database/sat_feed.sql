-- =========================================================
-- INSERTS: sat_regimen_fiscal
-- =========================================================
INSERT INTO sat_regimen_fiscal
(c_regimen_fiscal, descripcion, aplica_fisica, aplica_moral, fecha_inicio_vigencia, fecha_fin_vigencia)
VALUES
('601', 'General de Ley Personas Morales', 0, 1, '2022-01-01', NULL),
('603', 'Personas Morales con Fines no Lucrativos', 0, 1, '2022-01-01', NULL),
('605', 'Sueldos y Salarios e Ingresos Asimilados a Salarios', 1, 0, '2022-01-01', NULL),
('606', 'Arrendamiento', 1, 0, '2022-01-01', NULL),
('607', 'Régimen de Enajenación o Adquisición de Bienes', 1, 0, '2022-01-01', NULL),
('608', 'Demás ingresos', 1, 0, '2022-01-01', NULL),
('610', 'Residentes en el Extranjero sin Establecimiento Permanente en México', 1, 1, '2022-01-01', NULL),
('611', 'Ingresos por Dividendos (socios y accionistas)', 1, 0, '2022-01-01', NULL),
('612', 'Personas Físicas con Actividades Empresariales y Profesionales', 1, 0, '2022-01-01', NULL),
('614', 'Ingresos por intereses', 1, 0, '2022-01-01', NULL),
('615', 'Régimen de los ingresos por obtención de premios', 1, 0, '2022-01-01', NULL),
('616', 'Sin obligaciones fiscales', 1, 0, '2022-01-01', NULL),
('620', 'Sociedades Cooperativas de Producción que optan por diferir sus ingresos', 0, 1, '2022-01-01', NULL),
('621', 'Incorporación Fiscal', 1, 0, '2022-01-01', NULL),
('622', 'Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras', 0, 1, '2022-01-01', NULL),
('623', 'Opcional para Grupos de Sociedades', 0, 1, '2022-01-01', NULL),
('624', 'Coordinados', 0, 1, '2022-01-01', NULL),
('625', 'Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas', 1, 0, '2022-01-01', NULL),
('626', 'Régimen Simplificado de Confianza', 1, 1, '2022-01-01', NULL);

-- =========================================================
-- INSERTS: sat_uso_cfdi
-- =========================================================
INSERT INTO sat_uso_cfdi
(c_uso_cfdi, descripcion, aplica_fisica, aplica_moral, fecha_inicio_vigencia, fecha_fin_vigencia)
VALUES
('G01', 'Adquisición de mercancías.', 1, 1, '2022-01-01', NULL),
('G02', 'Devoluciones, descuentos o bonificaciones.', 1, 1, '2022-01-01', NULL),
('G03', 'Gastos en general.', 1, 1, '2022-01-01', NULL),
('I01', 'Construcciones.', 1, 1, '2022-01-01', NULL),
('I02', 'Mobiliario y equipo de oficina por inversiones.', 1, 1, '2022-01-01', NULL),
('I03', 'Equipo de transporte.', 1, 1, '2022-01-01', NULL),
('I04', 'Equipo de computo y accesorios.', 1, 1, '2022-01-01', NULL),
('I05', 'Dados, troqueles, moldes, matrices y herramental.', 1, 1, '2022-01-01', NULL),
('I06', 'Comunicaciones telefónicas.', 1, 1, '2022-01-01', NULL),
('I07', 'Comunicaciones satelitales.', 1, 1, '2022-01-01', NULL),
('I08', 'Otra maquinaria y equipo.', 1, 1, '2022-01-01', NULL),
('D01', 'Honorarios médicos, dentales y gastos hospitalarios.', 1, 0, '2022-01-01', NULL),
('D02', 'Gastos médicos por incapacidad o discapacidad.', 1, 0, '2022-01-01', NULL),
('D03', 'Gastos funerales.', 1, 0, '2022-01-01', NULL),
('D04', 'Donativos.', 1, 0, '2022-01-01', NULL),
('D05', 'Intereses reales efectivamente pagados por créditos hipotecarios (casa habitación).', 1, 0, '2022-01-01', NULL),
('D06', 'Aportaciones voluntarias al SAR.', 1, 0, '2022-01-01', NULL),
('D07', 'Primas por seguros de gastos médicos.', 1, 0, '2022-01-01', NULL),
('D08', 'Gastos de transportación escolar obligatoria.', 1, 0, '2022-01-01', NULL),
('D09', 'Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones.', 1, 0, '2022-01-01', NULL),
('D10', 'Pagos por servicios educativos (colegiaturas).', 1, 0, '2022-01-01', NULL),
('S01', 'Sin efectos fiscales.', 1, 1, '2022-01-01', NULL),
('CP01', 'Pagos', 1, 1, '2022-01-01', NULL),
('CN01', 'Nómina', 1, 0, '2022-01-01', NULL);

-- =========================================================
-- INSERTS: sat_uso_cfdi_regimen
-- =========================================================

-- G01
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('G01','601'),('G01','603'),('G01','606'),('G01','612'),('G01','620'),('G01','621'),('G01','622'),('G01','623'),('G01','624'),('G01','625'),('G01','626');

-- G02
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('G02','601'),('G02','603'),('G02','606'),('G02','612'),('G02','616'),('G02','620'),('G02','621'),('G02','622'),('G02','623'),('G02','624'),('G02','625'),('G02','626');

-- G03
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('G03','601'),('G03','603'),('G03','606'),('G03','612'),('G03','620'),('G03','621'),('G03','622'),('G03','623'),('G03','624'),('G03','625'),('G03','626');

-- I01
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I01','601'),('I01','603'),('I01','606'),('I01','612'),('I01','620'),('I01','621'),('I01','622'),('I01','623'),('I01','624'),('I01','625'),('I01','626');

-- I02
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I02','601'),('I02','603'),('I02','606'),('I02','612'),('I02','620'),('I02','621'),('I02','622'),('I02','623'),('I02','624'),('I02','625'),('I02','626');

-- I03
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I03','601'),('I03','603'),('I03','606'),('I03','612'),('I03','620'),('I03','621'),('I03','622'),('I03','623'),('I03','624'),('I03','625'),('I03','626');

-- I04
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I04','601'),('I04','603'),('I04','606'),('I04','612'),('I04','620'),('I04','621'),('I04','622'),('I04','623'),('I04','624'),('I04','625'),('I04','626');

-- I05
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I05','601'),('I05','603'),('I05','606'),('I05','612'),('I05','620'),('I05','621'),('I05','622'),('I05','623'),('I05','624'),('I05','625'),('I05','626');

-- I06
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I06','601'),('I06','603'),('I06','606'),('I06','612'),('I06','620'),('I06','621'),('I06','622'),('I06','623'),('I06','624'),('I06','625'),('I06','626');

-- I07
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I07','601'),('I07','603'),('I07','606'),('I07','612'),('I07','620'),('I07','621'),('I07','622'),('I07','623'),('I07','624'),('I07','625'),('I07','626');

-- I08
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('I08','601'),('I08','603'),('I08','606'),('I08','612'),('I08','620'),('I08','621'),('I08','622'),('I08','623'),('I08','624'),('I08','625'),('I08','626');

-- D01
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D01','605'),('D01','606'),('D01','608'),('D01','611'),('D01','612'),('D01','614'),('D01','607'),('D01','615'),('D01','625');

-- D02
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D02','605'),('D02','606'),('D02','608'),('D02','611'),('D02','612'),('D02','614'),('D02','607'),('D02','615'),('D02','625');

-- D03
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D03','605'),('D03','606'),('D03','608'),('D03','611'),('D03','612'),('D03','614'),('D03','607'),('D03','615'),('D03','625');

-- D04
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D04','605'),('D04','606'),('D04','608'),('D04','611'),('D04','612'),('D04','614'),('D04','607'),('D04','615'),('D04','625');

-- D05
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D05','605'),('D05','606'),('D05','608'),('D05','611'),('D05','612'),('D05','614'),('D05','607'),('D05','615'),('D05','625');

-- D06
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D06','605'),('D06','606'),('D06','608'),('D06','611'),('D06','612'),('D06','614'),('D06','607'),('D06','615'),('D06','625');

-- D07
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D07','605'),('D07','606'),('D07','608'),('D07','611'),('D07','612'),('D07','614'),('D07','607'),('D07','615'),('D07','625');

-- D08
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D08','605'),('D08','606'),('D08','608'),('D08','611'),('D08','612'),('D08','614'),('D08','607'),('D08','615'),('D08','625');

-- D09
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D09','605'),('D09','606'),('D09','608'),('D09','611'),('D09','612'),('D09','614'),('D09','607'),('D09','615'),('D09','625');

-- D10
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('D10','605'),('D10','606'),('D10','608'),('D10','611'),('D10','612'),('D10','614'),('D10','607'),('D10','615'),('D10','625');

-- S01
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('S01','601'),('S01','603'),('S01','605'),('S01','606'),('S01','608'),('S01','610'),('S01','611'),('S01','612'),('S01','614'),('S01','616'),('S01','620'),('S01','621'),('S01','622'),('S01','623'),('S01','624'),('S01','607'),('S01','615'),('S01','625'),('S01','626');

-- CP01
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('CP01','601'),('CP01','603'),('CP01','605'),('CP01','606'),('CP01','608'),('CP01','610'),('CP01','611'),('CP01','612'),('CP01','614'),('CP01','616'),('CP01','620'),('CP01','621'),('CP01','622'),('CP01','623'),('CP01','624'),('CP01','607'),('CP01','615'),('CP01','625'),('CP01','626');

-- CN01
INSERT INTO sat_uso_cfdi_regimen (c_uso_cfdi, c_regimen_fiscal) VALUES
('CN01','605');
