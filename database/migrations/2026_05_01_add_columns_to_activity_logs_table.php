<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('activity_logs', function (Blueprint $table) {
            if (!Schema::hasColumn('activity_logs', 'subject_type')) {
                $table->string('subject_type')->nullable()->after('description');
            }
            if (!Schema::hasColumn('activity_logs', 'subject_id')) {
                $table->unsignedBigInteger('subject_id')->nullable()->after('subject_type');
            }
            if (!Schema::hasColumn('activity_logs', 'metadata')) {
                $table->json('metadata')->nullable()->after('subject_id');
            }
            if (!Schema::hasColumn('activity_logs', 'ip_address')) {
                $table->string('ip_address')->nullable()->after('metadata');
            }
            if (!Schema::hasColumn('activity_logs', 'user_agent')) {
                $table->string('user_agent')->nullable()->after('ip_address');
            }
        });
    }

    public function down(): void
    {
        Schema::table('activity_logs', function (Blueprint $table) {
            $columns = ['user_agent', 'ip_address', 'metadata', 'subject_id', 'subject_type'];
            foreach ($columns as $col) {
                if (Schema::hasColumn('activity_logs', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
