/*
# Description
Створення схеми api для HTTP API об'єктів

# Usage
USE [YourDatabase];
GO
:r api.sql
GO
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'api')
BEGIN
    EXEC('CREATE SCHEMA api');
    PRINT 'Схема api створена';
END
ELSE
BEGIN
    PRINT 'Схема api вже існує';
END
GO
