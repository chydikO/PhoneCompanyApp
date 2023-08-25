DROP DATABASE PhoneCompany;

CREATE DATABASE PhoneCompany DEFAULT CHAR SET utf8;
USE PhoneCompany;

# CUSTOMER (Id, FirstName, LastName, PhoneNum, PlanId)
#     PRICINGPLAN (Id, ConnectionFee, PricePerSecond )
#                 PHONECALL (Id, StartCall, CalledNum, Seconds, CustomerId)
#                           BILL (Id, Month, Year, Amount, CustomerId)

-- Create Tables START
CREATE TABLE PricingPlan (
                             id INT PRIMARY KEY AUTO_INCREMENT,
                             connectionFee DECIMAL(10, 2),
                             pricePerSecond DECIMAL(10, 2)
);

CREATE TABLE Customer (
                          Id INT PRIMARY KEY AUTO_INCREMENT,
                          firstName VARCHAR(50),
                          lastName VARCHAR(50),
                          phoneNum VARCHAR(20),
                          pricingPlan_id INT,
                          FOREIGN KEY (pricingPlan_id) REFERENCES PricingPlan(id)
);

CREATE TABLE PhoneCall (
                           id INT PRIMARY KEY AUTO_INCREMENT,
                           startCall DATETIME,
                           calledNum VARCHAR(20),
                           seconds INT,
                           customer_id INT,
                           FOREIGN KEY (customer_id) REFERENCES Customer(id)
);

CREATE TABLE Bill (
                      id INT PRIMARY KEY AUTO_INCREMENT,
                      month INT,
                      year INT,
                      amount DECIMAL(10, 2),
                      customer_id INT,
                      FOREIGN KEY (customer_id) REFERENCES Customer(id)
);
-- Create Tables END


-- Задание 1:
-- Запретить удаление и обновление данных в таблице PHONECALL - только вставка
DELIMITER //

    CREATE TRIGGER trg_PhoneCall_Delete
        BEFORE DELETE ON PhoneCall
        FOR EACH ROW
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Удаление данных в таблице PHONECALL запрещено!';
    END //

    CREATE TRIGGER trg_PhoneCall_Update
        BEFORE UPDATE ON PhoneCall
        FOR EACH ROW
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Обновление данных в таблице PHONECALL запрещено!';
    END //

DELIMITER ;

-- Задание 2:
-- Напишите триггер, который автоматически обновляет счет (amount) за звонки в таблице Bill
-- в случае добавления записи в таблицу PHONECALL
-- В таблице Bill будет только одна запись для каждого клиента на каждый месяц


-- Task-2 Ver 3.0
DELIMITER //

CREATE TRIGGER trg_UpdateBillAmount
    AFTER INSERT ON PhoneCall
    FOR EACH ROW
BEGIN
    DECLARE billId INT;
    DECLARE billAmount DECIMAL(10, 2);
    DECLARE callDuration INT;
    DECLARE freeCallDuration INT;

    -- Получаем идентификатор счета (billId) для текущего клиента и месяца
    SELECT id INTO billId
        FROM Bill
            WHERE customer_id = NEW.customer_id
                AND Month = MONTH(NEW.StartCall)
                    AND Year = YEAR(NEW.StartCall);

    -- Получаем длительность звонка
    SET callDuration = NEW.seconds;
    -- Получаем бесплатные секунды из PricingPlan
    SET freeCallDuration = (SELECT connectionFee FROM PricingPlan WHERE id = (SELECT PricingPlan_id FROM Customer WHERE id = NEW.customer_id));

    -- Если счет уже существует, обновляем его сумму (amount)
    IF billId IS NOT NULL THEN
        -- Проверяем, если длительность звонка больше бесплатных секунд
        IF callDuration > freeCallDuration THEN
            -- Получаем сумму звонка
            SELECT Amount INTO billAmount
                FROM Bill
                    WHERE Bill.customer_id = NEW.customer_id
                        AND Month = MONTH(NEW.StartCall)
                            AND Year = YEAR(NEW.StartCall);

            -- Обновляем счет
            UPDATE Bill
                SET Amount = Amount + billAmount
                    WHERE id = billId;
        END IF;
    ELSE
        -- Создаем новую запись в таблице BILL только если длительность звонка больше бесплатных секунд
        IF callDuration > freeCallDuration THEN
            INSERT INTO Bill (Month, Year, Amount, customer_id)
            VALUES (
                       MONTH(NEW.StartCall),
                       YEAR(NEW.StartCall),
                       NEW.seconds * (SELECT PricePerSecond FROM PricingPlan WHERE id = (SELECT PricingPlan_id FROM Customer WHERE id = NEW.customer_id)),
                       NEW.customer_id
                   );
        END IF;
    END IF;
