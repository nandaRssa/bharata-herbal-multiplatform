<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained('users')->onDelete('cascade');
            $table->string('action'); // e.g., 'create_product', 'update_order', 'login'
            $table->text('description');
            $table->string('subject_type')->nullable(); // e.g., 'Product', 'Order'
            $table->unsignedBigInteger('subject_id')->nullable();
            $table->json('metadata')->nullable(); // Store additional data
            $table->string('ip_address')->nullable();
            $table->string('user_agent')->nullable();
            $table->timestamps();

            // Indexes
            $table->index(['admin_id', 'created_at']);
            $table->index('action');
            $table->index('subject_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('activity_logs');
    }
};
