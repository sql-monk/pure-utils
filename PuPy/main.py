"""
PuPy - REST API з FastAPI поверх SQL Server (схема pupy)

Увесь бізнес логіка — в SQL (процедури/функції/представлення),
Python — тільки маршрутизація + серіалізація.

HTTP → FastAPI (PuPy) → SQL Server (schema pupy) → JSON
"""
import argparse
import sys
import os
import getpass
import uvicorn

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

from database import DatabaseConnection
from router import create_app


def parse_args():
    """Парсинг аргументів командного рядка"""
    parser = argparse.ArgumentParser(
        description='PuPy - FastAPI REST API for SQL Server (schema pupy)'
    )
    
    parser.add_argument(
        '--server',
        type=str,
        default='localhost',
        help='SQL Server hostname/IP (default: localhost)'
    )
    
    parser.add_argument(
        '--port',
        type=int,
        default=1433,
        help='SQL Server port (default: 1433)'
    )
    
    parser.add_argument(
        '--user',
        type=str,
        default=None,
        help='SQL username (if not provided, uses Windows Auth)'
    )
    
    parser.add_argument(
        '--database',
        type=str,
        default='msdb',
        help='Default database (default: msdb)'
    )
    
    parser.add_argument(
        '--trust-server-certificate',
        action='store_true',
        default=True,
        help='Trust server certificate for SSL (default: True)'
    )
    
    parser.add_argument(
        '--host',
        type=str,
        default='0.0.0.0',
        help='FastAPI server host (default: 0.0.0.0)'
    )
    
    parser.add_argument(
        '--api-port',
        type=int,
        default=8000,
        help='FastAPI server port (default: 8000)'
    )
    
    return parser.parse_args()


def confirm_database(database: str) -> bool:
    """Підтвердження використання бази даних"""
    print(f"\n⚠️  Database to use: {database}")
    response = input("Continue? (y/n): ").strip().lower()
    return response == 'y'


def main():
    """Головна функція запуску сервера"""
    args = parse_args()
    
    # Підтвердження бази даних
    if not confirm_database(args.database):
        print("❌ Aborted by user")
        sys.exit(0)
    
    # Запит паролю якщо використовується SQL Auth
    password = None
    if args.user:
        password = getpass.getpass(f"Password for {args.user}: ")
    
    # Ініціалізація підключення до БД
    db_config = {
        'server': args.server,
        'port': args.port,
        'user': args.user,
        'password': password,
        'database': args.database,
        'trust_server_certificate': args.trust_server_certificate
    }
    
    try:
        db = DatabaseConnection(db_config)
        print(f"✅ Connected to SQL Server: {args.server}:{args.port}")
        print(f"✅ Database: {args.database}")
    except Exception as e:
        print(f"❌ Failed to connect to SQL Server: {e}")
        sys.exit(1)
    
    # Створення FastAPI додатку
    app = create_app(db)
    
    # Запуск сервера
    print(f"\n🚀 Starting PuPy FastAPI server on {args.host}:{args.api_port}")
    print(f"📖 API documentation: http://{args.host}:{args.api_port}/docs")
    
    uvicorn.run(
        app,
        host=args.host,
        port=args.api_port,
        log_level="info"
    )


if __name__ == "__main__":
    main()
