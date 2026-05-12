<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE payments MODIFY COLUMN method ENUM('cod', 'ewallet', 'bank_transfer', 'dana', 'gopay', 'qris') DEFAULT 'cod'");
        }
        // SQLite uses TEXT (VARCHAR) for enum columns, so no change needed
    }

    public function down(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'mysql') {
            DB::statement("ALTER TABLE payments MODIFY COLUMN method ENUM('cod', 'ewallet', 'bank_transfer') DEFAULT 'cod'");
        }
    }
};
