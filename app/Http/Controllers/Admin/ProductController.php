<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Models\Setting;
use App\Services\ActivityLogger;
use App\Services\ProductStockService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    public function __construct(protected ProductStockService $stockService) {}

    public function index(Request $request)
    {
        $query = Product::with('categories');

        // Handle showing archived products
        if ($request->boolean('show_archived')) {
            $query->onlyTrashed();
        } else {
            $query->withoutTrashed();
        }

        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        if ($request->filled('category')) {
            $query->whereHas('categories', fn($q) => $q->where('categories.id', $request->category));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Sorting logic
        $sortByOption = $request->input('sort_by', 'terbaru');
        $sortOrder = $request->input('sort_order', 'desc');
        
        match ($sortByOption) {
            'nama_asc' => $query->orderBy('name', 'asc'),
            'nama_desc' => $query->orderBy('name', 'desc'),
            'stok_asc' => $query->orderBy('stock', 'asc'),
            'stok_desc' => $query->orderBy('stock', 'desc'),
            'harga_asc' => $query->orderBy('price', 'asc'),
            'harga_desc' => $query->orderBy('price', 'desc'),
            default => $query->latest(),
        };

        $products    = $query->paginate(15)->withQueryString();
        $categories  = Category::all();
        $stockSummary = $this->stockService->getStockSummary();
        $showArchived = $request->boolean('show_archived');
        $archivedCount = Product::onlyTrashed()->count();

        return view('admin.products.index', compact('products', 'categories', 'stockSummary', 'sortByOption', 'showArchived', 'archivedCount'));
    }

    public function create()
    {
        $categories = Category::all();
        return view('admin.products.create', compact('categories'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'           => 'required|string|max:255',
            'description'    => 'nullable|string',
            'usage'          => 'nullable|string',
            'benefits'       => 'nullable|string',
            'composition'    => 'nullable|string',
            'price'          => 'required|numeric|min:0',
            'discount_price' => 'nullable|numeric|min:0|lt:price',
            'stock'          => 'required|integer|min:0',
            'image'          => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'is_featured'    => 'boolean',
            'is_bestseller'  => 'boolean',
            'categories'     => 'required|array|min:1',
            'categories.*'   => 'exists:categories,id',
        ]);

        $data['slug']         = Str::slug($data['name']);
        $data['is_featured']  = $request->boolean('is_featured');
        $data['is_bestseller']= $request->boolean('is_bestseller');
       
        $data['status']       = Product::resolveStatus($data['stock']);

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('products', 'public');
        }

        $product = Product::create($data);
        $product->categories()->sync($request->categories);

        // Log activity
        ActivityLogger::logProductCreate($product);

        return redirect()->route('admin.products.index')
            ->with('success', 'Produk berhasil ditambahkan.');
    }

    public function edit(Product $product)
    {
        $categories = Category::all();
        $product->load('categories');
        return view('admin.products.edit', compact('product', 'categories'));
    }

    public function update(Request $request, Product $product)
    {
        $data = $request->validate([
            'name'           => 'required|string|max:255',
            'description'    => 'nullable|string',
            'usage'          => 'nullable|string',
            'benefits'       => 'nullable|string',
            'composition'    => 'nullable|string',
            'price'          => 'required|numeric|min:0',
            'discount_price' => 'nullable|numeric|min:0',
            'stock'          => 'required|integer|min:0',
            'image'          => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'is_featured'    => 'boolean',
            'is_bestseller'  => 'boolean',
            'categories'     => 'required|array|min:1',
            'categories.*'   => 'exists:categories,id',
        ]);

        $data['is_featured']  = $request->boolean('is_featured');
        $data['is_bestseller']= $request->boolean('is_bestseller');

        if ($request->hasFile('image')) {
            if ($product->image) Storage::disk('public')->delete($product->image);
            $data['image'] = $request->file('image')->store('products', 'public');
        }

        $changes = array_diff_assoc($data, $product->getOriginal());
        $product->update($data);
        $product->categories()->sync($request->categories);

        // Log activity
        if (!empty($changes)) {
            ActivityLogger::logProductUpdate($product, $changes);
        }

        return redirect()->route('admin.products.index')
            ->with('success', 'Produk berhasil diperbarui.');
    }

    public function destroy(Product $product)
    {
        $product->delete();
        
        // Log activity
        ActivityLogger::logProductArchive($product);
        
        return back()->with('success', 'Produk berhasil diarsipkan.');
    }

    public function restore($id)
    {
        $product = Product::withTrashed()->findOrFail($id);
        $product->restore();
        
        // Log activity
        ActivityLogger::logProductRestore($product);
        
        return redirect()->route('admin.products.index')
            ->with('success', 'Produk berhasil dipulihkan.');
    }

    public function permanentDelete($id)
    {
        $product = Product::withTrashed()->findOrFail($id);
        if ($product->image) Storage::disk('public')->delete($product->image);
        $product->forceDelete();
        
        // Log activity
        ActivityLogger::logProductDelete($product);
        
        return back()->with('success', 'Produk berhasil dihapus permanen dari sistem.');
    }

    public function updateStock(Request $request, Product $product)
    {
        $request->validate([
            'stock' => 'required|integer|min:0',
        ]);

        $product = $this->stockService->updateStock($product, (int) $request->stock);

        return response()->json([
            'success' => true,
            'message' => 'Stok berhasil diperbarui.',
            'data'    => [
                'id'     => $product->id,
                'stock'  => $product->stock,
                'status' => $product->status,
            ],
        ]);
    }

    public function export(Request $request)
    {
        $query = Product::with('categories');

        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        if ($request->filled('category')) {
            $query->whereHas('categories', fn($q) => $q->where('categories.id', $request->category));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $products = $query->get();

        $filename = 'produk_' . now()->format('Ymd_His') . '.csv';
        $headers = ['Content-Type' => 'text/csv; charset=UTF-8'];

        $callback = function () use ($products) {
            $handle = fopen('php://output', 'w');

            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));

            fputcsv($handle, [
                'ID',
                'Nama Produk',
                'Kategori',
                'Harga (Rp)',
                'Harga Diskon (Rp)',
                'Stok',
                'Status',
                'Unggulan',
                'Terlaris',
                'Tanggal Dibuat',
            ]);

            foreach ($products as $product) {
                $categories = $product->categories->pluck('name')->implode(', ');

                fputcsv($handle, [
                    $product->id,
                    $product->name,
                    $categories ?: '-',
                    number_format($product->price, 0, ',', '.'),
                    $product->discount_price ? number_format($product->discount_price, 0, ',', '.') : '-',
                    $product->stock,
                    ucfirst($product->status) === 'Active' ? 'Aktif' : ($product->status === 'warning' ? 'Peringatan' : 'Nonaktif'),
                    $product->is_featured ? 'Ya' : 'Tidak',
                    $product->is_bestseller ? 'Ya' : 'Tidak',
                    $product->created_at->format('d/m/Y H:i'),
                ]);
            }

            fclose($handle);
        };

        return response()->streamDownload($callback, $filename, $headers);
    }
}
