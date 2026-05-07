## 🐛 Drag & Drop Upload Bug Fix

### Issue Report
**Problem**: Saat file gambar di-drag dari File Explorer ke area upload, browser membuka file sebagai halaman baru (tab baru) daripada memasukkannya ke kotak upload.

**Root Cause**: Event handler `preventDefault()` dan `stopPropagation()` tidak cukup untuk mencegah browser default drag & drop behavior.

---

### Solusi Yang Diterapkan

#### 1. **Global Document Event Prevention** ✅
```javascript
// Prevent default drag behavior on entire document
document.addEventListener('dragover', (e) => {
    e.preventDefault();
    e.stopPropagation();
}, false);

document.addEventListener('drop', (e) => {
    e.preventDefault();
    e.stopPropagation();
}, false);
```
**Tujuan**: Mencegah browser membuka file ketika di-drag ke area manapun di halaman.

---

#### 2. **Proper Dragenter Event** ✅
```javascript
dropZone.addEventListener('dragenter', (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounter++;  // Increment counter
    
    // Show visual feedback
    dropZone.classList.add('border-herbal-400', 'bg-herbal-50');
    if (draggingState) draggingState.classList.remove('hidden');
    if (defaultState) defaultState.classList.add('hidden');
}, false);
```
**Tujuan**: 
- Trigger saat file masuk ke drop zone
- Increment counter untuk tracking nested elements
- Tampil visual feedback "Lepaskan file di sini"

---

#### 3. **Dragover Event with DropEffect** ✅
```javascript
dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    e.stopPropagation();
    e.dataTransfer.dropEffect = 'copy';  // Visual cursor change
}, false);
```
**Tujuan**:
- Keep preventDefault active selama drag
- Set dropEffect ke 'copy' → cursor berubah jadi '+' (copy icon)
- Memberikan visual feedback bahwa file bisa di-drop

---

#### 4. **Smart Dragleave with Counter** ✅
```javascript
let dragCounter = 0;  // Track enter/leave pairs

dropZone.addEventListener('dragleave', (e) => {
    e.preventDefault();
    e.stopPropagation();
    dragCounter--;  // Decrement counter
    
    // Hide visual feedback hanya jika counter = 0
    if (dragCounter === 0) {
        dropZone.classList.remove('border-herbal-400', 'bg-herbal-50');
        if (draggingState) draggingState.classList.add('hidden');
        if (defaultState) defaultState.classList.remove('hidden');
    }
}, false);
```
**Tujuan**:
- Solusi untuk nested elements problem
- Saat mouse dari parent ke child element, dragleave akan trigger
- Counter mencegah premature reset visual feedback
- Visual feedback hanya disappear saat benar-benar keluar dari drop zone

---

#### 5. **Robust Drop Event Handler** ✅
```javascript
dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    // Reset counter dan visual state
    dragCounter = 0;
    dropZone.classList.remove('border-herbal-400', 'bg-herbal-50');
    if (draggingState) draggingState.classList.add('hidden');
    if (defaultState) defaultState.classList.remove('hidden');

    // Safely access dataTransfer.files
    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
        fileInput.files = files;
        handleFile(files[0]);
    }
}, false);
```
**Tujuan**:
- Prevent browser default drop behavior
- Reset counter setelah drop
- Safely handle files object
- Process dengan validation

---

### How It Works (Step-by-Step)

```
User drags file from File Explorer:
    ↓
1. Browser detects dragover on document
   → document.dragover event fires → preventDefault()
   ↓
2. File enters drop zone area
   → dropZone.dragenter fires → dragCounter++ (now 1)
   → Visual feedback shows: "Lepaskan file di sini"
   ↓
3. File still in drop zone
   → dropZone.dragover fires repeatedly → preventDefault() keeps active
   ↓
4. File dropped on drop zone
   → dropZone.drop fires → preventDefault()
   → dragCounter = 0 → reset visual
   → Extract files from e.dataTransfer.files
   → Validate (type, size)
   → Generate preview
   ↓
5. Browser does NOT open file in new tab
   ✓ File successfully added to form
```

