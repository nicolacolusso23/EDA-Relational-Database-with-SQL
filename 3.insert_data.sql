-- ==========================================================================================
-- STORES DATA INSERT
-- ==========================================================================================

-- Insert stores with detailed location, contact info, region, opening date, and manager

-- Useful for store-level reporting, sales aggregation, and regional analysis

INSERT INTO stores_table (
    store_id,
    store_name,
    address,
    region,
    phone_number,
    opening_date,
    manager_name
) VALUES
-- Cataluña (100s)
(101, 'QSR Barcelona Centro', 'Carrer de Pelai 12, Barcelona', 'Cataluña', '+34 931234101', '2018-05-12', 'Laura Martínez'),
(102, 'QSR Barcelona Norte', 'Av. Meridiana 220, Barcelona', 'Cataluña', '+34 931234102', '2019-03-20', 'Jordi Puig'),
(103, 'QSR Girona', 'Carrer Nou 45, Girona', 'Cataluña', '+34 972345103', '2020-09-10', 'Marta Soler'),

-- Madrid (200s)
(201, 'QSR Madrid Centro', 'Gran Vía 55, Madrid', 'Madrid', '+34 912345201', '2017-11-01', 'Carlos Gómez'),
(202, 'QSR Madrid Sur', 'Av. de Andalucía 88, Madrid', 'Madrid', '+34 912345202', '2021-02-18', 'Ana Rodríguez'),

-- Andalucía (300s)
(301, 'QSR Sevilla', 'Calle Sierpes 30, Sevilla', 'Andalucía', '+34 954567301', '2016-06-25', 'Manuel Herrera'),

-- Comunidad Valenciana (400s)
(401, 'QSR Valencia Centro', 'Carrer de Colón 22, Valencia', 'Comunidad Valenciana', '+34 963456401', '2018-08-14', 'Paula Ferrer'),
(402, 'QSR Valencia Playa', 'Passeig Marítim 5, Valencia', 'Comunidad Valenciana', '+34 963456402', '2020-07-01', 'David Navarro'),
(403, 'QSR Alicante', 'Av. Maisonnave 40, Alicante', 'Comunidad Valenciana', '+34 965678403', '2019-10-05', 'Lucía Torres'),

-- País Vasco (500s)
(501, 'QSR Bilbao', 'Gran Vía 18, Bilbao', 'País Vasco', '+34 944567501', '2017-04-09', 'Iker Etxeberria');


-- ==========================================================================================
-- FUNCTIONS
-- ==========================================================================================

-- Function to classify item categories based on menu item name

-- Supports consistent item categorization for reporting and analysis

CREATE OR REPLACE FUNCTION get_item_category(item_name TEXT)
RETURNS TEXT AS $$
BEGIN
    IF item_name ILIKE '%Combo%' THEN
        RETURN 'Combo';
    ELSIF item_name ILIKE '%Burger%' THEN
        RETURN 'Burger';
    ELSIF item_name ILIKE '%Chicken%' THEN
        RETURN 'Chicken';
    ELSIF item_name ILIKE '%Drink%' 
       OR item_name ILIKE '%Coffee%'
       OR item_name ILIKE '%Latte%'
       OR item_name ILIKE '%Tea%'
       OR item_name ILIKE '%Milkshake%' THEN
        RETURN 'Drink';
    ELSIF item_name ILIKE '%Pie%'
       OR item_name ILIKE '%Brownie%'
       OR item_name ILIKE '%Ice Cream%' THEN
        RETURN 'Dessert';
    ELSIF item_name ILIKE '%Fries%'
       OR item_name ILIKE '%Onion Rings%'
       OR item_name ILIKE '%Hash Browns%' THEN
        RETURN 'Side';
    ELSE
        RETURN 'Other';
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Function to determine if an item is vegetarian

-- Useful for dietary segmentation and menu analysis

