package com.chydik0;

import java.sql.*;
import java.util.Scanner;

public class PhoneCompanyApp {
    private static final String DB_URL = "jdbc:mariadb://localhost/phonecompany";
    private static final String DB_USERNAME = "root";
    private static final String DB_PASSWORD = "";

    private Connection connection;
    private Statement statement;
    private Scanner scanner;

    public PhoneCompanyApp() {
        try {
            connection = DriverManager.getConnection(DB_URL, DB_USERNAME, DB_PASSWORD);
            statement = connection.createStatement();
            scanner = new Scanner(System.in);
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void run() {
        boolean running = true;

        while (running) {
            System.out.println("-= Выберите действие: =-");
            System.out.println("1. Ввод информации о клиентах");
            System.out.println("2. Регистрация звонков");
            System.out.println("3. Печать счета за текущий месяц для абонентов");
            System.out.println("0. Выход");

            int choice = scanner.nextInt();
            scanner.nextLine(); // Считываем символ новой строки после ввода числа

            switch (choice) {
                case 1:
                    inputCustomerInfo();
                    break;
                case 2:
                    registerPhoneCall();
                    break;
                case 3:
                    printBillForCurrentMonth();
                    break;
                case 0:
                    running = false;
                    break;
                default:
                    System.err.println("Неверный выбор. Попробуйте еще раз.");
                    break;
            }
        }
        closeResources();
    }

    private void inputCustomerInfo() {
        try {
            System.out.println("Введите информацию о клиентах:");

            //TODO:
            System.out.print("Имя: ");
            String firstName = scanner.nextLine();

            //TODO:
            System.out.print("Фамилия: ");
            String lastName = scanner.nextLine();

            //TODO:
            System.out.print("Номер телефона: ");
            String phoneNum = scanner.nextLine();

            //TODO: вывести варианты тарифного плана
            System.out.print("ID тарифного плана: ");
            int pricingPlanId = scanner.nextInt();
            scanner.nextLine(); // Считываем символ новой строки после ввода числа

            String sql = "INSERT INTO CUSTOMER (FirstName, LastName, PhoneNum, PricingPlan_id) VALUES (?, ?, ?, ?)";
            PreparedStatement preparedStatement = connection.prepareStatement(sql);
            preparedStatement.setString(1, firstName);
            preparedStatement.setString(2, lastName);
            preparedStatement.setString(3, phoneNum);
            preparedStatement.setInt(4, pricingPlanId);
            preparedStatement.executeUpdate();

            System.out.println("Информация о клиенте успешно добавлена.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void registerPhoneCall() {
        try {
            System.out.println("Регистрация звонка:");

            //TODO: упростить ввод даты
            System.out.print("Дата и время начала звонка (yyyy-MM-dd HH:mm:ss): ");
            String startCall = scanner.nextLine();

            System.out.print("Номер, на который был совершен звонок: ");
            String calledNum = scanner.nextLine();

            System.out.print("Продолжительность звонка (в секундах): ");
            int seconds = scanner.nextInt();
            scanner.nextLine(); // Считываем символ новой строки после ввода числа

            //TODO: вывести клиентов и проверить есть ли такой клиенрт
            System.out.print("ID клиента: ");
            int customerId = scanner.nextInt();
            scanner.nextLine(); // Считываем символ новой строки после ввода числа

            String sql = "INSERT INTO PHONECALL (StartCall, CalledNum, Seconds, customer_id) VALUES (?, ?, ?, ?)";
            PreparedStatement preparedStatement = connection.prepareStatement(sql);
            preparedStatement.setString(1, startCall);
            preparedStatement.setString(2, calledNum);
            preparedStatement.setInt(3, seconds);
            preparedStatement.setInt(4, customerId);
            preparedStatement.executeUpdate();

            System.out.println("Звонок успешно зарегистрирован.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void printBillForCurrentMonth() {
        try {
            System.out.println("Печать счета за текущий месяц для абонентов:");

            System.out.print("ID клиента: ");
            int customerId = scanner.nextInt();
            scanner.nextLine(); // Считываем символ новой строки после ввода числа

            String sql =
                    """
                        SELECT SUM(Seconds * PricePerSecond) AS TotalAmount FROM PHONECALL
                            JOIN CUSTOMER ON PHONECALL.Customer_id = CUSTOMER.id
                                JOIN PRICINGPLAN ON CUSTOMER.PricingPlan_id = PRICINGPLAN.Id
                                    WHERE MONTH(StartCall) = MONTH(CURRENT_DATE()) AND YEAR(StartCall) = YEAR(CURRENT_DATE())
                                        AND Customer_Id = ?
                    """;
            PreparedStatement preparedStatement = connection.prepareStatement(sql);
            preparedStatement.setInt(1, customerId);
            ResultSet resultSet = preparedStatement.executeQuery();

            if (resultSet.next()) {
                double totalAmount = resultSet.getDouble("TotalAmount");
                System.out.println("Счет за текущий месяц для клиента с ID " + customerId + ": " + totalAmount);
            } else {
                System.out.println("Счет не найден для указанного клиента и текущего месяца.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void closeResources() {
        try {
            statement.close();
            connection.close();
            scanner.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}

