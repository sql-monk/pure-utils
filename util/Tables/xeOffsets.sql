/*
# Description
Таблиця для зберігання даних Extended Events.

# Parameters
Таблиця не має параметрів

# Returns
Структура таблиці для зберігання даних

# Usage
Використовується для зберігання та запиту даних
*/
CREATE TABLE util.xeOffsets (
	sessionName NVARCHAR(128) NOT NULL PRIMARY KEY,
	LastEventTime DATETIME2 NOT NULL,
	LastFileName NVARCHAR(260) NOT NULL,
	LastOffset BIGINT NOT NULL
		DEFAULT(0)
) ON util;