CREATE OR REPLACE FUNCTION is_item_vegetarian(item_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    IF item_name ILIKE '%Veggie%'
       OR item_name ILIKE '%Salad%'
       OR item_name ILIKE '%Fries%'
       OR item_name ILIKE '%Onion Rings%'
       OR item_name ILIKE '%Hash Browns%'
       OR item_name ILIKE '%Ice Cream%'
       OR item_name ILIKE '%Pie%'
       OR item_name ILIKE '%Brownie%'
       OR item_name ILIKE '%Drink%'
       OR item_name ILIKE '%Coffee%'
       OR item_name ILIKE '%Latte%'
       OR item_name ILIKE '%Tea%'
       OR item_name ILIKE '%Milkshake%' THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;



-- ==========================================================================================
-- ITEMS TABLE INSERT
-- ==========================================================================================

-- Populate items_table based on fact_pos_logs menu items

-- Price is set to maximum observed value to avoid inconsistencies; category and vegetarian flag are auto-assigned

INSERT INTO items_table (
    item_id,
    item_name,
    category,
    price,
    is_vegetarian
)
SELECT
    ROW_NUMBER() OVER (ORDER BY menu_item) AS item_id,
    menu_item AS item_name,
    get_item_category(menu_item) AS category,
    MAX(unit_price) AS price,                              -- Se utiliza el precio máximo observado para evitar inconsistencias derivadas de promociones o variaciones temporales. --
    is_item_vegetarian(menu_item) AS is_vegetarian
FROM fact_pos_logs
GROUP BY menu_item
ORDER BY menu_item;


-- ==========================================================================================
-- DISCOUNTS TABLE INSERT
-- ==========================================================================================

-- Insert permanent discounts and weekly coupons

-- Remove old coupon IDs > 2 and re-insert with new IDs starting from 234

INSERT INTO discounts_table (
    discount_id,
    discount_name,
    discount_percentage,
    valid_from,
    valid_until
) VALUES
-- Descuentos permanentes
(0, 'No Discount', 0.00, NULL, NULL),
(1, 'Member Discount', 15.00, NULL, NULL),
-- Cupones semanales
(3, 'Spring Promo Coupon', 10.00, '2025-04-11', '2025-04-17'),
(4, 'Easter Special Coupon', 15.00, '2025-04-18', '2025-04-24'),
(5, 'May Saver Coupon', 12.00, '2025-05-03', '2025-05-09'),
(6, 'Early Summer Coupon', 20.00, '2025-06-01', '2025-06-07'),
(7, 'Mid Summer Deal', 18.00, '2025-06-20', '2025-06-26'),
(8, 'July Special Coupon', 15.00, '2025-07-05', '2025-07-11'),
(9, 'Summer Holiday Coupon', 25.00, '2025-07-20', '2025-07-26'),
(10, 'Back to School Early Deal', 20.00, '2025-08-03', '2025-08-09');

-- Eliminar solo los cupones existentes (IDs mayores a 2)
DELETE FROM discounts_table
WHERE discount_id > 1;

-- Insertar los cupones con los nuevos IDs a partir de 234
INSERT INTO discounts_table (
    discount_id,
    discount_name,
    discount_percentage,
    valid_from,
    valid_until
) VALUES
(234, 'Spring Promo Coupon', 10.00, '2025-04-11', '2025-04-17'),
(235, 'Easter Special Coupon', 15.00, '2025-04-18', '2025-04-24'),
(236, 'May Saver Coupon', 12.00, '2025-05-03', '2025-05-09'),
(237, 'Early Summer Coupon', 20.00, '2025-06-01', '2025-06-07'),
(238, 'Mid Summer Deal', 18.00, '2025-06-20', '2025-06-26'),
(239, 'July Special Coupon', 15.00, '2025-07-05', '2025-07-11'),
(240, 'Summer Holiday Coupon', 25.00, '2025-07-20', '2025-07-26'),
(241, 'Back to School Early Deal', 20.00, '2025-08-03', '2025-08-09');



-- ==========================================================================================
-- CUSTOMERS TABLE INSERT
-- ==========================================================================================

-- Insert sample customers for testing and production

-- Transaction example included for rollback demonstration

BEGIN;

INSERT INTO customers_table (
    customer_id,
    customer_name,
    date_of_birth,
    email,
    loyalty_member
)
VALUES (
    99999,
    'Test User',
    '1990-01-01',
    'test.user@example.com',
    TRUE
);

-- Undo changes
ROLLBACK;

-- Main customer inserts
INSERT INTO customers_table (customer_id, customer_name, date_of_birth, email, loyalty_member) VALUES
(10501, 'Alessia Romano', '1991-04-18', 'alessia.romano@gmail.com', TRUE),
(10502, 'Mateo Vargas', '1984-09-07', 'mateo.vargas@yahoo.com', FALSE),
(10503, 'Nora Castillo', '1996-02-11', 'nora.castillo@hotmail.com', TRUE),
(10504, 'Bruno Martinelli', '1980-12-24', 'bruno.martinelli@gmail.com', FALSE),
(10505, 'Irene Alvarez', '1989-06-03', 'irene.alvarez@yahoo.com', TRUE),
(10506, 'Thiago Costa', '1993-10-29', 'thiago.costa@gmail.com', FALSE),
(10507, 'Lucia Herrera', '1987-01-16', 'lucia.herrera@hotmail.com', TRUE),
(10508, 'Marco Rojas', '1979-08-22', 'marco.rojas@yahoo.com', FALSE),
(10509, 'Sofia Conti', '1992-11-05', 'sofia.conti@gmail.com', TRUE),
(10510, 'Diego Navarro', '1983-03-14', 'diego.navarro@hotmail.com', FALSE),
(10511, 'Clara Moretti', '1995-07-28', 'clara.moretti@yahoo.com', TRUE),
(10512, 'Hugo Mendes', '1981-05-09', 'hugo.mendes@gmail.com', FALSE),
(10513, 'Paula Ferrer', '1990-09-19', 'paula.ferrer@hotmail.com', TRUE),
(10514, 'Ivan Petrescu', '1986-04-02', 'ivan.petrescu@yahoo.com', FALSE),
(10515, 'Marta Bianchi', '1994-01-27', 'marta.bianchi@gmail.com', TRUE),
(10516, 'Rafael Ortega', '1978-10-12', 'rafael.ortega@hotmail.com', FALSE),
(10517, 'Giulia DeLuca', '1991-12-07', 'giulia.deluca@yahoo.com', TRUE),
(10518, 'Adrian Molina', '1982-07-23', 'adrian.molina@gmail.com', TRUE),
(10519, 'Elena Ruiz', '1988-02-15', 'elena.ruiz@hotmail.com', FALSE),
(10520, 'Jonas Schneider', '1980-06-30', 'jonas.schneider@yahoo.com', TRUE),
(10521, 'Camila Souza', '1996-08-08', 'camila.souza@gmail.com', FALSE),
(10522, 'Pietro Rinaldi', '1985-11-21', 'pietro.rinaldi@hotmail.com', TRUE),
(10523, 'Ariana Navas', '1992-03-04', 'ariana.navas@yahoo.com', TRUE),
(10524, 'Felix Dubois', '1977-09-26', 'felix.dubois@gmail.com', FALSE),
(10525, 'Nadia Benali', '1990-05-13', 'nadia.benali@hotmail.com', TRUE),
(10526, 'Kevin Zhang', '1984-12-01', 'kevin.zhang@yahoo.com', FALSE),
(10527, 'Rosa Ventura', '1993-07-17', 'rosa.ventura@gmail.com', TRUE),
(10528, 'Samuel Costa', '1981-02-28', 'samuel.costa@hotmail.com', FALSE),
(10529, 'Chiara Neri', '1989-10-05', 'chiara.neri@yahoo.com', TRUE),
(10530, 'Omar Haddad', '1983-04-22', 'omar.haddad@gmail.com', FALSE),
(10531, 'Helena Duarte', '1995-09-09', 'helena.duarte@hotmail.com', TRUE),
(10532, 'Tomas Ortega', '1987-06-11', 'tomas.ortega@yahoo.com', FALSE),
(10533, 'Yara Hussein', '1991-01-19', 'yara.hussein@gmail.com', TRUE),
(10534, 'Beatriz Gomez', '1982-08-14', 'beatriz.gomez@hotmail.com', TRUE),
(10535, 'Dylan Mercer', '1979-03-07', 'dylan.mercer@yahoo.com', FALSE),
(10536, 'Sara Valente', '1994-12-23', 'sara.valente@gmail.com', TRUE),
(10537, 'Ursula Novak', '1986-05-29', 'ursula.novak@hotmail.com', FALSE),
(10538, 'Leonardo Greco', '1980-11-02', 'leonardo.greco@yahoo.com', TRUE),
(10539, 'Giada Borrelli', '1992-07-06', 'giada.borrelli@gmail.com', TRUE),
(10540, 'Tariq Hassan', '1984-01-25', 'tariq.hassan@hotmail.com', FALSE),
(10541, 'Mila Popovic', '1990-10-18', 'mila.popovic@yahoo.com', TRUE),
(10542, 'Enea Caruso', '1981-08-09', 'enea.caruso@gmail.com', FALSE),
(10543, 'Damian Peralta', '1988-04-03', 'damian.peralta@hotmail.com', TRUE),
(10544, 'Lola Martin', '1996-09-27', 'lola.martin@yahoo.com', TRUE),
(10545, 'Timo Schneider', '1983-12-14', 'timo.schneider@gmail.com', FALSE),
(10546, 'Giovanni Bassi', '1995-02-02', 'giovanni.bassi@hotmail.com', TRUE),
(10547, 'Lucia Ferraro', '1987-07-30', 'lucia.ferraro@yahoo.com', FALSE),
(10548, 'Ivan Petrov', '1980-03-11', 'ivan.petrov@gmail.com', TRUE),
(10549, 'Rene Alvarez', '1978-06-25', 'rene.alvarez@hotmail.com', FALSE),
(10550, 'Nouria Khelifi', '1991-11-08', 'nouria.khelifi@yahoo.com', TRUE),
(10551, 'Valeria Conti', '1986-02-19', 'valeria.conti@gmail.com', TRUE),
(10552, 'Javier Ruiz', '1984-10-09', 'javier.ruiz@yahoo.com', FALSE),
(10553, 'Megan Oneil', '1992-05-21', 'megan.oneil@hotmail.com', TRUE),
(10554, 'Riccardo Leone', '1981-09-02', 'riccardo.leone@gmail.com', FALSE),
(10555, 'Teresa Marino', '1987-12-08', 'teresa.marino@hotmail.com', TRUE),
(10556, 'Nicolas Girard', '1980-04-12', 'nicolas.girard@yahoo.com', FALSE),
(10557, 'Paola Gentili', '1993-03-16', 'paola.gentili@gmail.com', TRUE),
(10558, 'Stefan Ilic', '1983-01-28', 'stefan.ilic@hotmail.com', FALSE),
(10559, 'Ines Duarte', '1990-06-06', 'ines.duarte@yahoo.com', TRUE),
(10560, 'Sara Gallo', '1985-09-18', 'sara.gallo@gmail.com', FALSE),
(10561, 'Alba Ricci', '1991-07-02', 'alba.ricci@hotmail.com', TRUE),
(10562, 'Giulia Serra', '1982-12-21', 'giulia.serra@yahoo.com', FALSE),
(10563, 'Enzo Moretti', '1994-03-08', 'enzo.moretti@gmail.com', TRUE),
(10564, 'Irene DeLuca', '1980-07-10', 'irene.deluca@hotmail.com', FALSE),
(10565, 'Bruno Esposito', '1988-01-05', 'bruno.esposito@yahoo.com', TRUE),
(10566, 'Alicia Molina', '1996-10-26', 'alicia.molina@gmail.com', FALSE),
(10567, 'Fatima Idris', '1989-06-27', 'fatima.idris@hotmail.com', TRUE),
(10568, 'Anita Kowalski', '1984-05-09', 'anita.kowalski@yahoo.com', TRUE),
(10569, 'Hana Sato', '1993-06-21', 'hana.sato@gmail.com', FALSE),
(10570, 'Marco Rinaldi', '1985-07-12', 'marco.rinaldi@hotmail.com', TRUE),
(10571, 'Diego Ferri', '1991-01-12', 'diego.ferri@yahoo.com', FALSE),
(10572, 'Paula Navarro', '1994-09-02', 'paula.navarro@gmail.com', TRUE),
(10573, 'Hugo Lambert', '1980-12-14', 'hugo.lambert@yahoo.com', FALSE),
(10574, 'Clara Vanni', '1988-03-19', 'clara.vanni@hotmail.com', TRUE),
(10575, 'Samuel Costa', '1996-06-22', 'samuel.costa@gmail.com', FALSE),
(10576, 'Ursula Novak', '1987-10-06', 'ursula.novak@yahoo.com', TRUE),
(10577, 'Leonardo Greco', '1979-05-20', 'leonardo.greco@hotmail.com', FALSE),
(10578, 'Chiara Neri', '1991-02-08', 'chiara.neri@gmail.com', TRUE),
(10579, 'Jonas Keller', '1983-07-18', 'jonas.keller@hotmail.com', FALSE),
(10580, 'Elena Cruz', '1995-01-11', 'elena.cruz@yahoo.com', TRUE),
(10581, 'Yara Hussein', '1980-03-25', 'yara.hussein@hotmail.com', FALSE),
(10582, 'Beatriz Gomez', '1989-06-14', 'beatriz.gomez@gmail.com', TRUE),
(10583, 'Javier Ruiz', '1984-10-02', 'javier.ruiz@hotmail.com', FALSE),
(10584, 'Megan Oneil', '1992-04-29', 'megan.oneil@gmail.com', TRUE),
(10585, 'Riccardo Leone', '1981-08-18', 'riccardo.leone@yahoo.com', FALSE),
(10586, 'Teresa Marino', '1987-12-29', 'teresa.marino@gmail.com', TRUE),
(10587, 'Ivan Petrov', '1981-10-03', 'ivan.petrov@hotmail.com', FALSE),
(10588, 'Ariana Navas', '1986-02-16', 'ariana.navas@gmail.com', TRUE),
(10589, 'Rene Alvarez', '1979-05-30', 'rene.alvarez@yahoo.com', FALSE),
(10590, 'Nouria Khelifi', '1990-09-10', 'nouria.khelifi@hotmail.com', TRUE),
(10591, 'Felipe Andrade', '1983-12-19', 'felipe.andrade@gmail.com', FALSE),
(10592, 'Claudia Serra', '1988-03-02', 'claudia.serra@yahoo.com', TRUE),
(10593, 'Evan Delgado', '1981-06-11', 'evan.delgado@gmail.com', FALSE),
(10594, 'Marco Rojas', '1979-08-03', 'marco.rojas@hotmail.com', TRUE),
(10595, 'Lucia Herrera', '1987-01-22', 'lucia.herrera@yahoo.com', TRUE),
(10596, 'Mateo Vargas', '1984-09-30', 'mateo.vargas@gmail.com', FALSE),
(10597, 'Nora Castillo', '1996-02-24', 'nora.castillo@yahoo.com', TRUE),
(10598, 'Bruno Martinelli', '1980-12-08', 'bruno.martinelli@hotmail.com', FALSE),
(10599, 'Irene Alvarez', '1989-06-27', 'irene.alvarez@gmail.com', TRUE),
(10600, 'Thiago Costa', '1993-10-03', 'thiago.costa@yahoo.com', FALSE),
(10601, 'Valentin Pardo', '1982-05-16', 'valentin.pardo@gmail.com', TRUE),
(10602, 'Noemi Sorrento', '1994-11-09', 'noemi.sorrento@yahoo.com', FALSE),
(10603, 'Giorgio Mancini', '1978-07-22', 'giorgio.mancini@hotmail.com', TRUE),
(10604, 'Carmen Iglesias', '1986-01-14', 'carmen.iglesias@gmail.com', FALSE),
(10605, 'Lorenzo Vitale', '1991-08-31', 'lorenzo.vitale@yahoo.com', TRUE),
(10606, 'Amina Farouk', '1993-03-25', 'amina.farouk@hotmail.com', TRUE),
(10607, 'Peter Novak', '1980-02-12', 'peter.novak@gmail.com', FALSE),
(10608, 'Anais Laurent', '1988-10-06', 'anais.laurent@yahoo.com', TRUE),
(10609, 'Rui Ferreira', '1984-04-19', 'rui.ferreira@hotmail.com', FALSE),
(10610, 'Carla Espinosa', '1995-06-08', 'carla.espinosa@gmail.com', TRUE),
(10611, 'Nikolai Ivanov', '1981-12-27', 'nikolai.ivanov@yahoo.com', FALSE),
(10612, 'Laura Gentile', '1990-09-17', 'laura.gentile@hotmail.com', TRUE),
(10613, 'Sergio Palma', '1979-03-28', 'sergio.palma@gmail.com', FALSE),
(10614, 'Elisa Monti', '1987-07-11', 'elisa.monti@yahoo.com', TRUE),
(10615, 'Brayan Salas', '1983-11-04', 'brayan.salas@hotmail.com', FALSE),
(10616, 'Gaia Roversi', '1992-02-26', 'gaia.roversi@gmail.com', TRUE),
(10617, 'Adriana Lopes', '1985-05-30', 'adriana.lopes@yahoo.com', TRUE),
(10618, 'Nico Bernasconi', '1980-08-09', 'nico.bernasconi@hotmail.com', FALSE),
(10619, 'Sana ElAmrani', '1994-12-14', 'sana.elamrani@gmail.com', TRUE),
(10620, 'Mauro Pellegrini', '1977-06-02', 'mauro.pellegrini@yahoo.com', FALSE),
(10621, 'Jana Kovac', '1991-04-05', 'jana.kovac@hotmail.com', TRUE),
(10622, 'Oscar Villalba', '1982-09-13', 'oscar.villalba@gmail.com', FALSE),
(10623, 'Ingrid Svensson', '1989-01-18', 'ingrid.svensson@yahoo.com', TRUE),
(10624, 'Ramon Calderon', '1984-07-23', 'ramon.calderon@hotmail.com', FALSE),
(10625, 'Bianca Marchetti', '1993-10-10', 'bianca.marchetti@gmail.com', TRUE),
(10626, 'Santiago Rivas', '1981-03-07', 'santiago.rivas@yahoo.com', FALSE),
(10627, 'Lina Kassem', '1996-05-29', 'lina.kassem@hotmail.com', TRUE),
(10628, 'Ettore Grassi', '1979-12-20', 'ettore.grassi@gmail.com', FALSE),
(10629, 'Daria Colombo', '1987-08-15', 'daria.colombo@yahoo.com', TRUE),
(10630, 'Youssef Hakimi', '1983-02-03', 'youssef.hakimi@hotmail.com', FALSE),
(10631, 'Mireia Soler', '1992-06-22', 'mireia.soler@gmail.com', TRUE),
(10632, 'Julien Moreau', '1980-10-28', 'julien.moreau@yahoo.com', FALSE),
(10633, 'Paolo Bellini', '1988-05-12', 'paolo.bellini@hotmail.com', TRUE),
(10634, 'Zara Miftah', '1995-09-03', 'zara.miftah@gmail.com', TRUE),
(10635, 'Fabio Greco', '1982-01-09', 'fabio.greco@yahoo.com', FALSE),
(10636, 'Nerea Varela', '1990-12-02', 'nerea.varela@hotmail.com', TRUE),
(10637, 'Tommy Jensen', '1986-04-21', 'tommy.jensen@gmail.com', FALSE),
(10638, 'Klara Horvat', '1993-07-16', 'klara.horvat@yahoo.com', TRUE),
(10639, 'Rocco Santoro', '1978-11-29', 'rocco.santoro@hotmail.com', FALSE),
(10640, 'Sara Marini', '1989-03-11', 'sara.marini@gmail.com', TRUE),
(10641, 'Elio Ricciardi', '1983-06-14', 'elio.ricciardi@yahoo.com', FALSE),
(10642, 'Celia Fuentes', '1992-01-08', 'celia.fuentes@hotmail.com', TRUE),
(10643, 'Milan Petrovic', '1980-09-27', 'milan.petrovic@gmail.com', TRUE),
(10644, 'Greta Lombardi', '1994-04-19', 'greta.lombardi@yahoo.com', FALSE),
(10645, 'Andres Vega', '1987-12-03', 'andres.vega@hotmail.com', TRUE),
(10646, 'Nina Dragic', '1991-05-17', 'nina.dragic@gmail.com', FALSE),
(10647, 'Luca Fiore', '1979-02-12', 'luca.fiore@yahoo.com', TRUE),
(10648, 'Maya Benitez', '1996-08-04', 'maya.benitez@hotmail.com', TRUE),
(10649, 'Gustavo Pires', '1982-10-22', 'gustavo.pires@gmail.com', FALSE),
(10650, 'Arianna Sanna', '1990-03-29', 'arianna.sanna@yahoo.com', TRUE),
(10651, 'Hector Campos', '1984-06-02', 'hector.campos@hotmail.com', FALSE),
(10652, 'Elif Demir', '1993-11-15', 'elif.demir@gmail.com', TRUE),
(10653, 'Bruno Valdes', '1981-01-06', 'bruno.valdes@yahoo.com', FALSE),
(10654, 'Marina Ledesma', '1988-07-09', 'marina.ledesma@hotmail.com', TRUE),
(10655, 'Nils Andersen', '1978-12-18', 'nils.andersen@gmail.com', FALSE),
(10656, 'Ilaria Sala', '1995-05-25', 'ilaria.sala@yahoo.com', TRUE),
(10657, 'Renato Rizzi', '1986-09-13', 'renato.rizzi@hotmail.com', TRUE),
(10658, 'Olga Smirnova', '1991-02-28', 'olga.smirnova@gmail.com', FALSE),
(10659, 'Jorge Salgado', '1983-08-07', 'jorge.salgado@yahoo.com', TRUE),
(10660, 'Daniela Costa', '1994-10-19', 'daniela.costa@hotmail.com', FALSE),
(10661, 'Teo Marquez', '1980-04-08', 'teo.marquez@gmail.com', TRUE),
(10662, 'Isabel Ribeiro', '1989-06-21', 'isabel.ribeiro@yahoo.com', TRUE),
(10663, 'Sami Nasser', '1982-02-17', 'sami.nasser@hotmail.com', FALSE),
(10664, 'Flavia Gatti', '1992-12-30', 'flavia.gatti@gmail.com', TRUE),
(10665, 'Branko Jovic', '1979-07-14', 'branko.jovic@yahoo.com', FALSE),
(10666, 'Ainhoa Prieto', '1995-01-18', 'ainhoa.prieto@hotmail.com', TRUE),
(10667, 'Marius Popa', '1987-03-06', 'marius.popa@gmail.com', FALSE),
(10668, 'Catarina Reis', '1991-09-22', 'catarina.reis@yahoo.com', TRUE),
(10669, 'Ivo Nikolic', '1984-11-02', 'ivo.nikolic@hotmail.com', FALSE),
(10670, 'Sabrina Falco', '1993-02-10', 'sabrina.falco@gmail.com', TRUE),
(10671, 'Khaled Mansour', '1981-06-26', 'khaled.mansour@yahoo.com', FALSE),
(10672, 'Livia Rocco', '1988-10-14', 'livia.rocco@hotmail.com', TRUE),
(10673, 'Gael Bernard', '1990-07-09', 'gael.bernard@gmail.com', TRUE),
(10674, 'Noor Haddadi', '1996-03-01', 'noor.haddadi@yahoo.com', FALSE),
(10675, 'Sergio Lobo', '1983-01-21', 'sergio.lobo@hotmail.com', TRUE),
(10676, 'Irene Vidal', '1992-05-12', 'irene.vidal@gmail.com', FALSE),
(10677, 'Bruna Martins', '1987-08-27', 'bruna.martins@yahoo.com', TRUE),
(10678, 'Dario Gallo', '1978-04-16', 'dario.gallo@hotmail.com', FALSE),
(10679, 'Svetlana Orlov', '1991-10-07', 'svetlana.orlov@gmail.com', TRUE),
(10680, 'Pablo Ibarra', '1984-03-24', 'pablo.ibarra@yahoo.com', FALSE),
(10681, 'Valeria Rizzo', '1993-12-06', 'valeria.rizzo@hotmail.com', TRUE),
(10682, 'Massimo DeSantis', '1982-07-18', 'massimo.desantis@gmail.com', FALSE),
(10683, 'Nina Carvajal', '1990-02-03', 'nina.carvajal@yahoo.com', TRUE),
(10684, 'Theo Lambert', '1986-05-24', 'theo.lambert@hotmail.com', FALSE),
(10685, 'Carolina Ponce', '1995-09-20', 'carolina.ponce@gmail.com', TRUE),
(10686, 'Arturo Neri', '1981-11-11', 'arturo.neri@yahoo.com', TRUE),
(10687, 'Mina Yilmaz', '1992-06-09', 'mina.yilmaz@hotmail.com', FALSE),
(10688, 'Elias Haddad', '1980-03-05', 'elias.haddad@gmail.com', TRUE),
(10689, 'Stella Marconi', '1988-08-31', 'stella.marconi@yahoo.com', FALSE),
(10690, 'Bruno Ribeiro', '1984-12-22', 'bruno.ribeiro@hotmail.com', TRUE),
(10691, 'Elisa Fontana', '1991-04-02', 'elisa.fontana@gmail.com', TRUE),
(10692, 'Ramon Gil', '1983-09-16', 'ramon.gil@yahoo.com', FALSE),
(10693, 'Ines Paredes', '1996-01-26', 'ines.paredes@hotmail.com', TRUE),
(10694, 'Luca Marini', '1979-06-10', 'luca.marini@gmail.com', FALSE),
(10695, 'Maja Kovalenko', '1994-03-21', 'maja.kovalenko@yahoo.com', TRUE),
(10696, 'Adrian Pelle', '1987-10-12', 'adrian.pelle@hotmail.com', FALSE),
(10697, 'Nora Fabbri', '1990-08-18', 'nora.fabbri@gmail.com', TRUE),
(10698, 'Victor Salazar', '1982-02-07', 'victor.salazar@yahoo.com', FALSE),
(10699, 'Giada Contini', '1993-05-27', 'giada.contini@hotmail.com', TRUE),
(10700, 'Olek Mazur', '1981-12-03', 'olek.mazur@gmail.com', FALSE),
(10701, 'Sonia Castillo', '1989-07-14', 'sonia.castillo@yahoo.com', TRUE),
(10702, 'Dimitri Volkov', '1984-04-05', 'dimitri.volkov@hotmail.com', FALSE),
(10703, 'Nerea Campos', '1992-10-19', 'nerea.campos@gmail.com', TRUE),
(10704, 'Fabian Rios', '1980-01-08', 'fabian.rios@yahoo.com', TRUE),
(10705, 'Aisha Karim', '1995-06-12', 'aisha.karim@hotmail.com', FALSE),
(10706, 'Gianni Esposito', '1983-11-23', 'gianni.esposito@gmail.com', TRUE),
(10707, 'Carla Nogueira', '1991-02-14', 'carla.nogueira@yahoo.com', FALSE),
(10708, 'Milo Petric', '1987-09-30', 'milo.petric@hotmail.com', TRUE),
(10709, 'Elena Varga', '1990-05-18', 'elena.varga@gmail.com', TRUE),
(10710, 'Rui Cardoso', '1982-08-26', 'rui.cardoso@yahoo.com', FALSE),
(10711, 'Nadia Salvi', '1994-12-01', 'nadia.salvi@hotmail.com', TRUE),
(10712, 'Oscar Ferraro', '1978-03-12', 'oscar.ferraro@gmail.com', FALSE),
(10713, 'Karla Jimenez', '1986-07-02', 'karla.jimenez@yahoo.com', TRUE),
(10714, 'Lorenzo Gatti', '1981-10-29', 'lorenzo.gatti@hotmail.com', FALSE),
(10715, 'Sana Idrissi', '1996-04-10', 'sana.idrissi@gmail.com', TRUE),
(10716, 'Victor Moreau', '1984-06-21', 'victor.moreau@yahoo.com', FALSE),
(10717, 'Marta Rivas', '1993-02-09', 'marta.rivas@hotmail.com', TRUE),
(10718, 'Ivan Cermak', '1979-08-18', 'ivan.cermak@gmail.com', FALSE),
(10719, 'Alina Petrescu', '1992-01-27', 'alina.petrescu@yahoo.com', TRUE),
(10720, 'Hector Duarte', '1983-05-06', 'hector.duarte@hotmail.com', FALSE),
(10721, 'Giulia Lombardo', '1990-09-15', 'giulia.lombardo@gmail.com', TRUE),
(10722, 'Pablo Herrera', '1987-12-28', 'pablo.herrera@yahoo.com', FALSE),
(10723, 'Nicoleta Ionescu', '1994-06-03', 'nicoleta.ionescu@hotmail.com', TRUE),
(10724, 'Sergio Conti', '1981-04-14', 'sergio.conti@gmail.com', TRUE),
(10725, 'Lina Ferreira', '1996-11-11', 'lina.ferreira@yahoo.com', FALSE),
(10726, 'Marco Silva', '1978-02-24', 'marco.silva@hotmail.com', TRUE),
(10727, 'Ana Moreno', '1989-08-30', 'ana.moreno@gmail.com', FALSE),
(10728, 'Bruno Carvalho', '1984-10-08', 'bruno.carvalho@yahoo.com', TRUE),
(10729, 'Sofia Mancini', '1992-03-19', 'sofia.mancini@hotmail.com', FALSE),
(10730, 'Diego Santoro', '1983-07-03', 'diego.santoro@gmail.com', TRUE),
(10731, 'Clara Figueroa', '1995-01-22', 'clara.figueroa@yahoo.com', TRUE),
(10732, 'Hugo Morel', '1980-06-17', 'hugo.morel@hotmail.com', FALSE),
(10733, 'Paula Ibarra', '1990-11-28', 'paula.ibarra@gmail.com', TRUE),
(10734, 'Ivan Markovic', '1986-02-05', 'ivan.markovic@yahoo.com', FALSE),
(10735, 'Marta Bellini', '1994-09-01', 'marta.bellini@hotmail.com', TRUE),
(10736, 'Rafael Castro', '1979-01-10', 'rafael.castro@gmail.com', FALSE),
(10737, 'Giulia Serra', '1991-12-15', 'giulia.serra@gmail.com', TRUE),
(10738, 'Adrian Ponce', '1982-07-05', 'adrian.ponce@yahoo.com', FALSE),
(10739, 'Elena Roldan', '1988-03-18', 'elena.roldan@hotmail.com', TRUE),
(10740, 'Jonas Weber', '1980-09-02', 'jonas.weber@gmail.com', FALSE),
(10741, 'Camila Reyes', '1996-08-21', 'camila.reyes@yahoo.com', TRUE),
(10742, 'Pietro Marini', '1985-11-09', 'pietro.marini@hotmail.com', FALSE),
(10743, 'Ariana Costa', '1992-03-28', 'ariana.costa@gmail.com', TRUE),
(10744, 'Felix Bernard', '1977-09-14', 'felix.bernard@yahoo.com', FALSE),
(10745, 'Nadia Rossi', '1990-05-01', 'nadia.rossi@hotmail.com', TRUE),
(10746, 'Kevin Park', '1984-12-20', 'kevin.park@gmail.com', FALSE),
(10747, 'Rosa Delgado', '1993-07-03', 'rosa.delgado@yahoo.com', TRUE),
(10748, 'Samuel Rizzo', '1981-02-16', 'samuel.rizzo@hotmail.com', TRUE),
(10749, 'Chiara Ferri', '1989-10-26', 'chiara.ferri@gmail.com', FALSE),
(10750, 'Omar Benyahia', '1983-04-11', 'omar.benyahia@yahoo.com', TRUE),
(10751, 'Helena Mendez', '1995-09-26', 'helena.mendez@hotmail.com', FALSE),
(10752, 'Tomas Salas', '1987-06-23', 'tomas.salas@gmail.com', TRUE),
(10753, 'Yara Nasser', '1991-01-06', 'yara.nasser@yahoo.com', TRUE),
(10754, 'Beatriz Pineda', '1982-08-02', 'beatriz.pineda@hotmail.com', FALSE),
(10755, 'Dylan Romero', '1979-03-20', 'dylan.romero@gmail.com', TRUE),
(10756, 'Sara Borrelli', '1994-12-11', 'sara.borrelli@yahoo.com', FALSE),
(10757, 'Ursula Mendes', '1986-05-07', 'ursula.mendes@hotmail.com', TRUE),
(10758, 'Leonardo Costa', '1980-11-24', 'leonardo.costa@gmail.com', FALSE),
(10759, 'Giada Marino', '1992-07-19', 'giada.marino@yahoo.com', TRUE),
(10760, 'Tariq Nouri', '1984-01-07', 'tariq.nouri@hotmail.com', FALSE),
(10761, 'Mila Duarte', '1990-10-01', 'mila.duarte@gmail.com', TRUE),
(10762, 'Enea Romano', '1981-08-28', 'enea.romano@yahoo.com', FALSE),
(10763, 'Damian Greco', '1988-04-21', 'damian.greco@hotmail.com', TRUE),
(10764, 'Lola Ferrer', '1996-09-11', 'lola.ferrer@gmail.com', TRUE),
(10765, 'Timo Rinaldi', '1983-12-02', 'timo.rinaldi@yahoo.com', FALSE),
(10766, 'Giovanni Conti', '1995-02-20', 'giovanni.conti@hotmail.com', TRUE),
(10767, 'Lucia Serra', '1987-07-11', 'lucia.serra@gmail.com', FALSE),
(10768, 'Ivan Marino', '1980-03-29', 'ivan.marino@yahoo.com', TRUE),
(10769, 'Rene Duarte', '1978-06-07', 'rene.duarte@hotmail.com', FALSE),
(10770, 'Nouria Benali', '1991-11-26', 'nouria.benali@gmail.com', TRUE),
(10771, 'Felipe Ruiz', '1983-12-07', 'felipe.ruiz@yahoo.com', FALSE),
(10772, 'Claudia Ferraro', '1988-03-20', 'claudia.ferraro@hotmail.com', TRUE),
(10773, 'Evan Costa', '1981-06-29', 'evan.costa@gmail.com', FALSE),
(10774, 'Valeria Neri', '1986-02-07', 'valeria.neri@yahoo.com', TRUE),
(10775, 'Massimo Bassi', '1982-07-01', 'massimo.bassi@hotmail.com', FALSE),
(10776, 'Nina Romano', '1990-02-22', 'nina.romano@gmail.com', TRUE),
(10777, 'Theo Greco', '1986-05-02', 'theo.greco@yahoo.com', TRUE),
(10778, 'Carolina Serra', '1995-09-12', 'carolina.serra@hotmail.com', FALSE),
(10779, 'Arturo Ferri', '1981-11-30', 'arturo.ferri@gmail.com', TRUE),
(10780, 'Mina Costa', '1992-06-27', 'mina.costa@yahoo.com', FALSE),
(10781, 'Elias Romano', '1980-03-19', 'elias.romano@hotmail.com', TRUE),
(10782, 'Stella Neri', '1988-08-11', 'stella.neri@gmail.com', FALSE),
(10783, 'Bruno Silva', '1984-12-01', 'bruno.silva@yahoo.com', TRUE),
(10784, 'Elisa Romano', '1991-04-25', 'elisa.romano@hotmail.com', TRUE),
(10785, 'Ramon Costa', '1983-09-04', 'ramon.costa@gmail.com', FALSE),
(10786, 'Ines Ferri', '1996-01-06', 'ines.ferri@yahoo.com', TRUE),
(10787, 'Luca Greco', '1979-06-21', 'luca.greco@hotmail.com', FALSE),
(10788, 'Maja Neri', '1994-03-06', 'maja.neri@gmail.com', TRUE),
(10789, 'Adrian Silva', '1987-10-29', 'adrian.silva@yahoo.com', FALSE),
(10790, 'Nora Costa', '1990-08-05', 'nora.costa@hotmail.com', TRUE),
(10791, 'Victor Romano', '1982-02-26', 'victor.romano@gmail.com', FALSE),
(10792, 'Giada Ferri', '1993-05-08', 'giada.ferri@yahoo.com', TRUE),
(10793, 'Olek Costa', '1981-12-21', 'olek.costa@hotmail.com', TRUE),
(10794, 'Sonia Ferri', '1989-07-02', 'sonia.ferri@gmail.com', FALSE),
(10795, 'Dimitri Costa', '1984-04-26', 'dimitri.costa@yahoo.com', TRUE),
(10796, 'Nerea Romano', '1992-10-02', 'nerea.romano@hotmail.com', FALSE),
(10797, 'Fabian Ferri', '1980-01-29', 'fabian.ferri@gmail.com', TRUE),
(10798, 'Aisha Costa', '1995-06-29', 'aisha.costa@yahoo.com', FALSE),
(10799, 'Gianni Romano', '1983-11-11', 'gianni.romano@hotmail.com', TRUE),
(10800, 'Carla Ferri', '1991-02-06', 'carla.ferri@gmail.com', FALSE),
(10801, 'Milo Costa', '1987-09-11', 'milo.costa@yahoo.com', TRUE),
(10802, 'Elena Romano', '1990-05-06', 'elena.romano@hotmail.com', TRUE),
(10803, 'Rui Costa', '1982-08-08', 'rui.costa@gmail.com', FALSE),
(10804, 'Nadia Ferri', '1994-12-21', 'nadia.ferri@yahoo.com', TRUE),
(10805, 'Oscar Romano', '1978-03-29', 'oscar.romano@hotmail.com', FALSE),
(10806, 'Karla Costa', '1986-07-21', 'karla.costa@gmail.com', TRUE),
(10807, 'Lorenzo Ferri', '1981-10-17', 'lorenzo.ferri@yahoo.com', FALSE),
(10808, 'Sana Costa', '1996-04-23', 'sana.costa@hotmail.com', TRUE),
(10809, 'Victor Ferri', '1984-06-11', 'victor.ferri@gmail.com', FALSE),
(10810, 'Marta Costa', '1993-02-27', 'marta.costa@yahoo.com', TRUE),
(10811, 'Ivan Romano', '1979-08-05', 'ivan.romano@hotmail.com', FALSE),
(10812, 'Alina Costa', '1992-01-10', 'alina.costa@gmail.com', TRUE),
(10813, 'Hector Ferri', '1983-05-27', 'hector.ferri@yahoo.com', FALSE),
(10814, 'Giulia Costa', '1990-09-05', 'giulia.costa@hotmail.com', TRUE),
(10815, 'Pablo Ferri', '1987-12-18', 'pablo.ferri@gmail.com', FALSE),
(10816, 'Nicoleta Costa', '1994-06-25', 'nicoleta.costa@yahoo.com', TRUE),
(10817, 'Sergio Ferri', '1981-04-26', 'sergio.ferri@hotmail.com', TRUE),
(10818, 'Marco Costa', '1978-02-09', 'marco.costa@gmail.com', FALSE),
(10819, 'Ana Ferri', '1989-08-09', 'ana.ferri@yahoo.com', TRUE),
(10820, 'Bruno Costa', '1984-10-21', 'bruno.costa@hotmail.com', FALSE),
(10821, 'Sofia Ferri', '1992-03-05', 'sofia.ferri@gmail.com', TRUE),
(10822, 'Diego Costa', '1983-07-27', 'diego.costa@yahoo.com', FALSE),
(10823, 'Clara Ferri', '1995-01-09', 'clara.ferri@hotmail.com', TRUE),
(10824, 'Hugo Costa', '1980-06-02', 'hugo.costa@gmail.com', FALSE),
(10825, 'Paula Ferri', '1990-11-13', 'paula.ferri@yahoo.com', TRUE),
(10826, 'Ivan Costa', '1986-02-25', 'ivan.costa@hotmail.com', FALSE),
(10827, 'Marta Ferri', '1994-09-27', 'marta.ferri@gmail.com', TRUE),
(10828, 'Rafael Costa', '1979-01-31', 'rafael.costa@yahoo.com', FALSE),
(10829, 'Giulia Ferri', '1991-12-29', 'giulia.ferri@hotmail.com', TRUE),
(10830, 'Adrian Costa', '1982-07-27', 'adrian.costa@gmail.com', FALSE),
(10831, 'Elena Ferri', '1988-03-01', 'elena.ferri@yahoo.com', TRUE),
(10832, 'Jonas Costa', '1980-09-19', 'jonas.costa@hotmail.com', FALSE),
(10833, 'Camila Ferri', '1996-08-02', 'camila.ferri@gmail.com', TRUE),
(10834, 'Pietro Costa', '1985-11-26', 'pietro.costa@yahoo.com', FALSE),
(10835, 'Ariana Ferri', '1992-03-12', 'ariana.ferri@hotmail.com', TRUE),
(10836, 'Felix Costa', '1977-09-01', 'felix.costa@gmail.com', FALSE),
(10837, 'Nadia Costa', '1990-05-25', 'nadia.costa@yahoo.com', TRUE),
(10838, 'Kevin Ferri', '1984-12-12', 'kevin.ferri@hotmail.com', FALSE),
(10839, 'Rosa Costa', '1993-07-25', 'rosa.costa@gmail.com', TRUE),
(10840, 'Samuel Ferri', '1981-02-02', 'samuel.ferri@yahoo.com', TRUE),
(10841, 'Chiara Costa', '1989-10-12', 'chiara.costa@hotmail.com', FALSE),
(10842, 'Omar Costa', '1983-04-03', 'omar.costa@gmail.com', TRUE),
(10843, 'Helena Costa', '1995-09-02', 'helena.costa@yahoo.com', FALSE),
(10844, 'Tomas Ferri', '1987-06-29', 'tomas.ferri@hotmail.com', TRUE),
(10845, 'Yara Costa', '1991-01-27', 'yara.costa@gmail.com', TRUE),
(10846, 'Beatriz Costa', '1982-08-25', 'beatriz.costa@yahoo.com', FALSE),
(10847, 'Dylan Costa', '1979-03-28', 'dylan.costa@hotmail.com', TRUE),
(10848, 'Sara Costa', '1994-12-07', 'sara.costa@gmail.com', FALSE),
(10849, 'Ursula Costa', '1986-05-18', 'ursula.costa@yahoo.com', TRUE),
(10850, 'Leonardo Ferri', '1980-11-08', 'leonardo.ferri@hotmail.com', FALSE),
(10851, 'Giada Costa', '1992-07-27', 'giada.costa@gmail.com', TRUE),
(10852, 'Tariq Costa', '1984-01-18', 'tariq.costa@yahoo.com', FALSE),
(10853, 'Mila Costa', '1990-10-29', 'mila.costa@hotmail.com', TRUE),
(10854, 'Enea Costa', '1981-08-16', 'enea.costa@gmail.com', FALSE),
(10855, 'Damian Costa', '1988-04-11', 'damian.costa@yahoo.com', TRUE),
(10856, 'Lola Costa', '1996-09-05', 'lola.costa@hotmail.com', TRUE),
(10857, 'Timo Costa', '1983-12-25', 'timo.costa@gmail.com', FALSE),
(10858, 'Giovanni Ferri', '1995-02-11', 'giovanni.ferri@yahoo.com', TRUE),
(10859, 'Lucia Costa', '1987-07-24', 'lucia.costa@hotmail.com', FALSE),
(10860, 'Ivan Ferri', '1980-03-03', 'ivan.ferri@gmail.com', TRUE),
(10861, 'Rene Costa', '1978-06-18', 'rene.costa@yahoo.com', FALSE),
(10862, 'Nouria Costa', '1991-11-17', 'nouria.costa@hotmail.com', TRUE),
(10863, 'Felipe Costa', '1983-12-27', 'felipe.costa@gmail.com', FALSE),
(10864, 'Claudia Costa', '1988-03-31', 'claudia.costa@yahoo.com', TRUE),
(10865, 'Evan Costa', '1981-06-03', 'evan.costa@hotmail.com', FALSE),
(10866, 'Valeria Ferri', '1986-02-28', 'valeria.ferri@gmail.com', TRUE),
(10867, 'Massimo Costa', '1982-07-10', 'massimo.costa@yahoo.com', FALSE),
(10868, 'Nina Ferri', '1990-02-13', 'nina.ferri@hotmail.com', TRUE),
(10869, 'Theo Costa', '1986-05-10', 'theo.costa@gmail.com', TRUE),
(10870, 'Carolina Costa', '1995-09-28', 'carolina.costa@yahoo.com', FALSE),
(10871, 'Arturo Costa', '1981-11-20', 'arturo.costa@hotmail.com', TRUE),
(10872, 'Mina Ferri', '1992-06-18', 'mina.ferri@gmail.com', FALSE),
(10873, 'Elias Costa', '1980-03-23', 'elias.costa@yahoo.com', TRUE),
(10874, 'Stella Costa', '1988-08-23', 'stella.costa@hotmail.com', FALSE),
(10875, 'Bruno Ferri', '1984-12-10', 'bruno.ferri@gmail.com', TRUE),
(10876, 'Elisa Costa', '1991-04-13', 'elisa.costa@yahoo.com', TRUE),
(10877, 'Ramon Ferri', '1983-09-29', 'ramon.ferri@hotmail.com', FALSE),
(10878, 'Ines Costa', '1996-01-18', 'ines.costa@gmail.com', TRUE),
(10879, 'Luca Ferri', '1979-06-02', 'luca.ferri@yahoo.com', FALSE),
(10880, 'Maja Costa', '1994-03-13', 'maja.costa@hotmail.com', TRUE),
(10881, 'Adrian Costa', '1987-10-06', 'adrian.costa2@gmail.com', FALSE),
(10882, 'Nora Ferri', '1990-08-30', 'nora.ferri@yahoo.com', TRUE),
(10883, 'Victor Costa', '1982-02-14', 'victor.costa@hotmail.com', FALSE),
(10884, 'Giada Ferri', '1993-05-20', 'giada.ferri2@gmail.com', TRUE),
(10885, 'Olek Ferri', '1981-12-09', 'olek.ferri@hotmail.com', TRUE),
(10886, 'Sonia Costa', '1989-07-24', 'sonia.costa@yahoo.com', FALSE),
(10887, 'Dimitri Ferri', '1984-04-14', 'dimitri.ferri@gmail.com', TRUE),
(10888, 'Nerea Ferri', '1992-10-11', 'nerea.ferri@hotmail.com', FALSE),
(10889, 'Fabian Costa', '1980-01-16', 'fabian.costa@yahoo.com', TRUE),
(10890, 'Aisha Ferri', '1995-06-04', 'aisha.ferri@gmail.com', FALSE),
(10891, 'Gianni Costa', '1983-11-04', 'gianni.costa@hotmail.com', TRUE),
(10892, 'Carla Costa', '1991-02-25', 'carla.costa@yahoo.com', FALSE),
(10893, 'Milo Ferri', '1987-09-21', 'milo.ferri@gmail.com', TRUE),
(10894, 'Elena Costa', '1990-05-29', 'elena.costa2@hotmail.com', TRUE),
(10895, 'Rui Ferri', '1982-08-16', 'rui.ferri@yahoo.com', FALSE),
(10896, 'Nadia Costa', '1994-12-02', 'nadia.costa2@gmail.com', TRUE),
(10897, 'Oscar Costa', '1978-03-03', 'oscar.costa@yahoo.com', FALSE),
(10898, 'Karla Costa', '1986-07-12', 'karla.costa2@hotmail.com', TRUE),
(10899, 'Lorenzo Costa', '1981-10-09', 'lorenzo.costa@gmail.com', FALSE),
(10900, 'Sana Ferri', '1996-04-16', 'sana.ferri@yahoo.com', TRUE),
(10901, 'Victor Ferri', '1984-06-28', 'victor.ferri2@hotmail.com', FALSE),
(10902, 'Marta Ferri', '1993-02-15', 'marta.ferri2@gmail.com', TRUE),
(10903, 'Ivan Costa', '1979-08-25', 'ivan.costa2@yahoo.com', FALSE),
(10904, 'Alina Ferri', '1992-01-03', 'alina.ferri@hotmail.com', TRUE),
(10905, 'Hector Costa', '1983-05-15', 'hector.costa@gmail.com', FALSE),
(10906, 'Giulia Ferri', '1990-09-23', 'giulia.ferri2@yahoo.com', TRUE),
(10907, 'Pablo Costa', '1987-12-06', 'pablo.costa@hotmail.com', FALSE),
(10908, 'Nicoleta Ferri', '1994-06-18', 'nicoleta.ferri@gmail.com', TRUE),
(10909, 'Sergio Costa', '1981-04-07', 'sergio.costa@yahoo.com', TRUE),
(10910, 'Marco Ferri', '1978-02-18', 'marco.ferri@hotmail.com', FALSE);

-- ==========================================================================================
-- FACT TABLE UPDATE
-- ==========================================================================================

-- Add foreign key columns for items, discounts, and customers

ALTER TABLE fact_pos_logs
ADD COLUMN item_id INTEGER,
ADD COLUMN discount_id INTEGER,
ADD COLUMN customer_id INTEGER;


-- Assign random customers

UPDATE fact_pos_logs
SET customer_id = (10501 + floor(random() * (10910 - 10501 + 1)))::INT;  


-- Remove old columns

ALTER TABLE fact_pos_logs
DROP COLUMN menu_item;

ALTER TABLE fact_pos_logs
DROP COLUMN discount;


-- Map menu items to item_id

UPDATE fact_pos_logs f
SET item_id = i.item_id
FROM items_table i
WHERE f.menu_item = i.item_name;


-- Assign discounts conditionally: loyalty members only get Member Discount

UPDATE fact_pos_logs f
SET discount_id = CASE
    WHEN t.r < 0.70 THEN 0
    WHEN t.r < 0.80 AND c.loyalty_member = TRUE THEN 1
    WHEN t.r < 0.80 AND c.loyalty_member = FALSE THEN 0
    ELSE (234 + floor(random() * 8))::INT
END
FROM (
    SELECT ctid, random() AS r
    FROM fact_pos_logs
) t,
customers_table c
WHERE f.ctid = t.ctid
  AND f.customer_id = c.customer_id;


-- Update total_amount including discount and tax

UPDATE fact_pos_logs f
SET total_amount = ROUND(
    (
        (i.price * f.quantity)
        - ((i.price * f.quantity) * d.discount_percentage / 100)
        + f.tax
    )::numeric
, 2)
FROM items_table i, discounts_table d
WHERE f.item_id = i.item_id
  AND f.discount_id = d.discount_id;



-- ==========================================================================================
-- INDEXES AND CONSTRAINTS
-- ==========================================================================================

-- Ensure uniqueness and foreign key integrity

CREATE UNIQUE INDEX "stores_table_store_name_key" ON "stores_table" USING BTREE ("store_name");
CREATE UNIQUE INDEX "items_table_item_name_key" ON "items_table" USING BTREE ("item_name");
CREATE UNIQUE INDEX "discounts_table_discount_name_key" ON "discounts_table" USING BTREE ("discount_name");
CREATE UNIQUE INDEX "customers_table_email_key" ON "customers_table" USING BTREE ("email");

ALTER TABLE "fact_pos_logs" ADD FOREIGN KEY ("discount_id") REFERENCES "discounts_table" ("discount_id");
ALTER TABLE "fact_pos_logs" ADD FOREIGN KEY ("item_id") REFERENCES "items_table" ("item_id");
ALTER TABLE "fact_pos_logs" ADD FOREIGN KEY ("store_id") REFERENCES "stores_table" ("store_id");
ALTER TABLE "fact_pos_logs" ADD FOREIGN KEY ("customer_id") REFERENCES "customers_table" ("customer_id");
