<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    protected $fillable = [
        'admin_id',
        'admin_name',
        'action',
        'description',
        'subject_type',
        'subject_id',
        'metadata',
        'model_type',
        'model_id',
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'metadata' => 'json',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Relationship: Admin yang melakukan aktivitas
     */
    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    /**
     * Get subject model
     */
    public function getSubjectAttribute()
    {
        if (!$this->subject_type || !$this->subject_id) {
            return null;
        }

        $class = "App\\Models\\{$this->subject_type}";
        if (!class_exists($class)) {
            return null;
        }

        return $class::find($this->subject_id);
    }

    /**
     * Scope: Filter by action
     */
    public function scopeByAction($query, $action)
    {
        return $query->where('action', $action);
    }

    /**
     * Scope: Filter by admin
     */
    public function scopeByAdmin($query, $adminId)
    {
        return $query->where('admin_id', $adminId);
    }

    /**
     * Scope: Filter recent (last N days)
     */
    public function scopeRecent($query, $days = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($days))->latest();
    }

    /**
     * Scope: Filter by date range
     */
    public function scopeDateRange($query, $start, $end)
    {
        return $query->whereBetween('created_at', [$start, $end]);
    }
}
