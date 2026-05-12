<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReviewResource;
use App\Http\Traits\ApiResponseTrait;
use App\Models\Order;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    use ApiResponseTrait;

    public function store(Request $request, Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        if ($order->status !== 'completed') {
            return $this->error('Hanya pesanan yang sudah selesai yang dapat diberi review.', 400);
        }

        $validated = $request->validate([
            'product_id'    => ['required', 'exists:products,id'],
            'rating'        => ['required', 'integer', 'min:1', 'max:5'],
            'comment'       => ['nullable', 'string', 'max:1000'],
            'image'         => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'reviewer_name' => ['nullable', 'string', 'max:255'],
            'reviewer_title' => ['nullable', 'string', 'max:255'],
        ]);

        // Verify that the product is in this order
        $orderItem = $order->items()->where('product_id', $validated['product_id'])->first();
        if (!$orderItem) {
            return $this->error('Produk ini tidak ada di pesanan Anda.', 404);
        }

        // Check if review already exists
        $existingReview = Review::where('order_id', $order->id)
            ->where('product_id', $validated['product_id'])
            ->first();

        if ($existingReview) {
            return $this->error('Anda sudah memberikan review untuk produk ini.', 400);
        }

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('reviews', 'public');
        }

        $review = $order->reviews()->create([
            'user_id'        => auth()->id(),
            'product_id'     => $validated['product_id'],
            'rating'         => $validated['rating'],
            'comment'        => $validated['comment'] ?? null,
            'image'          => $imagePath,
            'reviewer_name'  => $validated['reviewer_name'] ?? auth()->user()->name,
            'reviewer_title' => $validated['reviewer_title'] ?? null,
        ]);

        $product = $orderItem->product;
        $product->updateRatingStats();

        return $this->success(new ReviewResource($review), 'Review berhasil ditambahkan.', 201);
    }

    public function destroy(Review $review)
    {
        if ($review->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        $product = $review->product;
        $review->delete();

        $product->updateRatingStats();

        return $this->success(null, 'Review berhasil dihapus.');
    }
}