END //

DELIMITER ;

-- Fill tab`s
-- Заполнение таблицы PRICINGPLAN
INSERT INTO PRICINGPLAN (ConnectionFee, PricePerSecond)
SELECT 10.00, 0.05
UNION ALL SELECT 15.00, 0.07
UNION ALL SELECT 20.00, 0.10;
-- Заполнение таблицы CUSTOMER
INSERT INTO CUSTOMER (FirstName, LastName, PhoneNum, PricingPlan_id)
SELECT 'John', 'Doe', '1234567890', 1
UNION ALL SELECT 'Jane', 'Smith', '9876543210', 2
UNION ALL SELECT 'Michael', 'Johnson', '5555555555', 1
UNION ALL SELECT 'Emily', 'Brown', '1111111111', 3
UNION ALL SELECT 'David', 'Miller', '9999999999', 2
UNION ALL SELECT 'Olivia', 'Davis', '7777777777', 1
UNION ALL SELECT 'James', 'Wilson', '4444444444', 3
UNION ALL SELECT 'Sophia', 'Anderson', '2222222222', 2
UNION ALL SELECT 'Benjamin', 'Taylor', '6666666666', 1
UNION ALL SELECT 'Ava', 'Thomas', '8888888888', 3;

-- Заполнение таблицы PHONECALL
INSERT INTO PHONECALL (Id, StartCall, CalledNum, Seconds, customer_id)
SELECT 1, '2022-01-01 10:00:00', '5551234567', 120, 1
UNION ALL SELECT 2, '2022-01-02 15:30:00', '5559876543', 180, 2
UNION ALL SELECT 3, '2022-01-03 12:45:00', '5555555555', 90, 3
UNION ALL SELECT 4, '2022-01-04 09:15:00', '5551111111', 240, 4
UNION ALL SELECT 5, '2022-01-05 16:20:00', '5559999999', 150, 5
UNION ALL SELECT 6, '2022-01-06 11:30:00', '5557777777', 300, 6
UNION ALL SELECT 7, '2022-01-07 14:10:00', '5554444444', 180, 7
UNION ALL SELECT 8, '2022-01-08 17:45:00', '5552222222', 120, 8
UNION ALL SELECT 9, '2022-01-09 13:20:00', '5556666666', 90, 9
UNION ALL SELECT 10, '2022-01-10 10:30:00', '5558888888', 240, 10;

-- Заполнение таблицы BILL
INSERT INTO BILL (Month, Year, Amount, customer_id)
SELECT 1, 2022, 6.00, 1
UNION ALL SELECT 1, 2022, 10.50, 2
UNION ALL SELECT 1, 2022, 9.00, 3
UNION ALL SELECT 1, 2022, 24.00, 4
UNION ALL SELECT 1, 2022, 7.50, 5
UNION ALL SELECT 1, 2022, 15.00, 6
UNION ALL SELECT 1, 2022, 10.50, 7
UNION ALL SELECT 1, 2022, 8.00, 8
UNION ALL SELECT 1, 2022, 4.50, 9
UNION ALL SELECT 1, 2022, 20.00, 10;