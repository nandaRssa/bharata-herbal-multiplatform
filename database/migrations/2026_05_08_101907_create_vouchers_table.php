<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('type', ['flat', 'percent']); // flat = Rp nominal, percent = %
            $table->decimal('value', 12, 2);            // amount or percentage value
            $table->decimal('min_purchase', 12, 2)->default(0);   // minimum order subtotal
            $table->decimal('max_discount', 12, 2)->nullable();   // max discount cap for percent
            $table->integer('usage_limit')->default(0);           // 0 = unlimited
            $table->integer('used_count')->default(0);
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vouchers');
    }
};
