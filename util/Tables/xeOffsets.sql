/*
# Description
Таблиця для зберігання зміщень (offsets) файлів Extended Events сесій.
Використовується для відстеження останньої обробленої позиції у файлах XE для забезпечення 
неперервного читання подій без дублювання.

# Columns
- sessionName NVARCHAR(128) - назва XE сесії (первинний ключ)
- LastEventTime DATETIME2 - час останньої обробленої події
- LastFileName NVARCHAR(260) - назва останнього обробленого файлу
- LastOffset BIGINT - остання позиція (зміщення) у файлі
*/
CREATE TABLE util.xeOffsets (
	sessionName NVARCHAR(128) NOT NULL PRIMARY KEY,
	LastEventTime DATETIME2 NOT NULL,
	LastFileName NVARCHAR(260) NOT NULL,
	LastOffset BIGINT NOT NULL
		DEFAULT(0)
) ON util;
