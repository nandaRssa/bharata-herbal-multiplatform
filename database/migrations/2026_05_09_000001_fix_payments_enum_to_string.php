<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE payments MODIFY COLUMN method VARCHAR(50) NOT NULL DEFAULT 'cod'");
            DB::statement("ALTER TABLE payments MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'pending'");
        } elseif ($driver === 'sqlite') {
            DB::statement('PRAGMA foreign_keys = OFF');

            DB::statement("CREATE TABLE payments_v2 (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                order_id INTEGER NOT NULL,
                method TEXT NOT NULL DEFAULT 'cod',
                status TEXT NOT NULL DEFAULT 'pending',
                proof TEXT NULL,
                proof_image TEXT NULL,
                account_name TEXT NULL,
                account_number TEXT NULL,
                amount NUMERIC NULL DEFAULT 0,
                paid_at DATETIME NULL,
                payment_deadline DATETIME NULL,
                created_at DATETIME NULL,
                updated_at DATETIME NULL,
                FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
            )");

            $cols = 'id, order_id, method, status, proof, proof_image, account_name, account_number, amount, paid_at, payment_deadline, created_at, updated_at';
            DB::statement("INSERT INTO payments_v2 ({$cols}) SELECT {$cols} FROM payments");
            DB::statement('DROP TABLE payments');
            DB::statement('ALTER TABLE payments_v2 RENAME TO payments');

            DB::statement('PRAGMA foreign_keys = ON');
        }
    }

    public function down(): void
    {
    }
};