---

### Key Changes vs Old Implementation

| Aspect | Before | After |
|--------|--------|-------|
| **Document Prevention** | ❌ Not present | ✅ Explicit prevention |
| **Dragenter** | ❌ Not handled | ✅ Properly tracked |
| **Counter** | ❌ No counter | ✅ Handles nested elements |
| **Dragover Effect** | ❌ No dropEffect | ✅ Visual cursor change |
| **Dragleave Logic** | ❌ Simple logic | ✅ Counter-based smart logic |
| **Drop Safety** | ⚠️ Basic | ✅ Robust with checks |

---

### Test Checklist

- [ ] **Test 1: Drag file dari File Explorer**
  - Buka halaman produk create/edit
  - Buka File Explorer window
  - Drag image file langsung ke kotak upload
  - Verifikasi: Preview muncul, file tidak dibuka di tab baru
  - Expected: File masuk ke input, preview visible

- [ ] **Test 2: Drag dengan nested elements**
  - Drag file ke area upload
  - Move ke tepi area sambil di-drag
  - Verify: Visual feedback tetap sampai benar-benar keluar
  - Expected: Tidak flickering, smooth transition

- [ ] **Test 3: Cursor feedback**
  - Drag file di atas drop zone
  - Verify: Cursor berubah ke copy icon (+)
  - Expected: Visual feedback jelas

- [ ] **Test 4: Drag multiple files**
  - Drag 2+ file sekaligus
  - Verify: Hanya file pertama yang diproses
  - Expected: Upload first file, others ignored

- [ ] **Test 5: Drag bukan file**
  - Drag teks/link ke area
  - Verify: Browser tidak ada atraksi
  - Expected: Normal drag behavior (tidak drop di input)

- [ ] **Test 6: Click upload tetap bekerja**
  - Click area upload
  - Verify: File picker dialog muncul
  - Expected: Normal file picker dialog

- [ ] **Test 7: Different browser tabs**
  - Open multiple tabs dengan produk pages
  - Upload di tab 1, tab 2, dst
  - Verify: Semua berfungsi independent
  - Expected: No cross-tab interference

---

### Browser Compatibility

✅ Chrome/Chromium 13+
✅ Firefox 9+
✅ Safari 6+
✅ Edge 12+
✅ Opera 12+
✅ Mobile browsers (with drag&drop API support)

---

### Performance Notes

- No memory leaks: Counter resets properly
- Event delegation: Minimal listeners attached
- DOM manipulation: Efficient classList operations
- File processing: Async FileReader, non-blocking

---

### Related Files

- **Component**: `resources/views/components/forms/drag-drop-upload.blade.php`
- **Usage**: `resources/views/admin/products/create.blade.php`
- **Also includes edit**: `resources/views/admin/products/edit.blade.php` (via include)

---

### Troubleshooting

If still having issues:

1. **Clear browser cache** - Vite might be caching old JS
   ```bash
   npm run build  # Rebuild assets
   ```

2. **Check browser console** for errors
   - F12 → Console tab
   - Look for JavaScript errors
   - Check if event listeners attached

3. **Test in different browser** - Rule out browser-specific issues

4. **Check file size** - Very large files might have different behavior

5. **Verify permissions** - Ensure file has read permissions

---

### Debug Mode

Add this to browser console to debug:

```javascript
// In browser console
const debugInfo = {
    dragover: 0,
    dragenter: 0,
    dragleave: 0,
    drop: 0
};

// Intercept events
const originalAddEventListener = Element.prototype.addEventListener;
Element.prototype.addEventListener = function(type, listener, options) {
    if (type.includes('drag')) {
        console.log(`[DEBUG] ${type} listener attached to`, this.id);
    }
    return originalAddEventListener.call(this, type, listener, options);
};
```

---

### Future Enhancements

🔮 Possible improvements:
- [ ] Multiple file drag support
- [ ] Progress bar during preview generation
- [ ] Drag image directly from browser tab
- [ ] Crop/resize before upload
- [ ] Drag & drop reordering (for galleries)
- [ ] Advanced EXIF data extraction

