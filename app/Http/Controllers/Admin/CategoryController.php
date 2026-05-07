<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::withCount('products')->latest()->get();
        return view('admin.categories.index', compact('categories'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'        => 'required|string|max:100|unique:categories,name',
            'description' => 'nullable|string',
            'icon'        => 'nullable|string|max:50',
        ]);
        $data['slug'] = Str::slug($data['name']);
        $category = Category::create($data);
        
        $this->logActivity(
            'Tambah Kategori',
            "Kategori '{$category->name}' ditambahkan",
            'Category',
            $category->id
        );
        
        return back()->with('success', 'Kategori berhasil ditambahkan.');
    }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'name'        => 'required|string|max:100|unique:categories,name,' . $category->id,
            'description' => 'nullable|string',
            'icon'        => 'nullable|string|max:50',
        ]);
        $data['slug'] = Str::slug($data['name']);
        $category->update($data);
        
        $this->logActivity(
            'Edit Kategori',
            "Kategori '{$category->name}' diperbarui",
            'Category',
            $category->id
        );
        
        return back()->with('success', 'Kategori berhasil diperbarui.');
    }

    public function destroy(Category $category)
    {
        $categoryName = $category->name;
        $category->delete();
        
        $this->logActivity(
            'Hapus Kategori',
            "Kategori '{$categoryName}' dihapus",
            'Category',
            $category->id
        );
        
        return back()->with('success', 'Kategori berhasil dihapus.');
    }
}
