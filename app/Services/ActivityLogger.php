<?php

namespace App\Services;

use App\Models\ActivityLog;
use Illuminate\Support\Facades\Request;
use Illuminate\Database\Eloquent\Model;

class ActivityLogger
{
    /**
     * Log an activity
     *
     * @param string $action - Action name (e.g., 'create_product', 'update_order')
     * @param string $description - Description of the activity
     * @param Model|null $subject - The model being acted upon
     * @param array|null $metadata - Additional metadata to store
     * @return ActivityLog
     */
    public static function log(
        string $action,
        string $description,
        ?Model $subject = null,
        ?array $metadata = null
    ): ActivityLog {
        // Resolve admin name — tetap tersedia meskipun user sudah logout
        $adminUser = auth()->user() ?? auth('sanctum')->user();
        $adminId   = $adminUser?->id;
        $adminName = $adminUser?->name ?? 'System';

        return ActivityLog::create([
            'admin_id'     => $adminId,
            'admin_name'   => $adminName,
            'action'       => $action,
            'description'  => $description,
            'subject_type' => $subject ? class_basename($subject) : null,
            'subject_id'   => $subject?->id,
            'metadata'     => $metadata,
            'ip_address'   => Request::ip(),
            'user_agent'   => Request::userAgent(),
        ]);
    }

    /**
     * Log login activity
     */
    public static function logLogin(string $email): ActivityLog
    {
        return self::log(
            'admin_login',
            "Admin {$email} berhasil login",
            metadata: ['email' => $email]
        );
    }

    /**
     * Log logout activity
     */
    public static function logLogout(string $email): ActivityLog
    {
        return self::log(
            'admin_logout',
            "Admin {$email} berhasil logout",
            metadata: ['email' => $email]
        );
    }

    /**
     * Log product creation
     */
    public static function logProductCreate(Model $product, ?array $data = null): ActivityLog
    {
        return self::log(
            'create_product',
            "Produk '{$product->name}' berhasil ditambahkan",
            $product,
            $data ? ['name' => $product->name, 'price' => $product->price] : null
        );
    }

    /**
     * Log product update
     */
    public static function logProductUpdate(Model $product, array $changes): ActivityLog
    {
        $changedFields = implode(', ', array_keys($changes));
        return self::log(
            'update_product',
            "Produk '{$product->name}' diperbarui (field: {$changedFields})",
            $product,
            ['changed_fields' => $changes]
        );
    }

    /**
     * Log product archive
     */
    public static function logProductArchive(Model $product): ActivityLog
    {
        return self::log(
            'archive_product',
            "Produk '{$product->name}' berhasil diarsipkan",
            $product
        );
    }

    /**
     * Log product restore
     */
    public static function logProductRestore(Model $product): ActivityLog
    {
        return self::log(
            'restore_product',
            "Produk '{$product->name}' berhasil dipulihkan dari arsip",
            $product
        );
    }

    /**
     * Log product permanent delete
     */
    public static function logProductDelete(Model $product): ActivityLog
    {
        return self::log(
            'delete_product',
            "Produk '{$product->name}' berhasil dihapus permanen",
            $product
        );
    }

    /**
     * Log order status update
     */
    public static function logOrderStatusUpdate(Model $order, string $oldStatus, string $newStatus): ActivityLog
    {
        return self::log(
            'update_order_status',
            "Status pesanan #{$order->order_number} diubah dari {$oldStatus} ke {$newStatus}",
            $order,
            ['old_status' => $oldStatus, 'new_status' => $newStatus]
        );
    }

    /**
     * Log settings update
     */
    public static function logSettingsUpdate(string $section, string $field, string $oldValue, string $newValue): ActivityLog
    {
        return self::log(
            'update_settings',
            "Pengaturan {$section}.{$field} diperbarui",
            metadata: [
                'section' => $section,
                'field' => $field,
                'old_value' => $oldValue,
                'new_value' => $newValue,
            ]
        );
    }

    /**
     * Get recent activities (for dashboard)
     */
    public static function getRecent(int $limit = 10, int $days = 7)
    {
        return ActivityLog::recent($days)
            ->with('admin')
            ->limit($limit)
            ->get();
    }

    /**
     * Get activities by admin
     */
    public static function getByAdmin(int $adminId, int $limit = 20)
    {
        return ActivityLog::byAdmin($adminId)
            ->latest()
            ->limit($limit)
            ->get();
    }

    /**
     * Get activities by action
     */
    public static function getByAction(string $action, int $limit = 20)
    {
        return ActivityLog::byAction($action)
            ->with('admin')
            ->latest()
            ->limit($limit)
            ->get();
    }
}
